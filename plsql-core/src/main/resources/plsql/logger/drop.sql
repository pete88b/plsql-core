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
  Drop script for logger.
*/

PROMPT ___ Start of logger drop.sql ___

DECLARE
  e_table_or_view_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_table_or_view_not_found, -00942);
  
  e_sequence_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_sequence_not_found, -02289);
  
  e_object_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_object_not_found, -04043);
  
  e_trigger_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_trigger_not_found, -04080);

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
    Attempt to execute the statement within an anonymous block, handling 
    'not found' execptions.
    Anything other than e_table_or_view_not_found, e_sequence_not_found, 
    e_object_not_found or e_trigger_not_found will propogate to the caller
  */
  PROCEDURE exec(
    p_sql IN VARCHAR2
  )
  IS
  BEGIN
    -- Always feedback the statement that we're about to execute
    p(p_sql);
    
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
      
  END exec;

BEGIN
  exec('DROP PACKAGE logger');
  exec('DROP PACKAGE logger_feedback');
  exec('DROP PACKAGE logger_error');
  exec('DROP PACKAGE logger_stack_utils');
  exec('DROP PACKAGE logger_utils');
  exec('DROP VIEW logger_data_all');
  exec('DROP VIEW logger_data_recent');
  exec('DROP SEQUENCE logger_data_log_id');
  exec('DROP TABLE logger_flags');
  exec('DROP TABLE logger_feedback_data');
  exec('DROP TABLE logger_error_data');
  
END;
/

PROMPT ___ End of logger drop.sql ___
