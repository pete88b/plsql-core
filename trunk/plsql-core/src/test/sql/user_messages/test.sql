/*
  test case for the default user_messages implementation (user_messages.bdy).
*/
declare
  l_cursor sys_refcursor;
  l_message_id INTEGER;
  l_message_level VARCHAR2(32767);
  l_message_detail VARCHAR2(32767);

  l_null_arg varchar2(1);

  type user_message_table_type is table of user_message_temp%rowtype index by binary_integer;
  l_expected user_message_table_type;

  l_row_num integer := 0;
 
  procedure assert_equals(
    p_message_level integer,
    p_message_detail varchar2
  )
  is
  begin
    if (nvl(l_expected(l_row_num).message_level, -1) != nvl(p_message_level, -1))
    then
      raise_application_error(-20000, 
        'row ' || l_row_num || ': expected level ' || l_expected(l_row_num).message_level ||
        ' found ' || p_message_level);

    end if;

    if (nvl(l_expected(l_row_num).message_detail, '~x~') != nvl(p_message_detail, '~x~'))
    then
      dbms_output.put_line('row ' || l_row_num || ': expected detail does not match actual');
      dbms_output.put_line(l_expected(l_row_num).message_detail);
      dbms_output.put_line(p_message_detail);

      raise_application_error(-20000, 
        'row ' || l_row_num || ': expected detail "' || l_expected(l_row_num).message_detail ||
        '" found "' || p_message_detail || '"');

    end if;

  end;

begin
  -- clear old messages if there are any
  user_messages.clear_messages;

  -- set-up expected results
  l_expected(1).message_level := 6;
  l_expected(1).message_detail := '1st message (level 6)';
  l_expected(2).message_level := 3;
  l_expected(2).message_detail := 'debug';
  l_expected(3).message_level := 200;
  l_expected(3).message_detail := 'info';
  l_expected(4).message_level := 500;
  l_expected(4).message_detail := 'warn';
  l_expected(5).message_level := 6000;
  l_expected(5).message_detail := 'error';
  l_expected(6).message_level := 8080;
  l_expected(6).message_detail := 'test message 1st arg. date=21-Jan-2020 13:20:55 and then "3"';
  l_expected(7).message_level := null;
  l_expected(7).message_detail := null;
  l_expected(8).message_level := null;
  l_expected(8).message_detail := null;
  l_expected(9).message_level := null;
  l_expected(9).message_detail := 'test message';
  l_expected(10).message_level := null;
  l_expected(10).message_detail := 'test message';
  l_expected(11).message_level := null;
  l_expected(11).message_detail := 'test message {2}';
  l_expected(12).message_level := 200;
  l_expected(12).message_detail := 'test messageTRUE FALSE';
  l_expected(13).message_level := 200;
  l_expected(13).message_detail := 'test messageTRUE';
  l_expected(14).message_level := 200;
  l_expected(14).message_detail := 'TRUE-FALSE-TRUE';

  -- simple message with no arguments
  user_messages.add_message(6, '1st message (level 6)');
  -- test debug, info, warn and error
  user_messages.add_debug_message('debug');
  user_messages.add_info_message('info');
  user_messages.add_warn_message('warn');
  user_messages.add_error_message('error');
  -- test with some arguments (note: we can pass numbers and oracle will do implicit conversion to varchar2)
  user_messages.add_message(8080, 'test message {1}. date={2} and then "{3}"',
    user_messages.add_argument(1, '1st arg',
    user_messages.add_argument(2, to_date('21-jan-2020 13:20:55', 'dd-Mon-yyyy hh24:mi:ss'),
    user_messages.add_argument(3, 3))));
  -- test with null values for level and message (these are both allowed to be null)
  user_messages.add_message(null, null);
  -- 8) null message passing in an argument (it should not error)
  user_messages.add_message(null, null,
    user_messages.add_argument(1, '1st arg'));
  -- 9) not null message passing in an argument (there's no {1} placeholder but it should not error)
  user_messages.add_message(null, 'test message',
    user_messages.add_argument(1, l_null_arg));
  -- 10) test passing null argument
  user_messages.add_message(null, 'test message{1}',
    user_messages.add_argument(1, l_null_arg));
  -- 11) test passing less arguments than placeholders (so {2} placeholder will appear in the message)
  user_messages.add_message(null, 'test message{1} {2}', 
    user_messages.add_argument(1, l_null_arg));
  -- 12) test passing boolean arguments
  user_messages.add_info_message('test message{1} {2}', 
    user_messages.add_argument(1, true,
    user_messages.add_argument(2, false)));
  -- 13) set same argument twice and the arg added latest wins (so true overrides false in this case)
  user_messages.add_info_message('test message{1}', 
    user_messages.add_argument(1, true,
    user_messages.add_argument(1, false)));
  -- 14) use same placeholder twice in the message
  user_messages.add_info_message('{1}-{2}-{1}', 
    user_messages.add_argument(1, true,
    user_messages.add_argument(2, false)));

  -- get the messages, loop through them and assert that each row has the expected values
  l_cursor := user_messages.get_messages;

  loop
    fetch l_cursor into l_message_id, l_message_level, l_message_detail;
    exit when l_cursor%notfound;

    l_row_num := l_row_num + 1;
    
    assert_equals(l_message_level, l_message_detail);
    
  end loop;

  close l_cursor;

end;
/
