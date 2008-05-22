CREATE OR REPLACE PACKAGE logger_flag
AS

  /*opb-package
    field
      name=row_id
      datatype=VARCHAR2
      id=Y;

    field
      name=log_level
      datatype=INTEGER;

    field
      name=log_user
      datatype=VARCHAR2;

  */

  /*opb
    param
      name=p_row_id
      field=row_id;

    param
      name=p_old_log_level
      field=log_level_data_source_value;

    param
      name=p_old_log_user
      field=log_user_data_source_value;

    clear_cached
      name=this;
  */
  FUNCTION del(
    p_row_id IN VARCHAR2,
    p_old_log_level IN INTEGER,
    p_old_log_user IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*opb
    param
      name=p_row_id
      field=row_id;

    param
      name=p_log_level
      field=log_level;

    param
      name=p_log_user
      field=log_user;

    invalidate_cached
      name=this;
  */
  FUNCTION ins(
    p_row_id OUT VARCHAR2,
    p_log_level IN INTEGER,
    p_log_user IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*opb
    param
      name=p_row_id
      field=row_id;

    param
      name=p_old_log_level
      field=log_level_data_source_value;

    param
      name=p_log_level
      field=log_level;

    param
      name=p_old_log_user
      field=log_user_data_source_value;

    param
      name=p_log_user
      field=log_user;

    invalidate_cached
      name=this;
  */
  FUNCTION upd(
    p_row_id IN VARCHAR2,
    p_old_log_level IN INTEGER,
    p_log_level IN INTEGER,
    p_old_log_user IN VARCHAR2,
    p_log_user IN VARCHAR2
  )
  RETURN VARCHAR2;

END logger_flag;
/
