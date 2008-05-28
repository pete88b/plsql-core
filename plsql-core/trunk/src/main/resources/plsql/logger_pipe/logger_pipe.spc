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

CREATE OR REPLACE PACKAGE logger_pipe
IS
  
  PROCEDURE use_dbms_output;

  /*
  Starts logger pipe background processes.
  This includes creating a pipe for inter-session communication and
  creating new Oracle sessions to receive logger calls.
  */
  PROCEDURE startup;
  
  /*
  Stops logger pipe background processes.
  This includes removing the pipe and stopping sessions created by startup.
  */
  PROCEDURE shutdown;
  
  PROCEDURE check_receivers;
  
  /*
  Receive and process a logger call.
  */
  PROCEDURE receive_logger_call(
    p_receiver_rowid IN VARCHAR2
  );
  
  /*
  p_log_type:
    'error' or 'feedback'
  */
  PROCEDURE log(
    p_log_type IN VARCHAR2,
    p_log_date IN DATE,
    p_log_user IN VARCHAR2,
    p_log_id IN INTEGER,
    p_log_level IN PLS_INTEGER,
    p_log_data IN VARCHAR2,
    p_module_owner IN VARCHAR2, 
    p_module_name IN VARCHAR2, 
    p_module_line IN NUMBER, 
    p_module_type IN VARCHAR2, 
    p_module_call_level IN INTEGER, 
    p_error_code IN INTEGER,
    p_error_message IN VARCHAR2, 
    p_call_stack IN VARCHAR2, 
    p_audsid IN NUMBER
  );
  
END;
/
