CREATE OR REPLACE PACKAGE BODY logger_feedback
IS
  
  /*
  */
  PROCEDURE log (
    p_level IN PLS_INTEGER,
    p_data  IN VARCHAR2)
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
      'feedback',
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
      NULL,
      NULL,
      NULL, 
      USERENV('SESSIONID'));
    
  END log;

  
END logger_feedback;
/
