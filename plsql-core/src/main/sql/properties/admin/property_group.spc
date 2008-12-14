PACKAGE property_group
IS
  
  /*
    Represents a sinlge property group.
  */
  
  
  /*opb-package
    field
      name=group_id
      datatype=INTEGER 
      id=Y;
 
    field
      name=group_name
      datatype=VARCHAR2;
 
    field
      name=group_description
      datatype=VARCHAR2;
 

    field
      name=key
      datatype=VARCHAR2
      in_load=ignored;
      
    field
      name=key_description
      datatype=VARCHAR2
      in_load=ignored;
 
    field
      name=single_value_per_key
      datatype=VARCHAR2
      in_load=ignored;
 
  */
 
 
  /*
    Deletes a Property Group by primary key.
    
    Parameters:
      p_group_id 
        ID of the group to delete.
  */
  /*opb
    param
      name=p_group_id
      field=group_id;
 
    clear_cached
      name=this;
  */
  PROCEDURE del(
    p_group_id IN INTEGER);
 
 
  /*
    Creates a Property Group returning it's new primary key value.
    
    Parameters:
      p_group_id 
        ID of the group created.
        
      p_group_name
        The name of the group to create.
        
      p_group_description
        A description of the group to create.
  */
  /*opb
    param
      name=p_group_id
      field=group_id;
 
    param
      name=p_group_name
      field=group_name;
 
    param
      name=p_group_description
      field=group_description;
 
    invalidate_cached
      name=this;
  */
  PROCEDURE ins(
    p_group_id OUT INTEGER,
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2);
 
 
  /*
    Updates a Property Group by primary key.
    
    Parameters:
      p_group_id 
        ID of the group to update.
        
      p_group_name
        The new group name.
        
      p_old_group_name
        The old group name.
        
      p_group_description
        A new description for the group.
  */
  /*opb
    param
      name=p_group_id
      field=group_id;
 
    param
      name=p_group_name
      field=group_name;
 
    param
      name=p_old_group_name
      field=group_name_data_source_value;

    param
      name=p_group_description
      field=group_description;
 
    invalidate_cached
      name=this;
  */
  PROCEDURE upd(
    p_group_id IN INTEGER,
    p_group_name IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2);
 
  
  /*
    Returns all keys of the specified group.
    
    If the specified group does not exist, no keys will be returned.
    
    Parameters:
      p_group_id 
        ID of the group who's keys should be returned.
        
      p_key
        Filter parameter.
        
      p_key_description
        Filter parameter.
        
      p_single_value_per_key
        Filter parameter. 
  */
  /*opb
    param
      name=p_group_id
      field=group_id;
      
    param
      name=p_key
      field=key;
    
    param
      name=p_key_description
      field=key_description;
 
    param
      name=p_single_value_per_key
      field=single_value_per_key;
   
    param
      name=RETURN
      datatype=cursor?property_key;
  */
  FUNCTION get_keys(
    p_group_id IN INTEGER,
    p_key IN VARCHAR2,
    p_key_description IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;


END property_group;
/