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

CREATE OR REPLACE PACKAGE permission
IS
  
  /*opb-package
    field
      name=parent_permission_id
      datatype=INTEGER
      id=Y;
      
    field
      name=permission_id
      datatype=INTEGER  
      id=Y;
    
    field
      name=permission_name
      datatype=VARCHAR2;
  
    field
      name=permission_description
      datatype=VARCHAR2;

    field
      name=parent_permission_name
      datatype=VARCHAR2;
  */
  
  /*
    Note: We need the 2 part ID (parent_permission_id and permission_id)
    when we call deny.
  */
  
  /*
    Deletes a Permission by primary key.
    Any use of this permission will also be removed.
  */
  /*opb
    param
      name=p_permission_id
      field=permission_id;
  
    param
      name=p_old_permission_name
      field=permission_name_data_source_value;
  
    param
      name=p_old_permission_description
      field=permission_description_data_source_value;
  
    clear_cached
      name=this;
  */
  PROCEDURE del(
    p_permission_id IN INTEGER,
    p_old_permission_name IN VARCHAR2,
    p_old_permission_description IN VARCHAR2);
  
  
  /*
    Creates a Permission returning it's new primary key value.
  */
  /*opb
    param
      name=p_permission_id
      field=permission_id;
  
    param
      name=p_permission_name
      field=permission_name;
  
    param
      name=p_permission_description
      field=permission_description;
  
    invalidate_cached
      name=this;
  */
  PROCEDURE ins(
    p_permission_id OUT INTEGER,
    p_permission_name IN VARCHAR2,
    p_permission_description IN VARCHAR2);
  
  
  /*
    Updates a Permission by primary key.
  */
  /*opb
    param
      name=p_permission_id
      field=permission_id;
  
    param
      name=p_permission_name
      field=permission_name;
  
    param
      name=p_permission_description
      field=permission_description;
  
    param
      name=p_old_permission_name
      field=permission_name_data_source_value;
  
    param
      name=p_old_permission_description
      field=permission_description_data_source_value;
  
    invalidate_cached
      name=permission;
  */
  PROCEDURE upd(
    p_permission_id IN INTEGER,
    p_permission_name IN VARCHAR2,
    p_permission_description IN VARCHAR2,
    p_old_permission_name IN VARCHAR2,
    p_old_permission_description IN VARCHAR2);
  
  
  /*
    Returns all Permissions directly allowed to the specified permission.
    
    Parameters:
      p_permission_id
        ID of the permission who's permission should be returned.
        This is used to find which permissions are allowed.
        
      p_permission_name
        Name of the permission who's permission should be returned.
        This is returned as the parent_permission_name for all rows returned.
  */
  /*opb
    param
      name=p_permission_id
      field=permission_id;
      
    param
      name=p_permission_name
      field=permission_name;
      
    param
      name=RETURN
      datatype=CURSOR?permission;
  
  */
  FUNCTION get_permissions(
    p_permission_id IN INTEGER,
    p_permission_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  
  /*
    Allows p_permission_allowed_id to p_permission_id.
  */
  /*opb
    invalidate_cached
      name=this;
  */
  PROCEDURE allow(
    p_permission_id IN INTEGER,
    p_permission_allowed_id IN INTEGER);
  
  
  /*
    Denies p_permission_allowed_id from p_permission_id.
  */
  /*opb
    param
      name=p_permission_id
      field=parent_permission_id;
      
    param
      name=p_permission_denied_id
      field=permission_id;
      
    invalidate_cached
      name=this;
  */
  PROCEDURE deny(
    p_permission_id IN INTEGER,
    p_permission_denied_id IN INTEGER);


  /*
    Returns the description of the specified permission.

    Parameters:
      p_permission_name
        A permission name.
        If this is not a valid name, this function will return
        p_permission_name with ' (unknown permission)' appended.
  */
  FUNCTION get_permission_description(
    p_permission_name IN VARCHAR2
  )
  RETURN VARCHAR2;


END permission;
/