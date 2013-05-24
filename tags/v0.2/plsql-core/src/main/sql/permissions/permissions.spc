/**
 * Copyright (C) 2008 Peter Butterfill.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

CREATE OR REPLACE PACKAGE permissions
IS
  
  /*opb-package
    field
      name=parent_permission_id
      datatype=INTEGER
      in_load=ignored;
      
    field
      name=permission_id
      datatype=INTEGER  
      in_load=ignored;
      
    field
      name=permission_name
      datatype=VARCHAR2
      in_load=ignored;
  
    field
      name=permission_description
      datatype=VARCHAR2
      in_load=ignored;
    
    field
      name=list_permissions_with_parent
      datatype=BOOLEAN
      in_load=ignored;
  */
  
  /*
    Returns all Permissions that meet the search criteria
    (it is expected that this function will be used when this package
    is being used as the root node in a tree of permissions).
    
    Paramters:
      p_list_permissions_with_parent
        If 'Y', the result will include permissions that have a parent.
        Otherwise, only permissions that have no parent will be returned.
        
      p_permission_name
        If NULL, all permissions are returned.
        Otherwise, only permissions that have a name like the specified
        value will be returned (comparison is case insensitive).
        
      RETURN
        A cursor containing the columns parent_permission_id and
        parent_permission_name and all columns of the permission_data table.
  */
  /*opb
    param
      name=p_list_permissions_with_parent
      field=list_permissions_with_parent
      datatype=BOOLEAN;
      
    param
      name=p_permission_name
      field=permission_name;
  
    param
      name=RETURN
      datatype=CURSOR?permission;
  
  */
  FUNCTION get_permissions(
    p_list_permissions_with_parent IN VARCHAR2,
    p_permission_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  
  /*
    Returns all Permissions that meet the search criteria.
    
    Paramters:
      p_permission_name
        If NULL, all permissions are returned.
        Otherwise, only permissions that have a name like the specified
        value will be returned (comparison is case insensitive).
        
      p_permission_description
        If NULL, all permissions are returned.
        Otherwise, only permissions that have a description like the specified
        value will be returned (comparison is case insensitive).
        
      RETURN
        A cursor containing the columns parent_permission_id and
        parent_permission_name and all columns of the permission_data table.
  */
  /*opb
    param
      name=p_permission_name
      field=permission_name;
  
    param
      name=p_permission_description
      field=permission_description;
  
    param
      name=RETURN
      datatype=CURSOR?permission;
  
  */
  FUNCTION get_filtered(
    p_permission_name IN VARCHAR2,
    p_permission_description IN VARCHAR2  
  )
  RETURN SYS_REFCURSOR;
  
  
  /*
    Returns 'Y' if p_permission_name is allowed p_required_permission_name,
    'N' otherwise.
    
    Note: 
      _allow_anything_ is a special permission name.
      If p_permission_name = '_allow_anything_' or 
      p_permission_name is allowed the _allow_anything_ permission, 
      this function will always return 'Y'.
      This is true even if p_required_permission_name is not a valid 
      permission name.
    
    Parameters:
      p_permission_name
        A permission name.
        If this is not a valid permission name, this function will return N
        (unless p_permission_name = '_allow_anything_').
        
      p_required_permission_name
        The name of the permission required.
        If this is not a valid permission name, this function will return N
        (unless p_permission_name = '_allow_anything_' or
        p_permission_name is allowed the _allow_anything_ permission).
  */
  FUNCTION is_allowed(
    p_permission_name IN VARCHAR2,
    p_required_permission_name IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  
END permissions;
/