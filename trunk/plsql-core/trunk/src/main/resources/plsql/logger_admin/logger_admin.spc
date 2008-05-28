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
