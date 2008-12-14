declare
  problem EXCEPTION;
  PRAGMA EXCEPTION_INIT(problem, -20000);
  l_group_name varchar2(32767);
  l_key_name varchar2(32767);
  
begin
  
  logger.set_feedback_level(-100);

  delete from property_value_data;
  delete from property_key_data;
  delete from property_group_data;
  commit;
  
  l_group_name := 'tg_1';
  properties.create_or_update_group(l_group_name, 'test group');
  properties.create_or_update_group(l_group_name, 'Test Group');
  
  l_key_name := 'tK_1.0';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key with no values set');
  
  l_key_name := 'tK_1.1';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key');
  properties.create_or_update_key(l_group_name, l_key_name, 'Test Key');
  properties.set_value(l_group_name, l_key_name, 'test value');
  
  properties.create_or_update_key(l_group_name, l_key_name, 'Test Key', 'N');
  properties.create_or_update_key(l_group_name, l_key_name, 'Test Key', 'Y');
  
  BEGIN
    properties.add_value(l_group_name, l_key_name, 'test value');
    raise_application_error(-20999, 'A');
  EXCEPTION
    WHEN problem
    THEN
      NULL;
  END;
  
  l_group_name := 'tg_2';
  properties.create_or_update_group(l_group_name, 'test group2');
  
  l_key_name := 'tK_2.2';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key 2');
  properties.set_value(l_group_name, l_key_name, 'test value 2');
  
  l_key_name := 'tK_2.3';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key3', 'N');
  properties.add_value(l_group_name, l_key_name, 'test value 3a');
  BEGIN
    properties.set_value(l_group_name, l_key_name, 'test value 3A');
    raise_application_error(-20999, 'B');
  EXCEPTION
    WHEN problem
    THEN
      NULL;
  END;
  properties.add_value(l_group_name, l_key_name, 'test value 3b');
  BEGIN
    properties.set_value(l_group_name, l_key_name, 'test value 3BAD');
    raise_application_error(-20999, 'a');
  EXCEPTION
    WHEN problem
    THEN
      NULL;
  END;
  properties.add_value(l_group_name, l_key_name, 'test value 3c');
  properties.create_or_update_key(l_group_name, l_key_name, 'Test Key 3', 'N');
  BEGIN
    properties.set_value(l_group_name, l_key_name, 'test value 3BAD');
    raise_application_error(-20999, 'b');
  EXCEPTION
    WHEN problem
    THEN
      NULL;
  END;
  
  l_group_name := 'tg_3';
  properties.create_or_update_group(l_group_name, 'test group3');
  
  l_key_name := 'tK_3.4';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key 4', 'N');
  properties.add_value(l_group_name, l_key_name, 'test value 4a', 1);
  properties.create_or_update_key(l_group_name, l_key_name, 'test key 4', 'Y');
  properties.create_or_update_key(l_group_name, l_key_name, 'test key 4', 'N');
  properties.add_value(l_group_name, l_key_name, 'test value 4b', 2);
  properties.add_value(l_group_name, l_key_name, 'test value 4c', 3);
  BEGIN
    properties.create_or_update_key(l_group_name, l_key_name, 'test key 4', 'Y');
    raise_application_error(-20999, 'X');
  EXCEPTION
    WHEN problem
    THEN
      NULL;
  END;
  
  l_key_name := 'tK_3.5';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key 5', 'N');
  properties.add_value(l_group_name, l_key_name, 'test value 5a');
  properties.add_value(l_group_name, l_key_name, 'test value 5b');
  
  l_key_name := 'tK_3.6';
  properties.create_or_update_key(l_group_name, l_key_name, 'test key 6', 'N');
  properties.add_value(l_group_name, l_key_name, 'test value 6a');
  
  properties.create_or_update_group(l_group_name, 'TEST GROUP3');
  
  BEGIN
    properties.create_or_update_key('not a group', l_key_name, 'test key 6', 'N');
    raise_application_error(-20999, 'Y');
  EXCEPTION
    WHEN properties.group_not_found
    THEN
      NULL;
  END;
  
  -- this creates a new key and should not update the group of the existing key
  properties.create_or_update_key('tg_1', l_key_name, 'test key 6', 'N');
  -- check that a new key has been created (i.e. the key has no values)
  if ('default value' != properties.get_value('tg_1', l_key_name, 'default value'))
  then
    raise_application_error(-20999, 'Z');
  end if;
  -- check that the values of the "original" key have not been affected
  if ('test value 6a' != properties.get_value(l_group_name, l_key_name))
  then
    raise_application_error(-20999, 'Z');
  end if;


  -- test get_value(VARCHAR2, VARCHAR2)
  if ('test value' != properties.get_value('tg_1', 'tK_1.1'))
  then
    raise_application_error(-20999, 'c');
  end if;
  
  DECLARE
    l_dummy VARCHAR2(32767);
  BEGIN
    -- group not found
    l_dummy := properties.get_value('not a group', 'tK_1.1');
    raise_application_error(-20999, 'd');
  EXCEPTION
    WHEN properties.group_not_found
    THEN
      NULL;
  END;

  DECLARE
    l_dummy VARCHAR2(32767);
  BEGIN
    -- key not found
    l_dummy := properties.get_value('tg_2', 'not a key');
    raise_application_error(-20999, 'd');
  EXCEPTION
    WHEN properties.key_not_found
    THEN
      NULL;
  END;

  DECLARE
    l_dummy VARCHAR2(32767);
  BEGIN
    -- too many values
    l_dummy := properties.get_value('tg_2', 'tK_2.3');
    raise_application_error(-20999, 'e');
  EXCEPTION
    WHEN properties.too_many_values
    THEN
      NULL;
  END;

  DECLARE
    l_dummy VARCHAR2(32767);
  BEGIN
    -- key has no values
    l_dummy := properties.get_value('tg_1', 'tK_1.0');
    raise_application_error(-20999, 'f');
  EXCEPTION
    WHEN properties.value_not_found
    THEN
      NULL;
  END;


  -- group not found
  if ('default value' != properties.get_value('not a group', 'tK_1.1', 'default value'))
  then
    raise_application_error(-20999, 'g');
  end if;

  -- key not found
  if ('default value' != properties.get_value('tg_1', 'not a key', 'default value'))
  then
    raise_application_error(-20999, 'h');
  end if;

  -- key has no values
  if ('default value' != properties.get_value('tg_1', 'tK_1.0', 'default value'))
  then
    raise_application_error(-20999, 'i');
  end if;

  declare
    l_rows integer := 0;
    l_cur sys_refcursor := properties.get_values('tg_1');
    l_row properties.property_type;
    
  begin
    loop
      fetch l_cur into l_row;
      exit when l_cur%notfound;
      l_rows := l_rows + 1;
      if (l_row.key != 'tK_1.1')
      then
        raise_application_error(-20999, 'j');
      end if;
      if (l_row.value != 'test value')
      then
        raise_application_error(-20999, 'k');
      end if;
    end loop;
    
    if (l_rows != 1)
    then
      raise_application_error(-20999, 'l');
    end if;
    
    begin
      l_cur := properties.get_values('not-a-group');
      raise_application_error(-20999, 'j2');
    exception
      when properties.group_not_found
      then
        null;
    end;
    
  end;

  
  declare
    l_rows integer := 0;
    l_cur sys_refcursor := properties.get_values('tg_2');
    l_row properties.property_type;
    
  begin
    loop
      fetch l_cur into l_row;
      exit when l_cur%notfound;
      l_rows := l_rows + 1;
      if (l_row.key not like 'tK_2.%')
      then
        raise_application_error(-20999, 'm');
      end if;
    end loop;
    
    if (l_rows != 4)
    then
      raise_application_error(-20999, 'n');
    end if;
    
  end;


  declare
    l_rows integer := 0;
    l_cur sys_refcursor := properties.get_values('tg_1', 'tK_1.1');
    l_row properties.property_type;
    
  begin
    loop
      fetch l_cur into l_row;
      exit when l_cur%notfound;
      l_rows := l_rows + 1;
      if (l_row.key != 'tK_1.1')
      then
        raise_application_error(-20999, 'o');
      end if;
      if (l_row.value != 'test value')
      then
        raise_application_error(-20999, 'p');
      end if;
    end loop;
    
    if (l_rows != 1)
    then
      raise_application_error(-20999, 'q');
    end if;
    
    begin
      l_cur := properties.get_values('not-a-group', 'not-a-key');
      raise_application_error(-20999, 'o2');
    exception
      when properties.group_not_found
      then
        null;
    end;
    
    begin
      l_cur := properties.get_values('tg_1', 'not-a-key');
      raise_application_error(-20999, 'p2');
    exception
      when properties.key_not_found
      then
        null;
    end;
    
  end;


  declare
    l_rows integer := 0;
    l_cur sys_refcursor := properties.get_values('tg_3', 'tK_3.4');
    l_row properties.property_type;
    
  begin
    loop
      fetch l_cur into l_row;
      exit when l_cur%notfound;
      l_rows := l_rows + 1;
      if (l_rows = 1)
      then
        if (l_row.value != 'test value 4a')
        then
          raise_application_error(-20999, 'r');
        end if;
      end if;
      if (l_rows = 2)
      then
        if (l_row.value != 'test value 4b')
        then
          raise_application_error(-20999, 's');
        end if;
      end if;
    end loop;
    
    if (l_rows != 3)
    then
      raise_application_error(-20999, 't');
    end if;
    
  end;
  
  l_group_name := 'tg_del';
  properties.create_or_update_group(l_group_name, 'test group for delete');
  
  l_key_name := 'tK_del.0';
  properties.create_or_update_key(l_group_name, l_key_name);
  
  properties.remove_values(l_group_name, l_key_name);
  
  properties.set_value(l_group_name, l_key_name, NULL);
  
  if (properties.get_value(l_group_name, l_key_name) IS NOT NULL)
  then
    raise_application_error(-20999, 'ZX_1');
  end if;
  
  properties.remove_values(l_group_name, l_key_name);
  
  if ('default value' != properties.get_value(l_group_name, l_key_name, 'default value'))
  then
    raise_application_error(-20999, 'ZX_1');
  end if;
  
  properties.remove_key(l_group_name, l_key_name);
  
  BEGIN
    properties.set_value(l_group_name, l_key_name, 'x');
    raise_application_error(-20999, 'ZX_2');
  EXCEPTION
    WHEN properties.key_not_found
    THEN
      NULL;
  END;
  
  BEGIN
    properties.remove_key(l_group_name, l_key_name);
    raise_application_error(-20999, 'ZX_2');
  EXCEPTION
    WHEN properties.key_not_found
    THEN
      NULL;
  END;
  
  properties.remove_group(l_group_name);
  
  BEGIN
    properties.remove_group(l_group_name);
    raise_application_error(-20999, 'ZX_3');
  EXCEPTION
    WHEN properties.group_not_found
    THEN
      NULL;
  END;
end;
