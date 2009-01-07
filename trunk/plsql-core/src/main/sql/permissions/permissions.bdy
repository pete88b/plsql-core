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
  
  /*
    Returns all Permissions that meet the search criteria
    (it is expected that this function will be used when this package
    is being used as the root node in a tree of permissions).
  */
  FUNCTION get_permissions(
    p_list_permissions_with_parent IN VARCHAR2,
    p_permission_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
  
  BEGIN
    logger.entering('get_permissions');
    
    logger.fb(
      'p_list_permissions_with_parent=' || p_list_permissions_with_parent ||
      ', p_permission_name=' || p_permission_name);
    
    IF (p_list_permissions_with_parent = 'Y')
    THEN
      OPEN l_result FOR
      SELECT
        NULL AS parent_permission_id,
        NULL AS parent_permission_name,
        permission_data.*
      FROM
        permission_data
      WHERE
        UPPER(permission_name) LIKE UPPER('%' || p_permission_name || '%')
      ORDER BY 
        REPLACE(permission_name, '/', 'zz');
        
    ELSE
      OPEN l_result FOR
      SELECT
        NULL AS parent_permission_id,
        NULL AS parent_permission_name,
        permission_data.*
      FROM
        permission_data
      WHERE 
        UPPER(permission_name) LIKE UPPER('%' || p_permission_name || '%')
      AND NOT EXISTS (
        SELECT NULL
          FROM permission_set_data
         WHERE permission_data.permission_id = permission_set_data.permission_allowed_id)
      ORDER BY 
        REPLACE(permission_name, '/', 'zz');
        
    END IF;
    
    RETURN l_result;
    
  END get_permissions;
  

  /*
    Returns all Permissions that meet the search criteria.
  */
  FUNCTION get_filtered(
    p_permission_name IN VARCHAR2,
    p_permission_description IN VARCHAR2  
  )
  RETURN SYS_REFCURSOR  
  IS
    l_result SYS_REFCURSOR;
  
  BEGIN
    logger.entering('get_filtered');
  
    logger.fb(
      'p_permission_name=' || p_permission_name || 
      ', p_permission_description=' || p_permission_description);
  
    OPEN l_result FOR
    SELECT
      NULL AS parent_permission_id,
      NULL AS parent_permission_name,
      permission_data.*
    FROM
      permission_data
    WHERE (
      UPPER(permission_name) LIKE '%' || UPPER(p_permission_name) || '%'
      OR permission_name IS NULL AND p_permission_name IS NULL)  
    AND (
      UPPER(permission_description) LIKE '%' || UPPER(p_permission_description) || '%'
      OR permission_description IS NULL AND p_permission_description IS NULL)
    ORDER BY 
      REPLACE(permission_name, '/', 'zz');
  
    RETURN l_result;
  
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('get_filtered failed');
      RAISE;
  
  END get_filtered;
  
  
  /*
    Returns the ID of the spcified permission.
    
    Parameters:
      p_permission_name
        A permission name.
        If this is not a valid permission name, NO_DATA_FOUND will be raised.
  */
  FUNCTION get_permission_id(
    p_permission_name IN VARCHAR2
  )
  RETURN INTEGER
  IS
    l_result INTEGER;
    
  BEGIN
    logger.entering('get_permission_id');
    
    logger.fb(
      'p_permission_name=' || p_permission_name);
      
    SELECT permission_id
      INTO l_result
      FROM permission_data
     WHERE permission_name = p_permission_name;
    
    RETURN l_result;
    
  END get_permission_id;
  
  
  /*
    Returns 'Y' if p_permission_id is allowed p_required_permission_id,
    'N' otherwise.
  */
  FUNCTION is_allowed(
    p_permission_id IN INTEGER,
    p_required_permission_id IN INTEGER
  )
  RETURN VARCHAR2
  IS
  BEGIN
    logger.entering('is_allowed(INTEGER, INTEGER)');
    
    logger.fb(
      'p_permission_id=' || p_permission_id ||
      ', p_required_permission_id=' || p_required_permission_id);
    
    -- see if the specified permission is the same as the required permission
    IF (p_permission_id = p_required_permission_id)
    THEN
      logger.fb('permission is the same as the required permission. returning Y');
      RETURN 'Y';
        
    END IF;
    
    -- see if the specified permission is a parent of the required permission
    FOR i IN (SELECT permission_id
                FROM permission_set_data
               WHERE permission_allowed_id = p_required_permission_id)
    LOOP
      IF (is_allowed(p_permission_id, i.permission_id) = 'Y')
      THEN
        -- Note: recursive permission sets will not be allowed so the
        -- recursive call above will never end up in an infinite loop
        logger.fb('returning Y');
        RETURN 'Y';
        
      END IF;
      
    END LOOP;
    
    -- if the specified permission is not a parent of the required permission,
    -- the specified permission is not allowed the required permission
    logger.fb('returning N');
    RETURN 'N';
    
  END is_allowed;
  
  
  /*
    Returns 'Y' if p_permission_name is allowed p_required_permission_name,
    'N' otherwise.
  */
  FUNCTION is_allowed(
    p_permission_name IN VARCHAR2,
    p_required_permission_name IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_permission_id INTEGER;
    l_required_permission_id INTEGER;
    
  BEGIN
    logger.entering('is_allowed(VARCHAR2, VARCHAR2)');
    
    logger.fb(
      'p_permission_name=' || p_permission_name ||
      ', p_required_permission_name=' || p_required_permission_name);
    
    -- the _allow_anything_ permission allows anything and everything
    -- so if the specified permission is _allow_anything_ we can return Y now
    IF (p_permission_name = '_allow_anything_')
    THEN
      logger.fb('p_permission_name is _allow_anything_. returning Y');
      RETURN 'Y';
      
    END IF;
    
    <<try_get_permission_id>>
    BEGIN
      -- get the ID of the specified permission
      l_permission_id := get_permission_id(p_permission_name);
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        -- if the specified permission does not exist, return N
        logger.fb('p_permission_name does not exist. returning N');
        RETURN 'N';
        
    END try_get_permission_id;
    
    <<try_is_allowed_anything>>
    BEGIN
      -- get the ID of the _allow_anything_ permission
      l_required_permission_id := get_permission_id('_allow_anything_');
      -- see if the specified permission is allowed the _allow_anything_ permission
      IF (is_allowed(l_permission_id, l_required_permission_id) = 'Y')
      THEN
        logger.fb('p_permission_name is allowed _allow_anything_. returning Y');
        RETURN 'Y';
        
      END IF;
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        -- if the _allow_anything_ permission does not exist, nothing will
        -- have been allowed it
        logger.fb('_allow_anything_ does not exist');
        
    END try_is_allowed_anything;
    
    <<try_get_required_id>>
    BEGIN
      -- get the ID of the required permission
      l_required_permission_id := get_permission_id(p_required_permission_name);
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        -- if the required permission does not exist, return N
        logger.fb('p_required_permission_name does not exist. returning N');
        RETURN 'N';
        
    END try_get_required_id;
    
    -- see if the specified permission is allowed the required permission
    RETURN is_allowed(l_permission_id, l_required_permission_id);
    
  END is_allowed;
  
END permissions;
/