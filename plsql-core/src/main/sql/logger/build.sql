/**
 * Copyright (C) 2008 Peter Butterfill.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
  Build script for logger.
*/

PROMPT ___ Start of logger build.sql ___

DECLARE
  e_table_or_view_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_table_or_view_not_found, -00942);

  e_sequence_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_sequence_not_found, -02289);

  e_object_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_object_not_found, -04043);

  e_trigger_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_trigger_not_found, -04080);

  -- ORA-24344 success with compilation error
  e_success_with_compilation_err EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_success_with_compilation_err, -24344);

  /*
    Send some data to dbms_output.
  */
  PROCEDURE p
    (s IN VARCHAR2)
  IS
  BEGIN
    IF (LENGTH(s) > 255)
    THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR(s, 1, 251) || ' ...');
    ELSE
      DBMS_OUTPUT.PUT_LINE(s);
    END IF;

  -- Let caller module handle any exceptions raised
  END p;

  /*
    Execute a piece of sql.
  */
  PROCEDURE exec
    (p_sql IN VARCHAR2,
     p_handle_exceptions IN BOOLEAN := FALSE)
  IS
  BEGIN
    -- Always feedback the statement that we're about to execute
    p(p_sql);

    IF (p_handle_exceptions)
    THEN
      -- If we're handling exceptions we'll attempt to execute the
      -- statement within an anonymous block, handling 'not found' execptions.
      -- Anything other than e_table_or_view_not_found, e_sequence_not_found,
      -- e_object_not_found or e_trigger_not_found will propogate to the caller
      <<try_sql>>
      BEGIN
        EXECUTE IMMEDIATE p_sql;
        -- Feedback done only if the statement ran without error
        p('Done');

      EXCEPTION
        WHEN e_table_or_view_not_found
        THEN
          p('Table or View not found');

        WHEN e_sequence_not_found
        THEN
          p('Sequence not found');

        WHEN e_object_not_found
        THEN
          p('Object not found');

        WHEN e_trigger_not_found
        THEN
          p('Trigger not found');

      END try_sql;

    ELSE
      -- If we're not handling exceptions, we'll let all exceptions
      -- propogate to the caller
      EXECUTE IMMEDIATE p_sql;
      -- feedback done only if the statement ran without error
      p('Done');

    END IF; -- IF (UPPER(feedback) = yes_C)

  EXCEPTION
    WHEN e_success_with_compilation_err
    THEN
      RAISE_APPLICATION_ERROR(
        -20000,
        'Success with compilation error');

  END exec;

BEGIN
  IF (UPPER('&&drop_existing.') = 'YES' OR
      UPPER('&&drop_existing.') = 'Y')
  THEN
    exec('DROP SEQUENCE logger_data_log_id', TRUE);
    exec('DROP TABLE logger_flags', TRUE);
    exec('DROP TABLE logger_feedback_data', TRUE);
    exec('DROP TABLE logger_error_data', TRUE);

  END IF;

  exec('
    CREATE SEQUENCE logger_data_log_id
      MINVALUE -99999999999999999999999999
      MAXVALUE 99999999999999999999999999
      START WITH -99999999999999999999999999
      INCREMENT BY 1
      CACHE 10
      CYCLE
      ORDER
  ');

  exec('
    CREATE TABLE logger_flags(
      log_user  VARCHAR2(30) CONSTRAINT logger_flags_pk PRIMARY KEY,
      log_level INTEGER
      )
  ');

  exec('
    CREATE TABLE logger_feedback_data (
      log_date          DATE,
      log_user          VARCHAR2(100),
      log_id            INTEGER,
      log_seq           INTEGER,
      log_level         INTEGER,
      log_data          VARCHAR2(4000),
      module_owner      VARCHAR2(30),
      module_name       VARCHAR2(400),
      module_line       NUMBER,        -- To match user_source.line
      module_type       VARCHAR2(30),
      module_call_level INTEGER,
      log_audsid        NUMBER
      )
  ');

  exec('
    CREATE TABLE logger_error_data (
      log_date          DATE,
      log_user          VARCHAR2(100),
      log_id            INTEGER,
      log_seq           INTEGER,
      log_level         INTEGER,
      log_data          VARCHAR2(4000),
      module_owner      VARCHAR2(30),
      module_name       VARCHAR2(400),
      module_line       NUMBER,        -- To match user_source.line
      module_type       VARCHAR2(30),
      module_call_level INTEGER,
      error_code        INTEGER,
      error_message     VARCHAR2(4000),
      error_backtrace   VARCHAR2(4000),
      call_stack        VARCHAR2(4000),
      log_audsid        NUMBER
      )
  ');

END;
/

-- create logger views

PROMPT Creating view logger_data_all
CREATE OR REPLACE VIEW logger_data_all
AS
SELECT log_date, log_user, log_id,
       log_seq, 'ERROR (' || log_level || ')' AS log_level, log_data,
       module_owner, module_name, module_line,
       module_type, module_call_level, error_message,
       error_code, error_backtrace, call_stack,
       log_audsid, 'error' AS source
  FROM logger_error_data
 UNION ALL
SELECT log_date, log_user, log_id,
       log_seq, DECODE(log_level, 98, 'enter', 99, 'exit', 200, 'INFO', 500, 'WARN', log_level), log_data,
       module_owner, module_name, module_line,
       module_type, module_call_level, '',
       TO_NUMBER(NULL), '', '',
       log_audsid, 'feedback'
  FROM logger_feedback_data
 ORDER BY log_date desc, log_id desc, log_seq desc;

PROMPT Creating view logger_data_recent
CREATE OR REPLACE VIEW logger_data_recent
AS
SELECT log_date, log_user, log_id,
       log_seq, 'ERROR (' || log_level || ')' AS log_level, log_data,
       module_owner, module_name, module_line,
       module_type, module_call_level, error_message,
       error_code, error_backtrace, call_stack,
       log_audsid, 'error' AS source
  FROM logger_error_data
 WHERE log_date > SYSDATE - (1/24/60)
 UNION ALL
SELECT log_date, log_user, log_id,
       log_seq, DECODE(log_level, 98, 'enter', 99, 'exit', 200, 'INFO', 500, 'WARN', log_level), log_data,
       module_owner, module_name, module_line,
       module_type, module_call_level, '',
       TO_NUMBER(NULL), '', '',
       log_audsid, 'feedback'
  FROM logger_feedback_data
 WHERE log_date > SYSDATE - (1/24/60)
 ORDER BY log_date desc, log_id desc, log_seq desc;

-- Compile package specifications
PROMPT Creating logger stack utils specification
@@logger_stack_utils.spc

PROMPT Creating logger utils specification
@@logger_utils.spc

PROMPT Creating logger feedback specification
@@logger_feedback.spc

PROMPT Creating logger error specification
@@logger_error.spc

PROMPT Creating logger specification
@@logger.spc

-- Set-up some varaibales to hold the database version
VARIABLE db_version VARCHAR2(2000);
VARIABLE db_compatibility VARCHAR2(2000);

BEGIN
  -- Get the database version for logger_error body compilation
  -- Note: this is in it's own PL/SQL block so that is it not effected by
  -- exceptions raised by other code. e.g. object name in use.
  DBMS_UTILITY.DB_VERSION(:db_version, :db_compatibility);

  DBMS_OUTPUT.PUT_LINE('Found database version: ' || :db_version || CHR(10));

END;
/

--
COLUMN logger_error_body NEW_VALUE logger_error_body NOPRINT
SELECT DECODE(SUBSTR(LTRIM(:db_version), 2, 1),
              '.', 'logger_error_pre_10.bdy',
              'logger_error_post_10.bdy') AS logger_error_body
  FROM DUAL;

-- Compile package bodies
PROMPT Creating logger stack utils body
@@logger_stack_utils.bdy

PROMPT Creating logger utils body
@@logger_utils.bdy

PROMPT Creating logger feedback body
@@logger_feedback.bdy

PROMPT Creating logger error body (using &logger_error_body.)
@@&logger_error_body.

PROMPT Creating logger body
@@logger.bdy

PROMPT ___ End of logger build.sql ___
