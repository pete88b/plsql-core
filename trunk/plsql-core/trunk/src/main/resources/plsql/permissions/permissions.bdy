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

CREATE OR REPLACE PACKAGE BODY permissions 
IS

  FUNCTION get_permissions(
    p_permission_search_string IN VARCHAR2,
    p_description_search_string IN VARCHAR2,
    p_status_search_value IN INTEGER
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('get_permissions');
    
    IF (p_permission_search_string = '_upper_case_or_not_used_')
    THEN
      OPEN l_result FOR
      SELECT *
        FROM permissions_data
       WHERE permission = UPPER(permission)
          OR NOT EXISTS 
             (SELECT NULL
                FROM permission_sets_data
               WHERE permissions_data.permission = permission_sets_data.permission_allowed)
       ORDER BY REPLACE(permission, '/', 'zz');
        
    ELSE
      OPEN l_result FOR
      SELECT *
        FROM permissions_data
       WHERE UPPER(permission) LIKE '%' || UPPER(p_permission_search_string) || '%'
         AND ((p_description_search_string IS NULL AND description IS NULL) OR
             UPPER(description) LIKE '%' || UPPER(p_description_search_string) || '%')
         AND (p_status_search_value IS NULL OR
             status = p_status_search_value)
       ORDER BY REPLACE(permission, '/', 'zz');
       
    END IF;
    
    RETURN l_result;
    
  END get_permissions;
  
  /*
  */
  FUNCTION get_permission_sets(
    p_permission_search_string IN VARCHAR2,
    p_description_search_string IN VARCHAR2,
    p_status_search_value IN INTEGER
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('get_permission_sets');
    
    OPEN l_result FOR
    SELECT *
      FROM permissions_data
     WHERE permission IN 
           (SELECT permission_allowed
              FROM permission_sets_data
             WHERE UPPER(permission_allowed) LIKE '%' || UPPER(p_permission_search_string) || '%')
       AND ((p_description_search_string IS NULL AND description IS NULL) OR
           UPPER(description) LIKE '%' || UPPER(p_description_search_string) || '%')
       AND (p_status_search_value IS NULL OR
           status = p_status_search_value)
     ORDER BY REPLACE(permission, '/', 'zz');
    
    RETURN l_result;
    
  END get_permission_sets;
  
END permissions;
/
