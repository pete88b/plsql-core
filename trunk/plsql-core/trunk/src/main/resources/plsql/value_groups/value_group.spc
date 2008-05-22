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
