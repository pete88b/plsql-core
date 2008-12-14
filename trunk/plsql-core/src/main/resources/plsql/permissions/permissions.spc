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
