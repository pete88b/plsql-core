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
test to demonstrate that the logging tx is autonomous of the calling tx.
this test should fail if using the normal logger on 8i as you can't start
an autonomous tx from within a ditributed tx.
*/
declare
  /*### TEST CONFIGURATION ###*/
  
  -- see also SET DB LINK HERE below
  
  -- set to true if testing pipe implementation, false otherwise
  l_test_pipe boolean := true;
  
  -- value of job_queue_interval DB init param
  -- this is only used if testing pipe mode
  l_job_queue_interval number := 60;
  
  /*### END OF TEST CONFIGURATION ###*/
  
  
  l_count integer;
  
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
  
  procedure p(
    p_data in varchar2
  )
  is
  begin
    dbms_output.put_line(
      substr(
        to_char(SYSDATE, 'ddMonyyyy hh24:mi:ss') || 
        ' (TEST SCRIPT) ' || p_data, 
      1, 255));
  end;
  
begin
  execute immediate 'TRUNCATE TABLE logger_feedback_data';
  execute immediate 'TRUNCATE TABLE logger_flags';
  
  if (l_test_pipe)
  then
    execute immediate 'begin logger_pipe.use_dbms_output; end;';
    execute immediate 'begin logger_pipe.startup; end;';
  end if;
  
  insert into logger_flags(log_user, log_level)
  values('deleteme', 0);
  
  p('doing select over DB link');
  -- /*### SET DB LINK HERE ###*/
  select null into l_count from dual@&db_link_name.;
  p('select over DB link complete');
  
  logger.set_feedback_level(-9);
  -- this should fail with normal logger on 8i
  logger.fb('logged from within a distributed tx');
  
  p('waiting for the jobs to be started');
  if (l_test_pipe)
  then
    -- wait for the jobs to be started and give receivers a chance to receive
    for i in 1 .. (l_job_queue_interval + 2)
    loop
      dbms_lock.sleep(1);
    end loop;
  end if;
  
  p('finished waiting');
  
  rollback;
  
  select count(*) into l_count from logger_feedback_data;
  
  assert(
    l_count = 1,
    'failed to create logger_feedback_data row');
    
  select count(*) into l_count from logger_flags;
  
  assert(
    l_count = 0,
    'failed to rollback logger_flags insert');
  
  if (l_test_pipe)
  then
    execute immediate 'begin logger_pipe.shutdown; end;';
  end if;
  
exception
  when others
  then 
    dbms_output.put_line(substr(sqlerrm, 1, 255));
    if (l_test_pipe)
    then
      execute immediate 'begin logger_pipe.shutdown; end;';
    end if;
    raise;
    
end;
