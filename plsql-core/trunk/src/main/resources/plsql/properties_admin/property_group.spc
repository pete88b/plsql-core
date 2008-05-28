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

CREATE OR REPLACE PACKAGE property_group
IS
  /*
  Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  /*opb-package
    field
      name=row_id
      id=Y
      read_only=Y;
      
    field
      name=group_name;
      
    field
      name=single_value_per_key;
    
    field
      name=locked;
    
    field
      name=group_description;
    
    field
      name=force_delete
      datatype=BOOLEAN
      in_load=ignored;
    
  */
  
  /*opb
    param
      name=p_group_name
      field=group_name;
    
    param
      name=p_single_value_per_key
      field=single_value_per_key;
    
    param
      name=p_group_description
      field=group_description;
    
    invalidate_cached
      name=this;
      
    invalidate_cached
      name=property_value;
    
  */
  FUNCTION ins(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_group_description IN VARCHAR2 := NULL
  )
  RETURN VARCHAR2;
  
  /*opb
    param
      name=p_row_id
      field=row_id;
    
    param
      name=p_force
      datatype=BOOLEAN
      field=force_delete;
    
    param
      name=p_old_group_name
      field=group_name_data_source_value;
      
    param
      name=p_old_single_value_per_key
      field=single_value_per_key_data_source_value;
    
    param
      name=p_old_locked
      field=locked_data_source_value;
    
    param
      name=p_old_group_description
      field=group_description_data_source_value;
    
    clear_cached
      name=this;
      
    clear_cached
      name=property_value;
    
  */
  FUNCTION del(
    p_row_id IN VARCHAR2,
    p_force IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_single_value_per_key IN VARCHAR2,
    p_old_locked IN VARCHAR2,
    p_old_group_description IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*opb
    param
      name=p_row_id
      field=row_id;
    
    param
      name=p_old_group_name
      field=group_name_data_source_value;
      
    param
      name=p_old_single_value_per_key
      field=single_value_per_key_data_source_value;
      
    param
      name=p_single_value_per_key
      field=single_value_per_key;
    
    param
      name=p_old_locked
      field=locked_data_source_value;
    
    param
      name=p_locked
      field=locked;
      
    param
      name=p_old_group_description
      field=group_description_data_source_value;
    
    param
      name=p_group_description
      field=group_description;
    
    invalidate_cached
      name=this;
      
    invalidate_cached
      name=property_value;
    
  */
  FUNCTION upd(
    p_row_id IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_single_value_per_key IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_old_locked IN VARCHAR2,
    p_locked IN VARCHAR2,
    p_old_group_description IN VARCHAR2,
    p_group_description IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*opb
    param
      name=p_old_group_name
      field=group_name_data_source_value;
      
    param
      name=RETURN
      datatype=cursor?property_value;
  */
  FUNCTION get_property_values(
    p_old_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
END property_group;
/
