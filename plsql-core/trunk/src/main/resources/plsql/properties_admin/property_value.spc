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

CREATE OR REPLACE PACKAGE property_value
IS
  
  /*opb-package
    field
      name=row_id
      id=Y;
    
    field
      name=value_contains_cr
      datatype=BOOLEAN
      read_only=Y;
    
    field
      name=group_name;

    field
      name=key;
    
    field
      name=property_description;
    
    field
      name=sort_order;
      
    field
      name=value;

  */

  /*opb
    param
      name=p_row_id
      field=row_id;

    param
      name=p_old_group_name
      field=group_name_data_source_value;

    param
      name=p_old_key
      field=key_data_source_value;

    param
      name=p_old_property_description
      field=property_description_data_source_value;

    param
      name=p_old_sort_order
      field=sort_order_data_source_value;

    param
      name=p_old_value
      field=value_data_source_value;

    clear_cached
      name=this;
  */
  FUNCTION del(
    p_row_id IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_key IN VARCHAR2,
    p_old_property_description IN VARCHAR2,
    p_old_sort_order IN VARCHAR2,
    p_old_value IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*opb
    param
      name=p_group_name
      field=group_name;

    param
      name=p_key
      field=key;

    param
      name=p_property_description
      field=property_description;
    
    param
      name=p_sort_order
      field=sort_order;

    param
      name=p_value
      field=value;

    invalidate_cached
      name=this;
  */
  FUNCTION ins(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_property_description IN VARCHAR2,
    p_sort_order IN VARCHAR2,
    p_value IN VARCHAR2
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
      name=p_old_key
      field=key_data_source_value;

    param
      name=p_key
      field=key;

    param
      name=p_old_property_description
      field=property_description_data_source_value;

    param
      name=p_property_description
      field=property_description;

    param
      name=p_old_sort_order
      field=sort_order_data_source_value;

    param
      name=p_sort_order
      field=sort_order;

    param
      name=p_old_value
      field=value_data_source_value;

    param
      name=p_value
      field=value;

    invalidate_cached
      name=this;
  */
  FUNCTION upd(
    p_row_id IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_key IN VARCHAR2,
    p_key IN VARCHAR2,
    p_old_property_description IN VARCHAR2,
    p_property_description IN VARCHAR2,
    p_old_sort_order IN VARCHAR2,
    p_sort_order IN VARCHAR2,
    p_old_value IN VARCHAR2,
    p_value IN VARCHAR2
  )
  RETURN VARCHAR2;
  
END property_value;
/
