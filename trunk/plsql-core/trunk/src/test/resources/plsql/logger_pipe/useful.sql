update logger_pipe_config
set listener_count = 2;

select * from logger_pipe_config;

begin
  logger_pipe.use_dbms_output;
  logger_pipe.startup;
end;

select * from logger_pipe_config;

select a.*, rowid from logger_pipe_receivers a

select * from user_jobs;

select * from v$session where module like 'logger_pipe%';

begin
  logger.error('test err2.1');
end;

select * from logger_data_recent
  

begin  
  logger_pipe.use_dbms_output;
  logger_pipe.check_receivers;
end;

begin  
  logger_pipe.use_dbms_output;
  logger_pipe.shutdown;
end;

select * from v$db_pipes


begin
  DBMS_PIPE.RESET_BUFFER;
  DBMS_PIPE.PACK_MESSAGE('shutdown');
  DBMS_OUTPUT.PUT_LINE(DBMS_PIPE.SEND_MESSAGE('LOGGER_TEST_logger_pipe'));
end;

begin
  dbms_job.remove(93);
  commit;
end;

begin
  for i in (select * from user_jobs)
  loop
    dbms_job.remove(i.job);
  end loop;
  commit;
end;
