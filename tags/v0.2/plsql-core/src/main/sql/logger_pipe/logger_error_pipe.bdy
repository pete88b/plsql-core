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

CREATE OR REPLACE PACKAGE BODY logger_error
IS

  PROCEDURE log (
    p_level IN PLS_INTEGER,
    p_data  IN VARCHAR2
  )
  IS
    l_who_record logger_stack_utils.who_record_type;
    l_log_id INTEGER;
    
  BEGIN
    -- We need to know who called the public logger procedure that caused this
    -- procedure to be called.
    -- This procedure should have been called by the private procedure 
    -- logger.log_internal which should have been called by one of the public
    -- logger procedures so ...
    logger_stack_utils.who_called_my_callers_caller(l_who_record);
    
    SELECT logger_data_log_id.NEXTVAL 
      INTO l_log_id
      FROM dual;
    
    logger_pipe.log(
      'error',
      SYSDATE,
      logger_utils.get_user,
      l_log_id,
      p_level,
      p_data,
      l_who_record.owner, 
      l_who_record.name, 
      l_who_record.line, 
      l_who_record.type, 
      l_who_record.level, 
      SQLCODE,
      SQLERRM,
      DBMS_UTILITY.FORMAT_CALL_STACK, 
      USERENV('SESSIONID'));
    
  END log;
  
END logger_error;
/
