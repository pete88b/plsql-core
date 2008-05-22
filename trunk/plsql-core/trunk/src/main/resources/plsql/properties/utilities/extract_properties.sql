declare
  procedure p(
    s in varchar2,
    n in integer := 0
  )
  is
  begin
    dbms_output.put_line(rpad(' ', n) || s);
  end;
 
begin
  dbms_output.enable(1000000);
  
  p('declare');
  p('l_drop_existing_groups boolean := true;', 2);
  p('');
  p('procedure create_group(', 2);
  p('p_name in varchar2,', 4);
  p('p_y_or_n in varchar2,', 4);
  p('p_description in varchar2', 4);
  p(')', 2);
  p('is', 2);
  p('begin', 2);
  p('if (l_drop_existing_groups and', 4);
  p('properties.group_exists(p_name) = properties.yes_c)', 8);
  p('then', 4);
  p('properties.remove_property_group(p_name);', 6);
  p('end if;', 4);
  p('');
  p('properties.create_property_group(p_name, p_y_or_n, p_description);', 4);
  p('');
  p('end create_group;', 2);
  p('');
  p('begin');
  
  for groups_cur in (select * 
                       from properties_groups
                      order by group_name)
  loop
    p('create_group(''' || 
      groups_cur.group_name || ''', ''' ||
      groups_cur.single_value_per_key || ''', ''' ||
      groups_cur.group_description || ''');',
      2);
    
    for properties_cur in (select *
                             from properties_data
                            where group_name = groups_cur.group_name
                            order by key)
    loop
      p('properties.set_property(''' || 
        groups_cur.group_name || ''', ''' ||
        properties_cur.key || ''', ''' ||
        properties_cur.value || ''', ''' ||
        properties_cur.property_description || ''');', 
        2);
        
    end loop;
      
    p('');
    
  end loop;
  
  p('end;');
end;

