CREATE OR REPLACE PACKAGE permission
IS
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  /*
    This package uses the property permission#case_of_permission to determine
    how permissions should be saved and compared.
    
    If this property is set to an invalid value, an exception will be raised
    when this package is first used by an Oracle session.
    
    There are three valid values for this property;
    
      upper
        permissions will be converted to upper case before saving or comparing.
        This is the default.
        
      lower
        permissions will be converted to lower case before saving or comparing.
        
      sensitive
        no changes will be made to the case of permissions for either saving
        or comparing.
        
  */
  
  /*opb-package
    
    field
      name=permission
      id=Y;
      
    field
      name=description;
      
    field
      name=status
      datatype=INTEGER;
    
    field
      name=new_permission
      in_load=optional;
      
    field
      name=permission_allowed
      on_change=allow
      in_load=optional;
      
    field
      name=permission_denied
      on_change=deny
      in_load=optional;
      
    field
      name=permission_set
      id=Y
      in_load=optional;
    
    field
      name=permission_required
      in_load=optional;
      
    field
      name=permission_search_string
      in_load=optional;
      
    field
      name=allowable_search_string
      in_load=optional;
  */
  
  /* anything goes */
  status_no_restrictions CONSTANT INTEGER := 0;
  
  /* permission can't be deleted */
  status_no_delete CONSTANT INTEGER := 1;
  
  /* permission can't be deleted,
     no changes to what this permission is allowed to do.
       i.e. can't be used as p_permission in allow or deny call
   */
  status_no_change CONSTANT INTEGER := 2;
  
  /* permission can't be deleted,
     no changes to what this permission is allowed to do and
     no other permission will be allowed this permission.
       i.e. can't be used as p_permission_allowed in allow call
  */
  status_no_allow CONSTANT INTEGER := 3;
  
  /* permission can't be deleted,
     no changes to what this permission is allowed to do,
     no other permission will be allowed this permission and
     permission can't be removed from a permission set.
       i.e. can't be used as p_permission_denied in deny call
  */
  status_no_deny CONSTANT INTEGER := 4;
  
  /*opb
    param
      name=p_permission
      field=new_permission;
      
    param
      name=p_description
      field=description;
      
    param
      name=p_status
      field=status;
      
    clear_cached
      name=this;
  */
  PROCEDURE create_permission(
    p_permission IN VARCHAR2,
    p_description IN VARCHAR2,
    p_status IN INTEGER := status_no_restrictions
  );
  
  /*opb
    param
      name=p_permission
      field=permission;
      
    clear_cached
      name=this;
  */
  PROCEDURE delete_permission(
    p_permission IN VARCHAR2
  );
  
  FUNCTION permission_exists(
    p_permission IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  PROCEDURE assert_permission_exists(
    p_permission IN VARCHAR2
  );
  
  /*
    Returns the status of the permission or NULL if the permission
    does not exist
  */
  FUNCTION get_permission_status(
    p_permission IN VARCHAR2
  )
  RETURN INTEGER;
  
  PROCEDURE set_permission_status(
    p_permission IN VARCHAR2,
    p_status IN INTEGER
  );
  
  FUNCTION get_permission_description(
    p_permission IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  PROCEDURE set_permission_description(
    p_permission IN VARCHAR2,
    p_permission_description IN VARCHAR2
  );
  
  /*opb
    param
      name=p_permission
      field=permission;
      
    param
      name=p_description
      field=description;
      
    param
      name=p_description_old
      field=description_data_source_value;
      
    param
      name=p_status
      field=status;
      
    param
      name=p_status_old
      field=status_data_source_value;
      
    invalidate_cached
        name=this;
  */
  FUNCTION update_permission(
    p_permission IN VARCHAR2,
    p_description IN VARCHAR2,
    p_description_old IN VARCHAR2,
    p_status IN INTEGER,
    p_status_old IN INTEGER
  )
  RETURN VARCHAR2;
  
  /* xxx
    explain permission loop
    exceptions
  */
  
  /*opb
    param
      name=p_permission
      field=permission;
      
    param
      name=p_permission_allowed
      field=permission_allowed;
      
    invalidate_cached
      name=this;
  */
  PROCEDURE allow(
    p_permission IN VARCHAR2,
    p_permission_allowed IN VARCHAR2
  );
  
  /*opb
    param
      name=p_permission
      field=permission_set;
      
    param
      name=p_permission_denied
      field=permission;
      
    invalidate_cached
      name=this;
  */
  PROCEDURE deny(
    p_permission IN VARCHAR2,
    p_permission_denied IN VARCHAR2
  );
  
  /*opb
    param
      name=RETURN
      datatype=CURSOR?permission;
      
    param
      name=p_permission
      field=permission;
      
    param
      name=p_search_string
      field=allowable_search_string;
  */
  FUNCTION get_allowable_permissions(
    p_permission IN VARCHAR2,
    p_search_string IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  /*opb
    param
      name=p_permission
      field=permission;
      
    param
      name=p_permission_required
      field=permission_required;
  */
  FUNCTION is_allowed(
    p_permission IN VARCHAR2,
    p_permission_required IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*opb
    param
      name=RETURN
      datatype=CURSOR?permission;
      
    param
      name=p_permission
      field=permission;
      
    param
      name=p_search_string
      field=permission_search_string;
  */
  FUNCTION get_permissions(
    p_permission IN VARCHAR2,
    p_search_string IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  /*
    Returns the permission sets of this permission.
  */
  /*opb
    param
      name=RETURN
      datatype=CURSOR?permission;
      
    param
      name=p_permission
      field=permission;
      
    param
      name=p_search_string
      field=permission_search_string;
  */
  FUNCTION get_permission_sets(
    p_permission IN VARCHAR2,
    p_search_string IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  /*opb
    param
      name=RETURN
      datatype=CURSOR?permission_status
      use_data_object_cache=N;
  */
  FUNCTION get_permission_statuses
  RETURN SYS_REFCURSOR;
  
END permission;
/
