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

CREATE OR REPLACE PACKAGE BODY logger_feedback
IS

  /*
    Provides procedures for logging feedback.
    This is the default implementation of logger_feedback.
  */  


  /*
    Inserts p_data into the logger_feedback_data table at p_level.
    
    This procedure does not commit the calling sessions transaction.
    
    If p_data more than 4000 characters long, it will be inserted into
    separate rows so no data is lost.
    
  */
  PROCEDURE log (
    p_level IN PLS_INTEGER,
    p_data IN VARCHAR2)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_who_record logger_stack_utils.who_record_type;
    l_data VARCHAR2(32767) := p_data;
    l_data_bit VARCHAR2(4000);
    l_log_id INTEGER;
    l_log_seq INTEGER := 0;
    
  BEGIN
    -- We need to know who called the public logger procedure that caused this
    -- procedure to be called.
    -- This procedure should have been called by the private procedure 
    -- logger.log_internal which should have been called by one of the public
    -- logger procedures so ...
    logger_stack_utils.who_called_my_callers_caller(l_who_record);
    
    SELECT logger_data_log_id.NEXTVAL INTO l_log_id FROM dual;
    
    LOOP
      EXIT WHEN l_log_seq > 0 AND l_data IS NULL;
      
      l_log_seq := l_log_seq + 1;
      l_data_bit := SUBSTR(l_data, 1, 4000);
      l_data := SUBSTR(l_data, 4001);
      
      INSERT INTO logger_feedback_data(
        log_date, log_user, log_id,
        log_seq, log_level, log_data,
        module_owner, module_name, module_line, 
        module_type, module_call_level, log_audsid)
      VALUES(
        SYSDATE, logger_utils.get_user, l_log_id,
        l_log_seq, p_level, l_data_bit,
        l_who_record.owner, l_who_record.name, l_who_record.line, 
        l_who_record.type, l_who_record.level, USERENV('SESSIONID'));
        
    END LOOP;
    
    COMMIT;
    
  END log;

  
END logger_feedback;
/
