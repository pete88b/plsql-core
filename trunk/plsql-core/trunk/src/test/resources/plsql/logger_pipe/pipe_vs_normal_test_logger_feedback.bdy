CREATE OR REPLACE PACKAGE BODY logger_feedback
IS
  
  /*
  */
  PROCEDURE log_pipe (
    p_who_record IN logger_stack_utils.who_record_type,
    p_level IN PLS_INTEGER,
    p_data  IN VARCHAR2)
  IS
    l_log_id INTEGER;
    
  BEGIN
    SELECT logger_data_log_id.NEXTVAL 
      INTO l_log_id
      FROM dual;
      
    logger_pipe.log(
      'feedback',
      SYSDATE,
      logger_utils.get_user,
      l_log_id,
      p_level,
      'PIPE:' || p_data,
      p_who_record.owner, 
      p_who_record.name, 
      p_who_record.line, 
      p_who_record.type, 
      p_who_record.level, 
      NULL,
      NULL,
      NULL, 
      USERENV('SESSIONID'));
    
  END log_pipe;
  
  /*
  */
  PROCEDURE log_normal (
    p_who_record IN logger_stack_utils.who_record_type,
    p_level IN PLS_INTEGER,
    p_data  IN VARCHAR2)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    
    INSERT INTO logger_feedback_data(
      log_date, log_user, log_id,
      log_seq, log_level, log_data,
      module_owner, module_name, module_line, 
      module_type, module_call_level, log_audsid)
    VALUES(
      SYSDATE, logger_utils.get_user, logger_data_log_id.NEXTVAL,
      0, p_level, SUBSTR(p_data, 1, 4000),
      p_who_record.owner, p_who_record.name, p_who_record.line, 
      p_who_record.type, p_who_record.level, USERENV('SESSIONID'));
        
    COMMIT;

    
  END log_normal;

  /*
  */
  PROCEDURE log (
    p_level IN PLS_INTEGER,
    p_data  IN VARCHAR2)
  IS
    l_who_record logger_stack_utils.who_record_type;
    
  BEGIN
    -- We need to know who called the public logger procedure that caused this
    -- procedure to be called.
    -- This procedure should have been called by the private procedure 
    -- logger.log_internal which should have been called by one of the public
    -- logger procedures so ...
    logger_stack_utils.who_called_my_callers_caller(l_who_record);
    
    IF (p_level = 101)
    THEN
      log_pipe(l_who_record, p_level, p_data);
        
    ELSE
      log_normal(l_who_record, p_level, p_data);

    END IF;
    
  END log;

  
END logger_feedback;
/
