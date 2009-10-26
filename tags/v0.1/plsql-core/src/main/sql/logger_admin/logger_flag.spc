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
