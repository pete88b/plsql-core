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
