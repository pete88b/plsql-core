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
