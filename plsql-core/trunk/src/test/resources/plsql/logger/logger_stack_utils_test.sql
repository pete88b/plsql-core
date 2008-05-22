/*
  Tests for logger_stack_utils. 
  See also logger_stack_utils_test_setup.sql and logger_stack_utils_teardown.sql.
  See also create_test_accounts.sql.
*/

declare
  -- who record that can be used by any test call in this script
  l_who_record logger_stack_utils.who_record_type;  
  
  -- general purpose variable. holds function return values etc.
  l_dummy varchar2(32767);
  
  -- line retrieved from dbms_output
  l_dbms_output_line varchar2(32767);
  
  -- status of line retrieval from dbms_output
  l_dbms_output_status number;
  
  -- raise an exception if p_condition is not true
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
  
  -- raise an exception if the specified who record does not contain the
  -- expected values
  procedure assert(
    p_who_record in logger_stack_utils.who_record_type,
    p_expected_owner varchar2,
    p_expected_name varchar2,
    p_expected_line number,
    p_expected_type varchar2,
    p_expected_level integer,
    p_message in varchar2 := null
  )
  is
  begin
    assert(
      upper(p_expected_owner) = upper(p_who_record.owner) or (
      p_expected_owner is null and p_who_record.owner is null),
      'expected owner=' || p_expected_owner || ' found ' || 
      p_who_record.owner || '. ' || p_message);
      
    assert(
      upper(p_expected_name) = upper(p_who_record.name) or (
      p_expected_name is null and p_who_record.name is null),
      'expected name=' || p_expected_name || ' found ' || 
      p_who_record.name || '. ' || p_message);
      
    assert(
      p_expected_line = p_who_record.line or (
      p_expected_line is null and p_who_record.line is null),
      'expected line=' || p_expected_line || ' found ' || 
      p_who_record.line || '. ' || p_message);
      
    assert(
      upper(p_expected_type) = upper(p_who_record.type) or (
      p_expected_type is null and p_who_record.type is null),
      'expected type=' || p_expected_type || ' found ' || 
      p_who_record.type || '. ' || p_message);
      
    assert(
      p_expected_level = p_who_record.level or (
      p_expected_level is null and p_who_record.level is null),
      'expected level=' || p_expected_level || ' found ' || 
      p_who_record.level || '. ' || p_message);
      
  end;
  
  
  /* START of test modules*/
  
  -- test who am I from procedure in an anonymous block
  procedure a
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 86, 'anonymous block', 2);
  end;
  
  -- test who am I from function in an anonymous block
  function b
  return varchar2
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 95, 'anonymous block', 2);
    return null;
  end;
  
  -- test who am i and who called over several call depths
  -- all c procedures check the results of who am i and who called and then
  -- call the next c procedure up.
  --   i.e. c calls c2, c3 calls c3 ... up to c6
  procedure c6
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 107, 'anonymous block', 7);
    logger_stack_utils.who_called(10, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
  end;
  
  procedure c5
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 116, 'anonymous block', 6);
    logger_stack_utils.who_called(9, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    c6;
  end;
  
  procedure c4
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 126, 'anonymous block', 5);
    logger_stack_utils.who_called(logger_stack_utils.g_my_callers_callers_caller, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(8, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    c5;
  end;
  
  procedure c3
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 138, 'anonymous block', 4);
    logger_stack_utils.who_called_my_callers_caller(l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(7, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(logger_stack_utils.g_my_callers_caller, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    c4;
  end;
  
  procedure c2
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 152, 'anonymous block', 3);
    logger_stack_utils.who_called_my_caller(l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(6, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(logger_stack_utils.g_my_caller, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    c3;
  end;
  
  procedure c
  is
  begin
    logger_stack_utils.who_am_i(l_who_record);
    assert(l_who_record, null, null, 166, 'anonymous block', 2);
    logger_stack_utils.who_called_me(l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(5, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    logger_stack_utils.who_called(logger_stack_utils.g_me, l_who_record);
    assert(l_who_record, null, null, 214, 'anonymous block', 1);
    c2;
  end;
  
  /* END of test modules*/
  
begin
  logger_stack_utils.who_am_i(l_who_record);
  assert(l_who_record, null, null, 180, 'anonymous block', 1);
  
  a;
  l_dummy := b;
  
  l_who_record := lsu_function;
  assert(l_who_record, USER, 'lsu_function', 6, 'function', 2);
  
  l_who_record := lsu_function2;
  assert(l_who_record, null, null, 189, 'anonymous block', 1);
  
  lsu_procedure(l_who_record);
  assert(l_who_record, USER, 'lsu_procedure', 4, 'procedure', 2);
  
  lsu_procedure2(l_who_record);
  assert(l_who_record, null, null, 195, 'anonymous block', 1);
  
  -- this is line 198. fire the trigger on the logger_flags table
  insert into logger_flags(log_user, log_level) values ('deleteme', null);
  rollback;
  
  dbms_output.get_line(l_dbms_output_line, l_dbms_output_status);
  -- the call stack tells us that this came from line 4 but it's 6 in the source code
  -- seems like for triggers, everything upto and including declare is seen as 1 line
  assert(
    l_dbms_output_line = 'owner=logger_test, name=lsu_trigger, line=4, type=trigger, level=2',
    'lsu_trigger who am I failed. actual=' || l_dbms_output_line);
  
  dbms_output.get_line(l_dbms_output_line, l_dbms_output_status);
  assert(
    l_dbms_output_line = 'owner=, name=, line=199, type=anonymous block, level=1',
    'lsu_trigger who called me failed. actual=' || l_dbms_output_line);
  
  c;
  
  l_who_record := lsu_package.a;
  assert(l_who_record, USER, 'lsu_package', 8, 'package body', 2);
  
  lsu_package.b(l_who_record);
  assert(l_who_record, USER, 'lsu_package', 17, 'package body', 2);
  
  lsu_package.c(l_who_record);
  assert(l_who_record, USER, 'lsu_package', 17, 'package body', 3);
  
  -- test calls from object in other schemas
  l_who_record := logger_test2.lsu_package.a;
  assert(l_who_record, 'logger_test2', 'lsu_package', 8, 'package body', 2);
  
  logger_test2.lsu_package.b(l_who_record);
  assert(l_who_record, 'logger_test2', 'lsu_package', 17, 'package body', 2);
  
  logger_test2.lsu_package.c(l_who_record);
  assert(l_who_record, 'logger_test2', 'lsu_package', 17, 'package body', 3);
  
  begin
    logger_stack_utils.who_called(0, l_who_record);
    assert(false, 'who_called(0, l_who_record) should have failed');
  exception
    when others then
      if (sqlcode = -20000) then raise; end if;
      assert(sqlcode = -6502, 'x');
  end;
  
  begin
    logger_stack_utils.who_called(1, l_who_record);
    assert(false, 'who_called(1, l_who_record) should have failed');
  exception
    when others then
      if (sqlcode = -20000) then raise; end if;
      assert(sqlcode = -6502, 'x');
  end;
  
  begin
    logger_stack_utils.who_called(2, l_who_record);
    assert(false, 'who_called(2, l_who_record) should have failed');
  exception
    when others then
      if (sqlcode = -20000) then raise; end if;
      assert(sqlcode = -6502, 'x');
  end;
  
  -- we don't care what this returns but it should not fail
  logger_stack_utils.who_called(3, l_who_record);
  
  -- simple test of who am i again. not really needed but here for completeness
  logger_stack_utils.who_called(4, l_who_record);
  assert(l_who_record, null, null, 266, 'anonymous block', 1);
  
  -- request stack lines that do not exists. 
  -- i.e there are only 4 calls on the stack when we make the following who 
  -- called call
  for i in 5 .. 9
  loop
    logger_stack_utils.who_called(i, l_who_record);
    assert(l_who_record, null, null, null, null, 0);
  end loop;
    
end;
