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

CREATE OR REPLACE PACKAGE BODY logger_pipe
IS
  
  g_config logger_pipe_config%ROWTYPE;
  
  g_job_tag CONSTANT VARCHAR2(32767) := '/*Created by logger_pipe.startup*/';
  
  g_use_dbms_output BOOLEAN := FALSE;
  
  PROCEDURE use_dbms_output
  IS
  BEGIN
    g_use_dbms_output := TRUE;
  END use_dbms_output;
  
  /*
  */
  PROCEDURE p(
    p_module IN VARCHAR2, 
    p_data IN VARCHAR2 := NULL
  )
  IS
  BEGIN
    IF (g_use_dbms_output)
    THEN
      DBMS_OUTPUT.PUT_LINE(
        SUBSTR(
          TO_CHAR(SYSDATE, 'ddMonyyyy hh24:mi:ss') || 
          ' (' || p_module || ') ' || p_data, 
        1, 255));
    END IF;
  END;

  /*
  */
  PROCEDURE assert(
    p_condition BOOLEAN,
    p_message VARCHAR2
  )
  IS
  BEGIN
    IF (NOT p_condition OR p_condition IS NULL)
    THEN
      p('assert', 'Raising error: ' || p_message);
      RAISE_APPLICATION_ERROR(-20000, p_message);
    END IF;
  END;

  /*
  */
  PROCEDURE load_global_config
  IS
  BEGIN
    p('load_global_config');
    
    SELECT * INTO g_config FROM logger_pipe_config;
    
  END load_global_config;

  /*
  */
  PROCEDURE set_pipe_status(
    p_status IN VARCHAR2
  )
  IS
  BEGIN
    p('set_pipe_status', p_status);
    
    UPDATE logger_pipe_config
    SET pipe_status = p_status;
    
    COMMIT;
    
  END set_pipe_status;
  
  /*
  */
  PROCEDURE start_receivers(
    p_how_many IN INTEGER
  )
  IS
    l_job BINARY_INTEGER;
    l_receiver_rowid VARCHAR2(32767);
    
  BEGIN
    p('start_receivers', 'creating ' || p_how_many || ' receivers');
    
    FOR i IN 1 .. p_how_many
    LOOP
      INSERT INTO logger_pipe_receivers(started)
      VALUES(SYSDATE)
      RETURNING ROWID INTO l_receiver_rowid;
        
      DBMS_JOB.SUBMIT(
        l_job, 
        g_job_tag || 
        'logger_pipe.receive_logger_call(''' || l_receiver_rowid || ''');');
      
      UPDATE logger_pipe_receivers
         SET job_id = l_job
       WHERE ROWID = l_receiver_rowid;
      
      COMMIT;
      
      p('start_receivers', 'created job. id=' || l_job);
      
    END LOOP;
    
  END start_receivers;
  
  PROCEDURE stop_receivers(
    p_how_many IN INTEGER
  )
  IS
    l_pipe_result INTEGER;
    
  BEGIN
    p('stop_receivers', 'stopping ' || p_how_many || ' receivers');
    
    FOR i IN 1 .. p_how_many
    LOOP
      DBMS_PIPE.RESET_BUFFER;
      DBMS_PIPE.PACK_MESSAGE('shutdown');
      -- use the default timeout and pipe size for sending shutdown messages
      l_pipe_result := DBMS_PIPE.SEND_MESSAGE(g_config.pipe_name);
    
      assert(
        l_pipe_result = 0,
        'Failed to send message. return value was ' || l_pipe_result);
        
    END LOOP;
    
  END stop_receivers;
  
  /*
  */
  PROCEDURE startup
  IS
    l_pipe_result INTEGER := 0;
    
  BEGIN
    p('startup');
    
    load_global_config;
    
    assert(
      g_config.pipe_status = 'stopped',
      'Failed to startup as the pipe is not stopped. Current status=' || 
      g_config.pipe_status);
    
    set_pipe_status('starting');
    
    l_pipe_result := DBMS_PIPE.CREATE_PIPE(g_config.pipe_name, g_config.max_pipe_size, FALSE);
    
    assert(
      l_pipe_result = 0,
      'Failed to create pipe "' || g_config.pipe_name || 
      '". return value was ' || l_pipe_result);
    
    p('startup', 'created pipe. name=' || g_config.pipe_name);
    
    start_receivers(g_config.receiver_count);
    
    set_pipe_status('started');
    
  END startup;
  
  /*
  */
  PROCEDURE shutdown
  IS
    l_pipe_result INTEGER;
    
  BEGIN
    p('shutdown');
        
    set_pipe_status('stopping');
    
    p('shutdown', 
      'sending ' || g_config.receiver_count || ' shutdown messages (' ||
      'plus one for the shutdown receiver)');
    
    stop_receivers(g_config.receiver_count + 1);
          
    -- receive any logger calls left in the pipe
    receive_logger_call(NULL);
    
    -- update v$session into so people don't think we we're a real receiver
    DBMS_APPLICATION_INFO.SET_MODULE('logger_pipe.shutdown', NULL);
    
    <<wait_for_receivers>>
    DECLARE
      l_count INTEGER;
        
    BEGIN
      <<wait_for_receivers_loop>>
      FOR i IN 1 .. 9 -- xxx todo config limit
      LOOP
        SELECT COUNT(*) INTO l_count
        FROM logger_pipe_receivers;
        
        IF (l_count = 0)
        THEN
          p('shutdown', 'receivers have all shutdown normally');
          EXIT wait_for_receivers_loop;
          
        END IF;
        
        p('shutdown', 'waiting for ' || l_count || ' receivers after ' || i || ' attempt(s)');
        
        DBMS_LOCK.SLEEP(i);
        
      END LOOP wait_for_receivers_loop;
      
      IF (l_count > 0)
      THEN
        p('shutdown', 
          'Receivers failed to shutdown. ' || 
          'Please check jobs and remove logger_pipe_receivers data manually');
            
      END IF;
      
    END wait_for_receivers;
    
    p('shutdown', 'removing pipe');
    
    l_pipe_result := DBMS_PIPE.REMOVE_PIPE(g_config.pipe_name);
    
    assert(
      l_pipe_result = 0,
      'Failed to remove pipe "' || g_config.pipe_name || 
      '". return value was ' || l_pipe_result);
    
    set_pipe_status('stopped');
    
  EXCEPTION
    WHEN OTHERS
    THEN
      IF (g_config.suppress_errors = 'Y')
      THEN
        NULL;
      ELSE
        RAISE;
      END IF;
    
  END shutdown;
  
  /*
  */
  --xxx todo fix this
  PROCEDURE check_receivers
  IS
    l_receiver_count INTEGER;
    
  BEGIN
    p('check_receivers');
    
    load_global_config;
    
    assert(
      g_config.pipe_status NOT LIKE '%ing',
      'Failed to check receivers as the pipe is ' || g_config.pipe_status);
    
    IF (g_config.pipe_status = 'started')
    THEN
      p('check_receivers', 'pipe is started');
      
      DELETE FROM logger_pipe_receivers
       WHERE NOT EXISTS
             (SELECT NULL
                FROM user_jobs
               WHERE user_jobs.job = logger_pipe_receivers.job_id);
      
      IF (SQL%ROWCOUNT > 0)
      THEN
        p('check_receivers', 
          'removed ' || SQL%ROWCOUNT || ' logger_pipe_receivers records with no job');
          
      END IF;
      
      COMMIT;
      
      -- see if the number of receivers in logger_pipe_receivers matches the 
      -- required receiver count
      SELECT COUNT(*) INTO l_receiver_count
      FROM logger_pipe_receivers;
      
      p('check_receivers', 
        'required receiver_count=' || g_config.receiver_count ||
        ', actual receiver_count=' || l_receiver_count);
      
      IF (l_receiver_count < g_config.receiver_count)
      THEN
        p('check_receivers', 'not enough receivers');
        
        start_receivers(g_config.receiver_count - l_receiver_count);
        
      ELSIF (l_receiver_count > g_config.receiver_count)
      THEN
        p('check_receivers', 'too many receivers');
        
        stop_receivers(l_receiver_count - g_config.receiver_count);
        
      END IF;
      
    END IF; -- End of IF (g_config.pipe_status = 'started')
    
    
    -- check for rougue jobs
    FOR i IN (SELECT job
                FROM user_jobs
               WHERE what LIKE g_job_tag || '%'
                 AND NOT EXISTS
                     (SELECT NULL
                        FROM logger_pipe_receivers
                       WHERE user_jobs.job = logger_pipe_receivers.job_id))
    LOOP
      p('check_receivers', 'found rogue job ' || i.job);
      
    END LOOP;
    
    -- check for rogue sessions
    FOR i IN (SELECT sid, serial#
                FROM v$session
               WHERE module = 'logger_pipe.receive_logger_call'
                 AND NOT EXISTS
                     (SELECT NULL
                        FROM logger_pipe_receivers
                       WHERE v$session.action = logger_pipe_receivers.ROWID))
    LOOP
      p('check_receivers', 
        'found rogue session. sid=' || i.sid || ', serial#=' || i.serial#);
      
    END LOOP;
    
    -- no need to check for jobs with no v$session as the jobs are run once
    
  EXCEPTION
    WHEN OTHERS
    THEN
      IF (g_config.suppress_errors = 'Y')
      THEN
        NULL;
      ELSE
        RAISE;
      END IF;
      
  END check_receivers;
  
  /*
  */
  PROCEDURE receive_logger_call(
    p_receiver_rowid IN VARCHAR2
  )
  IS
    l_pipe_result INTEGER;
    l_command VARCHAR2(32757);
    l_log_date DATE;
    l_log_user VARCHAR2(32757);
    l_log_id INTEGER;
    l_log_level PLS_INTEGER;
    l_log_data VARCHAR2(32757);
    l_module_owner VARCHAR2(32757);
    l_module_name VARCHAR2(32757);
    l_module_line NUMBER; 
    l_module_type VARCHAR2(32757);
    l_module_call_level INTEGER; 
    l_error_code INTEGER;
    l_error_message VARCHAR2(32757);
    l_call_stack VARCHAR2(32757);
    l_audsid NUMBER;
    
  BEGIN
    p('receive_logger_call');
    
    -- set v$session info so people know what this session is doing
    DBMS_APPLICATION_INFO.SET_MODULE(
      'logger_pipe.receive_logger_call', p_receiver_rowid); 
    
    <<receive_loop>>
    LOOP
      l_pipe_result := DBMS_PIPE.RECEIVE_MESSAGE(
        g_config.pipe_name, g_config.receive_max_wait);
      
      p('receive_logger_call', 'got message');
      
      DBMS_PIPE.UNPACK_MESSAGE(l_command);
      
      IF (l_command = 'shutdown')
      THEN
        p('receive_logger_call', 'got shutdown message');
        
        DELETE FROM logger_pipe_receivers
        WHERE ROWID = p_receiver_rowid;
        
        COMMIT;
        
        -- update v$session into so people know we've stopped receiving
        DBMS_APPLICATION_INFO.SET_MODULE(
          'logger_pipe.receive_logger_call(Complete)', p_receiver_rowid);
        
        -- Stop receiving messages
        EXIT receive_loop;
        
      END IF; -- End of IF (l_command = 'shutdown')
      
      -- if we get here, we're not shutting down.
      -- make sure the command type is valid
      IF (l_command IN ('error', 'feedback'))
      THEN
        p('receive_logger_call', 'unpacking full message');
        
        DBMS_PIPE.UNPACK_MESSAGE(l_log_date);
        DBMS_PIPE.UNPACK_MESSAGE(l_log_user);
        DBMS_PIPE.UNPACK_MESSAGE(l_log_id);
        DBMS_PIPE.UNPACK_MESSAGE(l_log_level);
        DBMS_PIPE.UNPACK_MESSAGE(l_log_data);
        DBMS_PIPE.UNPACK_MESSAGE(l_module_owner);
        DBMS_PIPE.UNPACK_MESSAGE(l_module_name);
        DBMS_PIPE.UNPACK_MESSAGE(l_module_line);
        DBMS_PIPE.UNPACK_MESSAGE(l_module_type);
        DBMS_PIPE.UNPACK_MESSAGE(l_module_call_level);
        DBMS_PIPE.UNPACK_MESSAGE(l_error_code);
        DBMS_PIPE.UNPACK_MESSAGE(l_error_message);
        DBMS_PIPE.UNPACK_MESSAGE(l_call_stack);
        DBMS_PIPE.UNPACK_MESSAGE(l_audsid);
        
        IF (l_command = 'error')
        THEN
          p('receive_logger_call', 'got error message');
          
          INSERT INTO logger_error_data(
            log_date, log_user, log_id,
            log_seq, log_level, log_data,
            module_owner, module_name, module_line, 
            module_type, module_call_level, error_code,
            error_message, error_backtrace, 
            call_stack, log_audsid)
          VALUES(
            l_log_date, l_log_user, l_log_id,
            0, l_log_level, l_log_data,
            l_module_owner, l_module_name, l_module_line, 
            l_module_type, l_module_call_level, l_error_code,
            l_error_message, NULL, 
            l_call_stack, l_audsid);
          
        ELSE
          p('receive_logger_call', 'got feedback message');
        
          INSERT INTO logger_feedback_data(
            log_date, log_user, log_id,
            log_seq, log_level, log_data,
            module_owner, module_name, module_line, 
            module_type, module_call_level, log_audsid)
          VALUES(
            l_log_date, l_log_user, l_log_id,
            0, l_log_level, l_log_data,
            l_module_owner, l_module_name, l_module_line, 
            l_module_type, l_module_call_level, l_audsid);
        
        END IF;
        
        -- commit the insert 
        -- (for either logger_error_data or logger_feedback_data)
        COMMIT;
        
      ELSE
        p('receive_logger_call', 'unknown command "' || l_command || '"');
        
      END IF; -- End if IF (l_command IN ('error', 'feedback'))
      
    END LOOP receive_loop;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      IF (g_config.suppress_errors = 'Y')
      THEN
        NULL;
      ELSE
        RAISE;
      END IF;
      
  END receive_logger_call;
  
  /*
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
  )
  IS
    l_pipe_result INTEGER;
    
  BEGIN
    p('log');
    
    DBMS_PIPE.RESET_BUFFER;
    DBMS_PIPE.PACK_MESSAGE(p_log_type);
    DBMS_PIPE.PACK_MESSAGE(p_log_date);
    DBMS_PIPE.PACK_MESSAGE(p_log_user);
    DBMS_PIPE.PACK_MESSAGE(p_log_id);
    DBMS_PIPE.PACK_MESSAGE(p_log_level);
    DBMS_PIPE.PACK_MESSAGE(SUBSTR(p_log_data, 1, 4000));
    DBMS_PIPE.PACK_MESSAGE(p_module_owner);
    DBMS_PIPE.PACK_MESSAGE(p_module_name);
    DBMS_PIPE.PACK_MESSAGE(p_module_line);
    DBMS_PIPE.PACK_MESSAGE(p_module_type);
    DBMS_PIPE.PACK_MESSAGE(p_module_call_level);
    DBMS_PIPE.PACK_MESSAGE(p_error_code);
    DBMS_PIPE.PACK_MESSAGE(SUBSTR(p_error_message, 1, 4000));
    DBMS_PIPE.PACK_MESSAGE(SUBSTR(p_call_stack, 1, 4000));
    DBMS_PIPE.PACK_MESSAGE(p_audsid);
    
    l_pipe_result := DBMS_PIPE.SEND_MESSAGE(
      g_config.pipe_name, g_config.send_max_wait, g_config.max_pipe_size);
    
    assert(
      l_pipe_result = 0,
      'Failed to send message. return value was ' || l_pipe_result);
      
  EXCEPTION
    WHEN OTHERS
    THEN
      IF (g_config.suppress_errors = 'Y')
      THEN
        NULL;
      ELSE
        RAISE;
      END IF;
    
  END log;
  
/*
*/
BEGIN
  load_global_config;
  
END;
/
