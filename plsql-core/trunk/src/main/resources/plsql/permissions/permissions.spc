CREATE OR REPLACE PACKAGE permissions 
IS
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  /*opb-package
    field
      name=permission
      in_load=optional;
    field
      name=description
      in_load=optional;
    field
      name=status
      datatype=INTEGER
      in_load=optional;
      
    field
      name=permission_search_string
      in_load=optional;
    field
      name=description_search_string
      in_load=optional;
    field
      name=status_search_value
      in_load=optional
      datatype=INTEGER;
  */
  
  
  /*opb
    param
      name=RETURN
      datatype=CURSOR?permission;
    param
      name=p_permission_search_string
      field=permission_search_string;
    param
      name=p_description_search_string
      field=description_search_string;
    param
      name=p_status_search_value
      field=status_search_value;
  */
  FUNCTION get_permissions(
    p_permission_search_string IN VARCHAR2,
    p_description_search_string IN VARCHAR2,
    p_status_search_value IN INTEGER
  )
  RETURN SYS_REFCURSOR;
  
  /*opb
    param
      name=RETURN
      datatype=CURSOR?permission;
    param
      name=p_permission_search_string
      field=permission_search_string;
    param
      name=p_description_search_string
      field=description_search_string;
    param
      name=p_status_search_value
      field=status_search_value;
  */
  FUNCTION get_permission_sets(
    p_permission_search_string IN VARCHAR2,
    p_description_search_string IN VARCHAR2,
    p_status_search_value IN INTEGER
  )
  RETURN SYS_REFCURSOR;
  
END permissions;
/
