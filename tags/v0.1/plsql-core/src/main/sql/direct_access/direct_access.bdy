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
CREATE OR REPLACE PACKAGE BODY direct_access 
IS

  /*
    Runs the specified SQL text as a query and returns the result as a cursor.
    
    This implementation should never fail. 
    If the SQL text fails to run, we'll feedback to the user and return a 
    dummy result set.
  */
  FUNCTION run_sql_text_as_query(
    p_sql_text IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('run_sql_text_as_query');
    
    logger.fb(
      'p_sql_text=' || p_sql_text);
    
    OPEN l_result FOR p_sql_text;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to run SQL as query', SQLERRM);
        
      OPEN l_result FOR SELECT NULL FROM dual WHERE 1 = 2;
      
      RETURN l_result;
      
  END run_sql_text_as_query;

  /*
    Runs the specified SQL text and then issues a ROLLBACK.
    If the SQL text runs without error, we'll feedback a success 
    message to the user.
    
    This implementation should never fail. 
    If the SQL text fails to run, we'll feedback to the user.
  */  
  PROCEDURE run_sql_text(
    p_sql_text IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('run_sql_text');
    
    EXECUTE IMMEDIATE p_sql_text;
    
    ROLLBACK;
    
    messages.add_message(
        messages.message_level_info,
        'Run SQL succeded', NULL);
    
  EXCEPTION
    WHEN OTHERS
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to run SQL', SQLERRM);
        
  END run_sql_text;
  
END direct_access;
/
