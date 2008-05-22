CREATE OR REPLACE PACKAGE property_groups 
IS
  /*
  Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  /*opb-package
    field
      name=group_name;
      
    field
      name=single_value_per_key;
    
    field
      name=locked;
    
    field
      name=group_description;
    
  */
  
  /*opb
    param
      name=p_group_name
      field=group_name;
      
    param
      name=p_single_value_per_key
      field=single_value_per_key;
      
    param
      name=p_locked
      field=locked;
      
    param
      name=p_group_description
      field=group_description;
    
    param
      name=RETURN
      datatype=cursor?property_group;
    
  */
  FUNCTION get_property_groups(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_locked IN VARCHAR2,
    p_group_description IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
END property_groups;
/
