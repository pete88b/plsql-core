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
CREATE OR REPLACE PACKAGE direct_access 
IS

  /*opb-package
    field
      name=sql_text
      in_load=ignored;
  */
  
  
  /*
    Runs the specified SQL text as a query and returns the result as a cursor.
  */
  /*opb
    param
      name=p_sql_text
      field=sql_text;
      
    param
      name=RETURN
      use_result_cache=N;
  */
  FUNCTION run_sql_text_as_query(
    p_sql_text IN VARCHAR2
  )
  RETURN SYS_REFCURSOR;
  
  
  /*
    Runs the specified SQL text and then issues a ROLLBACK -
    As this procedure may be accessed from a pooled connection, 
    it is not safe for calls to this procudure to leave active transactions.
  */
  /*opb
    param
      name=p_sql_text
      field=sql_text;
  */
  PROCEDURE run_sql_text(
    p_sql_text IN VARCHAR2
  );
  
END direct_access;
/
