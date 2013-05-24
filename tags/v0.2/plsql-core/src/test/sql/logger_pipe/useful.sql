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
