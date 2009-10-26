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

CREATE OR REPLACE PACKAGE BODY value_groups
AS
  

  FUNCTION get_filtered(
    p_description IN VARCHAR2,
    p_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;

  BEGIN
    logger.ms('get_filtered');

    OPEN l_result FOR 
    SELECT *
    FROM   value_groups_data a
    WHERE  (UPPER(description) LIKE '%' || UPPER(p_description) || '%' OR (description IS NULL AND p_description IS NULL)) AND
           (UPPER(group_name) LIKE '%' || UPPER(p_group_name) || '%' OR (group_name IS NULL AND p_group_name IS NULL))
    ORDER BY group_name;

    RETURN l_result;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to get filtered value group');
      
      RAISE;

  END get_filtered;

END value_groups;
/
