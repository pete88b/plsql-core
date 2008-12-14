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
  Tests for logger_feedback. 
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
      logger.fb('a1');
      
    elsif (p_what = 2)
    then
      logger.fb('a2');
      
    else
      logger.fb('a?');
      
    end if;
    rollback;
  end;

  procedure b_2
  is 
  begin
    logger.fb(
      rpad('b', 4000, 'b') || 
      rpad('B', 4000, 'B') || 
      rpad('c', 4000, 'c') || 
      rpad('C', 4000, 'C') ||
      rpad('d', 4000, 'd') || 
      rpad('D', 4000, 'D') ||
      rpad('e', 4000, 'e') || 
      rpad('E', 4000, 'E') || '.');
    rollback;
  end;

  procedure b
  is
  begin
    b_2;
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
    p_log_seq           in integer  := 1,
    p_log_date          in date     := sysdate, 
    p_log_user          in varchar2 := user, 
    p_log_id            in integer  := get_current_log_id,
    p_log_level         in integer  := 3
  )
  is
    l_dummy integer;
    
  begin

    select null into l_dummy
      from logger_feedback_data
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
       and (module_call_level = p_module_call_level or (module_call_level is null and p_module_call_level is null));
  
  end;
  
begin
  execute immediate 'truncate table logger_feedback_data';
  
  declare
    l_dummy integer;
  begin
    select logger_data_log_id.nextval into l_dummy from dual;
  end;
  
  logger.set_feedback_level(0);
  
  a(1);
  assert_row_exists(
    'a1',                       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    14,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2);                         -- p_module_call_level 
  
  a(2);
  assert_row_exists(
    'a2',                       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    18,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2);                         -- p_module_call_level
    
  a(3);
  assert_row_exists(
    'a?',                       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    21,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    2);                         -- p_module_call_level
  
  b;
  assert_row_exists(
    rpad('b', 4000, 'b'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3);                         -- p_module_call_level
  
  assert_row_exists(
    rpad('B', 4000, 'B'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    2);                         -- p_log_seq
  
  assert_row_exists(
    rpad('c', 4000, 'c'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    3);                         -- p_log_seq
  
  assert_row_exists(
    rpad('C', 4000, 'C'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    4);                         -- p_log_seq
    
  assert_row_exists(
    rpad('d', 4000, 'd'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    5);                         -- p_log_seq
  
  assert_row_exists(
    rpad('D', 4000, 'D'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    6);                         -- p_log_seq
    
  assert_row_exists(
    rpad('e', 4000, 'e'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    7);                         -- p_log_seq
    
  assert_row_exists(
    rpad('E', 4000, 'E'),       -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    8);                         -- p_log_seq
    
  assert_row_exists(
    '.',                        -- p_log_data
    null,                       -- p_module_owner
    null,                       -- p_module_name  
    30,                         -- p_module_line 
    'anonymous block',          -- p_module_type 
    3,                          -- p_module_call_level
    9);                         -- p_log_seq
  
end;
