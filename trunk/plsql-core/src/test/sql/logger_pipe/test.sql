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
This is the normal logger test script, modified slightly to test the pipe
implementation.
*/
DECLARE
  /*### TEST CONFIGURATION ###*/
  
  -- value of job_queue_interval DB init param
  l_job_queue_interval number := 60;
  
  -- number of seconds to wait between making a logger call and looking for the
  -- log entry. 
  l_post_log_wait_time number := 0.25;
  
  /*### END OF TEST CONFIGURATION ###*/
  
  /*
  */
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(s);
  END p;
  
  /*
  */
  PROCEDURE setup
  IS
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_error_data';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_feedback_data';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_flags';
    logger.set_feedback_level(logger.g_default_feedback_level);
    logger_utils.set_user(USER);
    
  END setup;
  
  /*
  */
  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    IF (NOT p_condition OR p_condition IS NULL)
    THEN
      raise_application_error(
        -20000, p_message);
    END IF;
  END;
  
  /*
  */
  PROCEDURE assert_table_has_rows(
    p_table_name IN VARCHAR2,
    p_expected_rows IN NUMBER,
    p_message IN VARCHAR2 := NULL
  )
  IS
    l_count NUMBER;
    
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table_name
    INTO l_count;
    assert(
      l_count = p_expected_rows,
      p_table_name || ' has ' || l_count || ' rows. expected ' || 
      p_expected_rows || '. ' || p_message);
  END;
    
  
  /*
  */
  PROCEDURE assert_log_exists(
    p_type IN VARCHAR2, -- error, feedback
    p_level IN INTEGER,
    p_data IN VARCHAR2,
    p_user IN VARCHAR2 := USER
  )
  IS 
    l_type VARCHAR2(32767);
  BEGIN
    p(CHR(10) || 'Start of assert_log_exists');
    DBMS_LOCK.SLEEP(l_post_log_wait_time);
    p('p_type=' || p_type || ', p_level=' || p_level || ', p_data=' || p_data || ', p_user=' || p_user);
    
    IF (p_type IS NOT NULL AND p_type != 'error' AND p_type != 'feedback')
    THEN
      RAISE_APPLICATION_ERROR(-20000, 'invalid p_type. ' || p_type);
    END IF;
    
    SELECT 
      t INTO l_type
    FROM (
      SELECT 
        'error' AS t, log_user, log_level, log_data, 
         module_owner, module_name, module_line, 
         module_type, module_call_level, error_message,
         error_code, error_backtrace, call_stack
       FROM   
         logger_error_data
       UNION ALL
       SELECT 
         'feedback', log_user, log_level, log_data, 
         module_owner, module_name, module_line, 
         module_type, module_call_level, '', 
         TO_NUMBER(NULL), '', ''
       FROM 
         logger_feedback_data
       )
    WHERE (
      p_level IS NULL OR log_level = p_level
      )
    AND (
      p_data IS NULL OR log_data = p_data
      )
    AND (
      p_user IS NULL OR log_user = p_user
      ); 
    
    IF (p_type IS NOT NULL AND p_type != l_type)
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 
        'Found entry under wrong type. expected=' || p_type || ' found='|| l_type);
    END IF;
    
    p('assert_log_exists: ok');
    
  EXCEPTION
    WHEN OTHERS
    THEN
      p('assert_log_exists exception: ' || SQLERRM);
      RAISE;
      
  END assert_log_exists;
  
  /*
  */
  PROCEDURE assert_log_not_exists(
    p_type IN VARCHAR2, -- error, feedback
    p_level IN INTEGER,
    p_data IN VARCHAR2,
    p_user IN VARCHAR2 := NULL
  )
  IS 
  BEGIN
    p(CHR(10) || 'Start of assert_log_not_exists');
    
    assert_log_exists(p_type, p_level, p_data, p_user);
    
    p('assert_log_not_exists: raising TOO_MANY_ROWS');
    RAISE TOO_MANY_ROWS;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN 
      p('assert_log_not_exists: ok');
      
  END assert_log_not_exists;
  
BEGIN
  logger_pipe.startup;
  
  dbms_lock.sleep(l_job_queue_interval);

  -- Start of test all feedback levels section
  -- this is run first as it would produce too much output if dbms_output
  -- is enabled.
  -- uncomment to run - expect 3 minute run time on 8i, 10 second run time on 10g.
  /*
  DBMS_OUTPUT.DISABLE;
  
  setup;
  
  FOR i IN 0 .. 5999
  LOOP
    logger.set_feedback_level(i);
    logger.log(i-1, 'nolog');
    assert_log_not_exists('feedback', i-1, 'nolog' || i, NULL);
    logger.log(i, 'log' || i);
    assert_log_exists('feedback', i, 'log' || i, NULL);
  END LOOP;  
  */
  -- End of test all feedback levels section


  DBMS_OUTPUT.ENABLE(1000000);
  
  p('Running PL/SQL test script for logger');
  p('Start time: ' || TO_CHAR(SYSDATE, 'dd-Mon-yyyy hh24:mi:ss'));
  p('');
  
  setup;
  
  p('***test default feedback level is as expected***');
  
  assert(
    logger.get_feedback_level = 100,
    'default feedback level=' || logger.get_feedback_level || ' expected=99');
  
  
  p('');
  p('***test log with default log level settings***');
  
  logger.log(99, 'log99');
  assert_log_not_exists(NULL, NULL, 'log99', NULL);
  
  logger.log(100, 'log100');
  ROLLBACK; -- make sure log insert has been commit
  assert_log_exists(NULL, NULL, 'log100', NULL);
  
  logger.log(101, 'log101');
  ROLLBACK; 
  assert_log_exists(NULL, NULL, 'log101', NULL);

  logger.log(5999, 'log5999');
  ROLLBACK; 
  assert_log_exists('feedback', NULL, 'log5999', NULL);
  
  logger.log(6000, 'log6000');
  ROLLBACK; 
  assert_log_exists('error', NULL, 'log6000', NULL);
  
  logger.log(6001, 'log6001');
  ROLLBACK; 
  assert_log_exists('error', NULL, 'log6001', NULL);
  
  
  p('');
  p('***test log level setting***');
  
  p('logger.get_feedback_level=' || logger.get_feedback_level);
  
  logger.log(99, 'log99x2');
  assert_log_not_exists(NULL, NULL, 'log99x2', NULL);
  
  logger.set_feedback_level(logger.get_feedback_level - 1);
  p('logger.get_feedback_level=' || logger.get_feedback_level);
  logger.log(99, 'log99x2');
  assert_log_exists('feedback', NULL, 'log99x2', NULL);
  
  logger.fb('fb');
  assert_log_not_exists('feedback', NULL, 'fb', NULL);
  
  logger.set_feedback_level(0);
  
  logger.fb('fb');
  ROLLBACK; 
  assert_log_exists('feedback', NULL, 'fb', NULL);
  
  logger.fb1('fb1');
  ROLLBACK; 
  assert_log_exists('feedback', 1, 'fb1', NULL);
  
  logger.fb2('fb2');
  ROLLBACK; 
  assert_log_exists('feedback', 2, 'fb2', NULL);
  
  logger.fb3('fb3');
  ROLLBACK; 
  assert_log_exists('feedback', 3, 'fb3', NULL);
  
  logger.fb4('fb4');
  ROLLBACK; 
  assert_log_exists('feedback', 4, 'fb4', NULL);
  
  logger.fb5('fb5');
  ROLLBACK; 
  assert_log_exists('feedback', 5, 'fb5', NULL);
  
  logger.entering('entering');
  ROLLBACK; 
  assert_log_exists('feedback', 98, 'entering', NULL);
  
  logger.exiting('exiting');
  ROLLBACK; 
  assert_log_exists('feedback', 99, 'exiting', NULL);
  
  logger.set_feedback_level(201);
  logger.info('info');
  assert_log_not_exists('feedback', 200, 'info', NULL);
  
  logger.set_feedback_level(200);
  logger.info('info');
  ROLLBACK; 
  assert_log_exists('feedback', 200, 'info', NULL);
  
  logger.set_feedback_level(501);
  logger.warn('warn');
  assert_log_not_exists('feedback', 500, 'warn', NULL);
  
  logger.set_feedback_level(500);
  logger.warn('warn');
  ROLLBACK; 
  assert_log_exists('feedback', 500, 'warn', NULL);
  
  -- errors should always be logged
  logger.set_feedback_level(99999);
  logger.error('error');
  ROLLBACK; 
  assert_log_exists('error', 6000, 'error', NULL);
  
  -- put the log level back
  logger.set_feedback_level(0);
  
  
  p('');
  p('***test log utils set_user***');
  
  logger.log(300, 'log300');
  assert_log_exists('feedback', NULL, 'log300', USER);
  
  logger_utils.set_user('CAPS');
  logger.log(300, 'log300');
  ROLLBACK; 
  assert_log_exists('feedback', NULL, 'log300', 'CAPS');
  
  logger_utils.set_user('anyOldUserName');
  logger.log(300, 'log300');
  ROLLBACK; 
  assert_log_exists('feedback', NULL, 'log300', 'anyOldUserName');
  
  
  p('***test logging calls run as autonomous transactions***');

  setup;

  -- insert a row into logger_flags
  -- this will be rolled back to make sure all logging calls run
  -- as autonomous transactions
  INSERT INTO logger_flags(log_user, log_level) VALUES('deleteme', 0);
  assert_table_has_rows('logger_flags', 1);

  logger.log(99, 'log99');
  assert_log_not_exists(NULL, NULL, 'log99', NULL);
  
  logger.log(100, 'log100');
  assert_log_exists(NULL, NULL, 'log100', NULL);
  
  logger.log(101, 'log101');
  assert_log_exists(NULL, NULL, 'log101', NULL);

  logger.log(5999, 'log5999');
  assert_log_exists('feedback', NULL, 'log5999', NULL);
  
  logger.log(6000, 'log6000');
  assert_log_exists('error', NULL, 'log6000', NULL);
  
  logger.log(6001, 'log6001');
  assert_log_exists('error', NULL, 'log6001', NULL);

  logger.set_feedback_level(0);
  
  logger.fb1('fb1');
  assert_log_exists('feedback', 1, 'fb1', NULL);
  
  logger.fb2('fb2');
  assert_log_exists('feedback', 2, 'fb2', NULL);
  
  logger.fb3('fb3');
  assert_log_exists('feedback', 3, 'fb3', NULL);
  
  logger.fb4('fb4');
  assert_log_exists('feedback', 4, 'fb4', NULL);
  
  logger.fb5('fb5');
  assert_log_exists('feedback', 5, 'fb5', NULL);
  
  logger.entering('entering');
  assert_log_exists('feedback', 98, 'entering', NULL);
  
  logger.exiting('exiting');
  assert_log_exists('feedback', 99, 'exiting', NULL);
  
  logger.info('info');
  assert_log_exists('feedback', 200, 'info', NULL);
  
  logger.warn('warn');
  assert_log_exists('feedback', 500, 'warn', NULL);
  
  logger.error('error');
  assert_log_exists('error', 6000, 'error', NULL);
  
  -- make sure all logging calls ran as autonomous transactions
  ROLLBACK;
  assert_table_has_rows(
    'logger_flags', 0, 
    'at least one call did not run as an autonomous transactions');
    
  
  p('');
  p('All logger tests passed');
  
  logger_pipe.shutdown;
  
EXCEPTION
  WHEN OTHERS
  THEN 
    DBMS_OUTPUT.PUT_LINE(SQLERRM);
    logger_pipe.shutdown;
    RAISE;
      
END;
