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
  Tests for logger_error_post_10. 
*/
declare

  procedure a(
    p_what in integer
  )
  is
    l_dummy integer;
  begin
    if (p_what = 1)
    then
      raise no_data_found;
      
    elsif (p_what = 2)
    then
      raise too_many_rows;
      
    else
      raise_application_error(-20002, 'test error message');
      
    end if;
    
  exception
    when others
    then
      logger.error('logger_error_post_10.a');
      
  end;

  procedure b
  is
  begin
    logger.error(rpad('b', 4000, 'b') || rpad('B', 4000, 'B') || '.');
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
  
  function get_current_log_id
  return integer
  is
    l_result integer;
  begin
    select logger_data_log_id.currval into l_result from dual;
    return l_result;
  end;
  
  procedure assert_row_exists(
    p_log_data          in varchar2, 
    p_module_owner      in varchar2, 
    p_module_name       in varchar2, 
    p_module_line       in integer, 
    p_module_type       in varchar2, 
    p_module_call_level in integer, 
    p_error_code        in integer, 
    p_error_message     in varchar2, 
    p_log_seq           in integer  := 1,
    p_error_backtrace   in varchar2 := null,
    p_log_date          in date     := sysdate, 
    p_log_user          in varchar2 := user, 
    p_log_id            in integer  := get_current_log_id,
    p_log_level         in integer  := 6000
  )
  is
    l_dummy integer;
    
  begin
    -- 10g can make a bit of a mess of sqlerrm. e.g. having raised no_data_found, 
    -- sqlerrm sometimes contains the expected error message 3 times. which is
    -- why we have "error_message like p_error_message || '%' " below
    select null into l_dummy
      from logger_error_data
     where log_date between (p_log_date - (24/60/60)) and (p_log_date + (24/60/60))
       and (log_user = p_log_user or (log_user is null and p_log_user is null))
       and (log_id = p_log_id or (log_id is null and p_log_id is null))
       and (log_seq = p_log_seq or (log_seq is null and p_log_seq is null))
       and (log_level = p_log_level or (log_level is null and p_log_level is null))
       and (log_data = p_log_data or (log_data is null and p_log_data is null))
       and (module_owner = p_module_owner or (module_owner is null and p_module_owner is null))
       and (module_name = p_module_name or (module_name is null and p_module_name is null))
       and (module_line = p_module_line or (module_line is null and p_module_line is null))
       and (module_type = p_module_type or (module_type is null and p_module_type is null))
       and (module_call_level = p_module_call_level or (module_call_level is null and p_module_call_level is null))
       and (error_code = p_error_code or (error_code is null and p_error_code is null))
       and (error_message like p_error_message || '%' or (error_message is null and p_error_message is null))
       and ((error_backtrace is not null and p_error_backtrace is not null) or (error_backtrace is null and p_error_backtrace is null));
  
  end;
  
begin
  execute immediate 'truncate table logger_error_data';
  
  a(1);
  
  assert_row_exists(
    'logger_error_post_10.a',    -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    28,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2,                          -- p_module_call_level 
    100,                        -- p_error_code (for no_data_found Oracle uses ANSI standard sqlcode)
    'ORA-01403: no data found', -- p_error_message. 
    1,
    'not null');
    
  a(2);
  assert_row_exists(
    'logger_error_post_10.a',    -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    28,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2,                          -- p_module_call_level 
    -1422,                      -- p_error_code 
    'ORA-01422: exact fetch returns more than requested number of rows',-- p_error_message
    1,
    'not null');
    
  a(3);
  assert_row_exists(
    'logger_error_post_10.a',    -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    28,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2,                          -- p_module_call_level 
    -20002,                     -- p_error_code 
    'ORA-20002: test error message',-- p_error_message
    1,
    'not null');
    
  b;
  assert_row_exists(
    rpad('b', 4000, 'b'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    35,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2,                          -- p_module_call_level 
    0,                          -- p_error_code 
    'ORA-0000: normal, successful completion');-- p_error_message
  
  assert_row_exists(
    rpad('B', 4000, 'B'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    35,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2,                          -- p_module_call_level 
    0,                          -- p_error_code 
    null,                       -- p_error_message
    2);                         --p_log_seq
    
  assert_row_exists(
    '.',                        -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    35,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2,                          -- p_module_call_level 
    0,                          -- p_error_code 
    null,                       -- p_error_message
    3);                         --p_log_seq
  
end;
