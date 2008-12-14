/*
  Outputs PL/SQL code that can be run to re-create current property data.

  The output (an anonymous block) can be run as is.
*/
declare
  procedure p(
    p_data in varchar2 := '  '
  )
  is
  begin
    dbms_output.put_line(p_data);
    
  end;
  
begin
  p('BEGIN');
  <<groups_loop>>
  for property_groups in (select * 
                          from property_group_data
                          order by group_name)
  loop
    p('  properties.create_or_update_group(''' || 
      property_groups.group_name || ''', ''' || 
      property_groups.group_description || ''');');
    
    p('  properties.remove_keys(''' || 
      property_groups.group_name || ''');');
      
    p;
    
    <<keys_loop>>
    for property_keys in (select *
                          from property_key_data
                          where group_id = property_groups.group_id)
    loop
      
      p('  properties.create_or_update_key(''' ||
        property_groups.group_name || ''', ''' ||
        property_keys.key || ''', ''' ||
        property_keys.key_description || ''', ''' ||
        property_keys.single_value_per_key || ''');');
    
      <<values_loop>>
      for property_values in (select *
                              from property_value_data
                              where key_id = property_keys.key_id)
      loop
        if (property_keys.single_value_per_key = 'Y')
        then
          p('  properties.set_value(''' ||
            property_groups.group_name || ''', ''' ||
            property_keys.key || ''', ''' ||
            property_values.value || ''');');
            
        else
          p('  properties.add_value(''' ||
            property_groups.group_name || ''', ''' ||
            property_keys.key || ''', ''' ||
            property_values.value || ''', ' ||
            property_values.sort_order || ');');
            
        end if;
        
      end loop values_loop;
      
      p;
      
    end loop keys_loop;
    
    p;
    
  end loop groups_loop;
  
  p('END;');
  p('/');
  
end;