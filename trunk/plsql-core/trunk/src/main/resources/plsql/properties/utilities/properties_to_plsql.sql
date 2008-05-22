
declare
  procedure p(
    s in varchar2
  )
  is
  begin
    dbms_output.put_line(s);
  end;
  
begin
  dbms_output.enable(10000000);
  
  p('
declare
  l_drop_existing_groups boolean := true;
  
  procedure create_group(
    p_name in varchar2,
    p_y_or_n in varchar2,
    p_desc in varchar2
  )
  is
  begin
    if (l_drop_existing_groups and 
          properties.group_exists(p_name) = properties.yes_c)
    then
      properties.remove_property_group(p_name);
    end if;
  
    properties.create_property_group(p_name, p_y_or_n, p_desc);

  end create_group;
  
begin');
  
  for i in (select * from properties_groups)
  loop
    p('  create_group(');
    p('    ''' || i.group_name || ''', ');
    p('    ''' || i.single_value_per_key || ''', ');
    p('    ''' || i.group_description || ''');');
    
    for j in (select * from properties_data where group_name = i.group_name)
    loop
      p('  properties.set_property(');
      p('    ''' || j.group_name || ''', ');
      p('    ''' || j.key || ''', ');
      p('    ''' || j.value || ''', ');
      p('    ''' || j.property_description || ''');');
    end loop;
    
    p('');
    
  end loop;
    
p('end;');
    
end;
