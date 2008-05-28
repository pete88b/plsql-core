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

CREATE OR REPLACE PACKAGE logger_utils
IS

  /*
    Set the logger user for this Oracle session.
    It is expected that the logger user should never be set to null but this
    procedure will not fail if p_user is null.
  */
  PROCEDURE set_user(
    p_user IN VARCHAR2);
  
  
  /*
    Returns the logger user of this Oracle session.
    This will return the value returned by the Oracle built-in function USER
    until set_user has been called.
  */
  FUNCTION get_user
  RETURN VARCHAR2;
  -- Make this function callable from SQL
  PRAGMA RESTRICT_REFERENCES(get_user, WNDS);
  
  
  /*
    Performs pre-log processing as required by the logger package 
    specification.
  */
  PROCEDURE pre_log_process;
  
  /*
    Check the logger_flags table.
    This may cause the current feedback level to be updated.
  */
  PROCEDURE check_flags;
  
END logger_utils;
/
