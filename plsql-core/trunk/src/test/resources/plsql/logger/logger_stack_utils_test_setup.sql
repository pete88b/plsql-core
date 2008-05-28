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
  create objects for logger_stack_utils testing
*/
create or replace function lsu_function 
return logger_stack_utils.who_record_type
is
  l_result logger_stack_utils.who_record_type;
begin
  logger_stack_utils.who_am_i(l_result);
  return l_result;
end lsu_function;
/

create or replace function lsu_function2
return logger_stack_utils.who_record_type
is
  l_result logger_stack_utils.who_record_type;
begin
  logger_stack_utils.who_called_me(l_result);
  return l_result;
end lsu_function2;
/

create or replace procedure lsu_procedure(
  p_who_record out logger_stack_utils.who_record_type)
is begin
  logger_stack_utils.who_am_i(p_who_record);
end lsu_procedure;
/

create or replace procedure lsu_procedure2(
  p_who_record out logger_stack_utils.who_record_type)
is 
  function a
  return logger_stack_utils.who_record_type
  is
    l_result logger_stack_utils.who_record_type;
  begin
    logger_stack_utils.who_called_my_caller(l_result);
    return l_result;
  end;
begin
  p_who_record := a;
end lsu_procedure2;
/

create or replace trigger lsu_trigger 
before insert on logger_flags for each row
declare
  l_who_record logger_stack_utils.who_record_type;
begin
  logger_stack_utils.who_am_i(l_who_record);
  dbms_output.put_line(
      'owner=' || l_who_record.owner ||
      ', name=' || l_who_record.name ||
      ', line=' || l_who_record.line ||
      ', type=' || l_who_record.type ||
      ', level=' || l_who_record.level);
      
  logger_stack_utils.who_called_me(l_who_record);
  dbms_output.put_line(
      'owner=' || l_who_record.owner ||
      ', name=' || l_who_record.name ||
      ', line=' || l_who_record.line ||
      ', type=' || l_who_record.type ||
      ', level=' || l_who_record.level);
      
end lsu_trigger;
/

create or replace package lsu_package
is
  function a
  return logger_stack_utils.who_record_type;
  
  procedure b(
    p_who_record out logger_stack_utils.who_record_type);
  
  procedure c(
    p_who_record out logger_stack_utils.who_record_type);
    
end;
/

create or replace package body lsu_package
is
  function a
  return logger_stack_utils.who_record_type
  is
    l_result logger_stack_utils.who_record_type;
  begin
    logger_stack_utils.who_am_i(l_result);
    return l_result;
  end;
  
  procedure b(
    p_who_record out logger_stack_utils.who_record_type
  )
  is
  begin
    logger_stack_utils.who_am_i(p_who_record);
  end;
  
  procedure c(
    p_who_record out logger_stack_utils.who_record_type
  )
  is
  begin
    b(p_who_record);
  end;
  
end;
/

create or replace package logger_test2.lsu_package
is
  function a
  return logger_test.logger_stack_utils.who_record_type;
  
  procedure b(
    p_who_record out logger_test.logger_stack_utils.who_record_type);
  
  procedure c(
    p_who_record out logger_test.logger_stack_utils.who_record_type);
    
end;
/

create or replace package body logger_test2.lsu_package
is
  function a
  return logger_test.logger_stack_utils.who_record_type
  is
    l_result logger_test.logger_stack_utils.who_record_type;
  begin
    logger_test.logger_stack_utils.who_am_i(l_result);
    return l_result;
  end;
  
  procedure b(
    p_who_record out logger_test.logger_stack_utils.who_record_type
  )
  is
  begin
    logger_test.logger_stack_utils.who_am_i(p_who_record);
  end;
  
  procedure c(
    p_who_record out logger_test.logger_stack_utils.who_record_type
  )
  is
  begin
    b(p_who_record);
  end;
  
end;
/
