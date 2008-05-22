CREATE OR REPLACE PACKAGE BODY logger_admin
IS
  
  FUNCTION get_logger_flags(
    p_log_level IN NUMBER,
    p_log_user IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;

  BEGIN
    logger.entering('get_logger_flags');

    OPEN l_result FOR
    SELECT ROWIDTOCHAR(a.ROWID) AS row_id, a.*
      FROM logger_flags a
     WHERE ((UPPER(log_level) LIKE '%' || p_log_level) OR
           (log_level IS NULL AND p_log_level IS NULL))
       AND ((UPPER(log_user) LIKE '%' || p_log_user) OR
           (log_user IS NULL AND p_log_user IS NULL));

    RETURN l_result;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to get logger flags. p_log_level=' || p_log_level ||
        ', p_log_user=' || p_log_user);
      RAISE;

  END get_logger_flags;
  
  
  FUNCTION logged_data(
    p_type IN VARCHAR2,
    p_last_n_minutes IN NUMBER,
    p_date_format IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    l_days NUMBER;
    l_format VARCHAR2(32767) := 'hh24:mi:ss';
    
  BEGIN
    logger.entering('logged_data');
    
    logger.fb(
      'p_last_n_minutes=' || p_last_n_minutes ||
      ', p_date_format=' || p_date_format ||
      ', p_type=' || p_type);
    
    IF (p_date_format IS NOT NULL)
    THEN
      -- check the specified date format works
      DECLARE
        l_dummy VARCHAR2(32767);
        
      BEGIN
        l_dummy := TO_CHAR(SYSDATE, p_date_format);
        logger.fb('using specified date format');
        l_format := p_date_format;
        
      EXCEPTION
        WHEN OTHERS
        THEN
          messages.add_message(
            messages.message_level_error,
            'Specified date format "' || p_date_format || '" is invalid. ' ||
            'The default format "hh24:mi:ss" was used instead',
            SQLERRM);
        
      END;
      
    END IF;
    
    IF (p_last_n_minutes IS NULL)
    THEN
      IF (p_type = 'all')
      THEN
        logger.fb('p_last_n_minutes is null. type is all. will use 1 minute');
        l_days := 1 / 24 / 60;
        
      ELSE
        logger.fb('p_last_n_minutes is null. type is not all. will use 1 day');
        l_days := 1;
        
      END IF;
      
    ELSE
      logger.fb('p_last_n_minutes is not null. setting minutes');
      l_days := 1 / 24 / 60;
      l_days := l_days * p_last_n_minutes;
      
    END IF; -- End of IF (p_last_n_minutes IS NULL)
    
    IF (p_type = 'all')
    THEN
      OPEN l_result FOR
      SELECT *
      FROM (
        SELECT 
          TO_CHAR(log_date, l_format) AS log_date, log_user, log_id, 
          log_seq, 'ERROR (' || log_level || ')' AS log_level, log_data, 
          module_owner, module_name, module_line, 
          module_type, module_call_level, error_message, 
          error_code, error_backtrace, call_stack, 'error' AS source
        FROM 
          logger_error_data
        WHERE 
          log_date > SYSDATE - l_days
        UNION ALL
        SELECT 
          TO_CHAR(log_date, l_format), log_user, log_id, 
          log_seq, DECODE(log_level, 98, 'enter', 99, 'exit', 200, 'INFO', 500, 'WARN', log_level), log_data, 
          module_owner, module_name, module_line, 
          module_type, module_call_level, '', 
          TO_NUMBER(NULL), '', '', 'feedback'
        FROM 
          logger_feedback_data
        WHERE 
          log_date > SYSDATE - l_days
        )
      ORDER BY log_date DESC, log_id DESC;
       
    ELSIF (p_type = 'error')
    THEN
      OPEN l_result FOR
      SELECT TO_CHAR(log_date, l_format) AS log_date, log_user, log_id, 
             log_seq, log_level, log_data, 
             module_owner, module_name, module_line, 
             module_type, module_call_level, error_message, 
             error_code, error_backtrace, call_stack
        FROM logger_error_data
       WHERE log_date > SYSDATE - l_days
       ORDER BY log_date DESC, log_id DESC;
       
    END IF; -- End of IF (p_type = 'all')
    
    RETURN l_result;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to get logged data. p_type=' || p_type ||
        ', p_last_n_minutes=' || p_last_n_minutes ||
        ', p_date_format=' || p_date_format);
      RAISE;
  
  END logged_data;
  
  FUNCTION get_logged_data(
    p_last_n_minutes IN NUMBER,
    p_date_format IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
  BEGIN
    logger.entering('get_logged_data');
    
    RETURN logged_data('all', p_last_n_minutes, p_date_format);
  
  END get_logged_data;
  
  FUNCTION get_logged_errors(
    p_last_n_minutes IN NUMBER,
    p_date_format IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
  BEGIN
    logger.entering('get_logged_errors');
    
    RETURN logged_data('error', p_last_n_minutes, p_date_format);
  
  END get_logged_errors;
  
END logger_admin;
/
