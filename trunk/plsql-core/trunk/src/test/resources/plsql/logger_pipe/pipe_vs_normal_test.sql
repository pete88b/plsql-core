/*
Run pipe_vs_normal_test_logger_feedback.bdy to build logger_feedback body
before running this test.

*/
declare
  /*### TEST CONFIGURATION ###*/
  
  -- set to true to run pipe version before normal
  l_pipe_first boolean := false;
  
  -- number of logger calls to make (to both pipe and normal) before running tests
  l_warm_up_call_count integer := 1000;
  
  -- number of logger calls to make (to both pipe and normal) during tests
  l_test_call_count integer := 9999;
  
  -- number of receivers to use
  l_receiver_count integer := 2;
  
  -- value of job_queue_interval DB init param
  l_job_queue_interval number := 60;
  
  /*### END OF TEST CONFIGURATION ###*/
  
  
  l_run1_name varchar2(32767);
  l_run2_name varchar2(32767);
  l_count integer;
  
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
  if (l_pipe_first)
  then
    l_run1_name := 'pipe';
    l_run2_name := 'normal';
  else
    l_run1_name := 'normal';
    l_run2_name := 'pipe';
  end if;
  
  update logger_pipe_config
  set receiver_count = l_receiver_count;
  commit;
  
  execute immediate 'TRUNCATE TABLE logger_feedback_data';
  
  logger.set_feedback_level(-9);
  
  logger_pipe.startup;
  
  dbms_lock.sleep(l_job_queue_interval);
  
  for i in 1 .. l_warm_up_call_count
  loop
    logger.log(101, '101.' || i);
    logger.log(102, '102.' || i);
    
  end loop;
  
  stats.run1(l_run1_name);
  
  for i in 1 .. l_test_call_count
  loop
    if (l_pipe_first)
    then
      logger.log(101, '101.' || i);
    else
      logger.log(102, '102.' || i);
    end if;
    
  end loop;
  
  DBMS_LOCK.SLEEP(1);
  
  stats.run2(l_run2_name);
  
  DBMS_LOCK.SLEEP(1);
  
  for i in 1 .. l_test_call_count
  loop
    if (l_pipe_first)
    then
      logger.log(102, '102.' || i);
    else
      logger.log(101, '101.' || i);
    end if;
    
  end loop;
  
  stats.stop(1);
  
  logger_pipe.shutdown;
  
  p('');
  p('l_warm_up_call_count: ' || l_warm_up_call_count);
  p('l_test_call_count   : ' || l_test_call_count);
  p('l_receiver_count    : ' || l_receiver_count);
  p('');
  if (l_pipe_first)
  then
    p('pipe was tested first');
  else
    p('normal was tested first');
  end if;
  
  select count (*) into l_count
  from logger_feedback_data;
  
  assert(
    l_count = ((l_warm_up_call_count + l_test_call_count) * 2 ),
    '1) expected ' || ((l_warm_up_call_count + l_test_call_count) * 2 ) || 
      ' found ' || l_count);
  
  select count (*) into l_count
  from logger_feedback_data
  where log_data like 'PIPE%';
  
  assert(
    l_count = (l_warm_up_call_count + l_test_call_count),
    '2) expected ' || (l_warm_up_call_count + l_test_call_count) || 
      ' found ' || l_count);
  
exception
  when others
  then 
    dbms_output.put_line(sqlerrm);
    logger_pipe.shutdown;
    raise;
    
end;
