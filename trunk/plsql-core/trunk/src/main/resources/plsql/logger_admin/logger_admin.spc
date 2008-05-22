CREATE OR REPLACE PACKAGE logger_admin
IS
  /*opb-package
    field
      name=log_level
      datatype=NUMBER;

    field
      name=log_user
      datatype=VARCHAR2;
    
    field
      name=last_n_minutes
      datatype=NUMBER;
      
    field
      name=date_format;
  */

  /*
  Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;

  /*opb
    param
      name=p_log_level
      field=log_level;

    param
      name=p_log_user
      field=log_user;

    param
      name=RETURN
      datatype=cursor?logger_flag;
  */
  FUNCTION get_logger_flags(
    p_log_level IN NUMBER,
    p_log_user IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  /*opb
    param
      name=p_last_n_minutes
      field=last_n_minutes;

    param
      name=p_date_format
      field=date_format;

  */
  FUNCTION get_logged_data(
    p_last_n_minutes IN NUMBER,
    p_date_format IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
    
  /*opb
    param
      name=p_last_n_minutes
      field=last_n_minutes;

    param
      name=p_date_format
      field=date_format;

  */
  FUNCTION get_logged_errors(
    p_last_n_minutes IN NUMBER,
    p_date_format IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
END logger_admin;
/
