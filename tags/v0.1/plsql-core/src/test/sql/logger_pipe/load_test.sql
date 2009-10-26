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

declare
  /*### TEST CONFIGURATION ###*/
  
  -- number of logger calls to make before running tests
  l_warm_up_call_count integer := 1000;
  
  -- number of logger calls to make during tests
  l_test_call_count integer := 5000;
  
  -- number of sessions to create to make logging calls
  l_logging_sessions_count integer := 5;
  
  -- start time for sessions created to make logging calls
  l_start date := sysdate + (1/24/60/30);
  
  -- number of receivers to use
  l_receiver_count integer := 1;
  
  -- max number of seconds to wait for logging sessions to complete
  l_max_post_test_wait_time INTEGER := 60;
  
  /*### END OF TEST CONFIGURATION ###*/
  
  
  l_start_time number;
  l_end_time number;
  
  -- expected number of rows created in the logger_feedback table
  l_expected integer := 
    l_warm_up_call_count + 
    (l_test_call_count * l_logging_sessions_count) + 
    l_logging_sessions_count;
  -- actual number of rows created in the logger_feedback table
  l_count integer;
  -- job ID of job created for logging session
  l_job_id number;
  -- code to be executed by the logging sessions
  l_job_what varchar2(32767);
  
  procedure p(
    p_data in varchar2
  )
  is
  begin
    dbms_output.put_line(p_data);
  end;
  
  procedure assert(
    p_condition in boolean,
    p_message in varchar2
  )
  is
  begin
    if (not p_condition or p_condition is null)
    then
      raise_application_error(
        -20000, p_message);
    end if;
  end;
  
begin
  update logger_pipe_config
  set receiver_count = l_receiver_count;
  commit;
  
  execute immediate 'TRUNCATE TABLE logger_feedback_data';
  
  logger_pipe.startup;
  
  logger.set_feedback_level(-9);
  
  for i in 1 .. l_warm_up_call_count
  loop
    logger.fb(i);
  end loop;
  
  l_job_what := '
    begin 
      for i in 1 .. ' || l_test_call_count || '
      loop
        logger.set_feedback_level(-9);
        logger.fb(''from job: '' || i);
      end loop;
      logger.fb(''LAST MESSAGE'');
    end;';
  
  p('logging session will execute' || l_job_what);
  
  for i in 1 .. l_logging_sessions_count
  loop
    dbms_job.submit(l_job_id, l_job_what, l_start);
    p('created job ' || l_job_id);
  end loop;
  commit;
  
  l_start_time := dbms_utility.get_time;
  
  for i in 1 .. l_max_post_test_wait_time * 4
  loop
    select count (*) into l_count
    from logger_feedback_data
    where log_data = 'LAST MESSAGE';
    if (l_count = l_logging_sessions_count)
    then
      exit;
    end if;
    DBMS_LOCK.SLEEP(0.25);
  end loop;
  
  l_end_time := dbms_utility.get_time;
  
  logger_pipe.shutdown;
  
  p('');
  p('l_warm_up_call_count       : ' || l_warm_up_call_count);
  p('l_test_call_count          : ' || l_test_call_count);
  p('l_logging_sessions_count   : ' || l_logging_sessions_count);
  p('l_receiver_count           : ' || l_receiver_count);
  p('l_max_post_test_wait_time  : ' || l_max_post_test_wait_time);
  p('');
  
  select count (*) into l_count
  from logger_feedback_data;
  
  assert(
    l_count = l_expected,
    '1) expected ' || l_expected || ' found ' || l_count);
  
  p(l_logging_sessions_count || ' session(s), each logging ' || 
    l_test_call_count || ' call(s) took ' || 
    l_receiver_count || ' receiver(s) ' || 
    (l_end_time - l_start_time) || ' ms');
  
exception
  when others
  then 
    logger_pipe.shutdown;
    dbms_output.put_line(sqlerrm);
    raise;
    
end;
