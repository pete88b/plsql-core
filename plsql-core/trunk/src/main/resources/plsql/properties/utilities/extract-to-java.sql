/*
  Outputs Java code that can be run to re-create current property data.

  It is assumed that the output will be copied to a Java class in a location 
  from which propertyManager (a PropertyManager instance) is accessible.
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
  
  <<groups_loop>>
  for property_groups in (select * 
                          from property_group_data
                          order by group_name)
  loop
    p('propertyManager.createOrUpdateGroup("' || 
      property_groups.group_name || '", "' || 
      property_groups.group_description || '");');
    
    p('propertyManager.removeKeys("' || 
      property_groups.group_name || '");');
      
    p;
    
    <<keys_loop>>
    for property_keys in (select key_id, key, key_description, 
                                 decode(single_value_per_key, 'Y', 'true', 'N', 'false') AS single_value_per_key
                          from property_key_data
                          where group_id = property_groups.group_id)
    loop
      
      p('propertyManager.createOrUpdateKey("' ||
        property_groups.group_name || '", "' ||
        property_keys.key || '", "' ||
        property_keys.key_description || '", ' ||
        property_keys.single_value_per_key || ');');
    
      <<values_loop>>
      for property_values in (select value,
                                     decode(sort_order, NULL, 'null', sort_order || 'L') AS sort_order
                              from property_value_data
                              where key_id = property_keys.key_id)
      loop
        if (property_keys.single_value_per_key = 'true')
        then
          p('propertyManager.setValue("' ||
            property_groups.group_name || '", "' ||
            property_keys.key || '", "' ||
            property_values.value || '");');
            
        else
          p('propertyManager.addValue("' ||
            property_groups.group_name || '", "' ||
            property_keys.key || '", "' ||
            property_values.value || '", ' ||
            property_values.sort_order || ');');
            
        end if;
        
      end loop values_loop;
      
      p;
      
    end loop keys_loop;
    
    p;
    
  end loop groups_loop;
  
end;