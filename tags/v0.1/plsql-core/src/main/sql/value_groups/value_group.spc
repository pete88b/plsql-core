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

CREATE OR REPLACE PACKAGE value_group
AS

  /*opb-package
    field
      name=description;

    field
      name=group_name
      read_only=N
      id=Y;

    field
      name=values_sql;

  */

  /*
  Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;


  /*opb
    param
      name=p_old_description
      field=description_data_source_value;

    param
      name=p_old_group_name
      field=group_name;
      
    param
      name=p_old_values_sql
      field=values_sql;

    clear_cached
      name=this;
  */
  FUNCTION del(
    p_old_description IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_values_sql IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*opb
    param
      name=p_description
      field=description;

    param
      name=p_group_name
      field=group_name;

    param
      name=p_values_sql
      field=values_sql;

    invalidate_cached
      name=this;
  */
  FUNCTION ins(
    p_description IN VARCHAR2,
    p_group_name IN VARCHAR2,
    p_values_sql IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*opb
    param
      name=p_group_name
      field=group_name;

    param
      name=p_old_description
      field=description_data_source_value;

    param
      name=p_description
      field=description;
   
    param
      name=p_old_values_sql
      field=values_sql_data_source_value;

    param
      name=p_values_sql
      field=values_sql;
      
    invalidate_cached
      name=this;
      
    invalidate_cached
      name=value_group_value;
  */
  FUNCTION update_details(
    p_group_name IN VARCHAR2,
    p_old_description IN VARCHAR2,
    p_description IN VARCHAR2,
    p_old_values_sql IN VARCHAR2,
    p_values_sql IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*opb
    param
      name=p_group_name
      field=group_name;
      
    param
      name=RETURN
      datatype=cursor?value_group_value;
  */
  FUNCTION get_values(
    p_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
END value_group;
/
