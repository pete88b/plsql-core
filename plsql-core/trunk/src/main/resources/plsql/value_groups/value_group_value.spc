CREATE OR REPLACE PACKAGE value_group_value
AS

  /*opb-package
    field
      name=group_name
      read_only=N
      id=Y;
      
    field
      name=value
      read_only=N
      id=Y;
    
    field
      name=label;
    
    field
      name=description;
      
    field
      name=enabled
      datatype=BOOLEAN
      initial_value=TRUE;
      
    field
      name=source_group_name
      read_only=Y;
  */

  /*opb
    param
      name=p_old_group_name
      field=group_name;
      
    param
      name=p_old_value
      field=value;

    param
      name=p_old_label
      field=label_data_source_value;

    param
      name=p_old_description
      field=description_data_source_value;
    
    param
      name=p_old_enabled
      field=enabled_data_source_value
      datatype=BOOLEAN;
    
    clear_cached
      name=this;
  */
  FUNCTION del(
    p_old_group_name IN VARCHAR2,
    p_old_value IN VARCHAR2,
    p_old_label IN VARCHAR2,
    p_old_description IN VARCHAR2,
    p_old_enabled IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*opb
    param
      name=p_group_name
      field=group_name;
    
    param
      name=p_value
      field=value;
    
    param
      name=p_label
      field=label;
    
    param
      name=p_description
      field=description;

    param
      name=p_enabled
      field=enabled
      datatype=BOOLEAN;

    invalidate_cached
      name=this;
  */
  FUNCTION ins(
    p_group_name IN VARCHAR2,
    p_value IN VARCHAR2,
    p_label IN VARCHAR2,
    p_description IN VARCHAR2,
    p_enabled IN VARCHAR2
  )
  RETURN VARCHAR2;


  /*opb
    param
      name=p_old_group_name
      field=group_name;
      
    param
      name=p_old_value
      field=value;
      
    param
      name=p_old_label
      field=label_data_source_value;

    param
      name=p_label
      field=label;
      
    param
      name=p_old_description
      field=description_data_source_value;

    param
      name=p_description
      field=description;

    param
      name=p_old_enabled
      field=enabled_data_source_value
      datatype=BOOLEAN;

    param
      name=p_enabled
      field=enabled
      datatype=BOOLEAN;

    invalidate_cached
      name=this;
  */
  FUNCTION upd(
    p_old_group_name IN VARCHAR2,
    p_old_value IN VARCHAR2,
    p_old_label IN VARCHAR2,
    p_label IN VARCHAR2,
    p_old_description IN VARCHAR2,
    p_description IN VARCHAR2,
    p_old_enabled IN VARCHAR2,
    p_enabled IN VARCHAR2
  )
  RETURN VARCHAR2;

END value_group_value;
/
