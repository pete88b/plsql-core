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
  Build script for logger pipe.

  Depends on: logger.
  Depends on: DBMS_PIPE.
  Depends on: DBMS_OUTPUT.
  Depends on: v_$session.
*/

PROMPT ___ Start of logger pipe build.sql ___

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
    exec('DROP TABLE logger_pipe_config', TRUE);
    exec('DROP TABLE logger_pipe_receivers', TRUE);
    
  END IF;  

--xxx todo switch suppress_errors to Y for prd
  exec('
    CREATE TABLE logger_pipe_config(
      pipe_name VARCHAR2(128) NOT NULL,
      max_pipe_size INTEGER DEFAULT 32767 NOT NULL,
      receiver_count INTEGER DEFAULT 2 NOT NULL,
      send_max_wait INTEGER DEFAULT 86400000 NOT NULL,
      receive_max_wait INTEGER DEFAULT 86400000 NOT NULL,
      pipe_status VARCHAR2(20) DEFAULT ''stopped'' NOT NULL,
      suppress_errors VARCHAR2(1) DEFAULT ''N'' NOT NULL,
      CONSTRAINT pipe_name_not_ora CHECK (UPPER(pipe_name) NOT LIKE ''ORA$%''),
      CONSTRAINT max_pipe_size_ge_8192 CHECK (max_pipe_size >= 8192),
      CONSTRAINT listeer_count_gt_0 CHECK (receiver_count > 0),
      CONSTRAINT suppress_errors_Y_or_N CHECK (suppress_errors IN (''Y'', ''N''))
      )
  ');

  exec('
    CREATE TABLE logger_pipe_receivers(
      started DATE NOT NULL,
      job_id NUMBER,
      flag VARCHAR2(20)
      )
  ');
  
END;
/

PROMPT Loading default pipe config

INSERT INTO logger_pipe_config(
  pipe_name)
VALUES(
  '&_USER._logger_pipe');

COMMIT;

CREATE OR REPLACE TRIGGER bid_fer_logger_pipe_config
  BEFORE INSERT OR DELETE ON logger_pipe_config FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(
    -20000, 
    'logger_pipe_config should always have one row');
    
END bid_fer_logger_pipe_config;
/

-- Compile package specifications
PROMPT Creating logger pipe specification
@@logger_pipe.spc

-- Compile package bodies
PROMPT Creating logger pipe body
@@logger_pipe.bdy

PROMPT Creating logger feedback (pipe) body
@@logger_feedback_pipe.bdy

PROMPT Creating logger error (pipe) body 
@@logger_error_pipe.bdy


PROMPT ___ End of logger pipe build.sql ___
