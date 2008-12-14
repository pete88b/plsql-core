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

CREATE OR REPLACE PACKAGE BODY permission
IS
  
  g_case_of_permission VARCHAR2(9); -- upper lower sensitive

  /*
  */
  PROCEDURE assert_is_true(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2  := NULL,
    p_rollback IN BOOLEAN := FALSE
  )
  IS
  BEGIN
    IF (p_rollback)
    THEN
      ROLLBACK;
    END IF;
    
    IF (p_condition IS NULL OR NOT p_condition)
    THEN
      RAISE_APPLICATION_ERROR(-20000, p_message);
    END IF;

  END assert_is_true;

  PROCEDURE raise_permission_not_found
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20001, 'Permission Not Found');
      
  END raise_permission_not_found;
  
  
  --xxx should this be private or public???
  FUNCTION convert_permission(
    p_permission IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
  BEGIN
    assert_is_true(
      p_permission IS NOT NULL,
      'permission must not be null');
      
    IF (g_case_of_permission = 'upper')
    THEN
      RETURN UPPER(p_permission);
      
    ELSIF (g_case_of_permission = 'lower')
    THEN
      RETURN LOWER(p_permission);
      
    ELSE
      RETURN p_permission;
      
    END IF;
    
  END convert_permission;
  
  /*
  */
  PROCEDURE create_permission(
    p_permission IN VARCHAR2,
    p_description IN VARCHAR2,
    p_status IN INTEGER := status_no_restrictions
  )
  IS
    l_permission permissions_data.permission%TYPE;
    
  BEGIN
    logger.entering('create_permission');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_description=' || p_description ||
      ', p_status=' || p_status);
    
    IF (p_permission IS NULL)
    THEN
      messages.add_message(
        messages.message_level_error,
        'permission cannot be created',
        'permission must not be null');
      RETURN;
    END IF;
    
    IF (p_status IS NULL)
    THEN
      messages.add_message(
        messages.message_level_error,
        'permission cannot be created',
        'permission status must not be null');
      RETURN;
    END IF;
    
    l_permission := convert_permission(p_permission);
      
    INSERT INTO permissions_data(
      permission, description, status)
    VALUES(
      l_permission, p_description, p_status);
      
    COMMIT;
    
    -- log the permission creation as an event
    logger.info('permission created. permission=' || l_permission);
    
    messages.add_message(
      messages.message_level_info,
      'Permission "' || l_permission || '" created', NULL);
    
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      messages.add_message(
        messages.message_level_error,
        'Permission cannot be created',
        'Permission "' || l_permission || '" already exists');
    
    -- xxx would it be better to properly validate status???
    WHEN exceptions.check_constraint_violated
    THEN
      messages.add_message(
        messages.message_level_error,
        'Permission "' || l_permission || '" cannot be created',
        'The permission status is probably invalid');
        
    WHEN OTHERS
    THEN
      logger.error('create_permission failed');
      RAISE;
    
  END create_permission;
  
  /*
  */
  PROCEDURE delete_permission(
    p_permission IN VARCHAR2
  )
  IS
    l_permission permissions_data.permission%TYPE;
    l_status INTEGER;
    
  BEGIN
    logger.entering('delete_permission');
    
    logger.fb(
      'p_permission=' || p_permission);
    
    l_status := get_permission_status(p_permission);
    
    IF (l_status IS NULL)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Permission cannot be deleted',
        'Permission "' || p_permission || '" does not exist');
      -- xxx
      RETURN;
      
    ELSIF (l_status != status_no_restrictions)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Permission "' || p_permission || '" cannot be deleted',
        'Permission status is ' || l_status);
      -- xxx
      RETURN;
      
    END IF;
    
    l_permission := convert_permission(p_permission);
      
    DELETE FROM permissions_data
     WHERE permission = l_permission;
    
    IF (SQL%ROWCOUNT = 1)
    THEN
      -- if one row was deleted, we can be totally sure the permission
      -- has been deleted. log the delete as an event
      logger.info('permission deleted. permission=' || l_permission);
    END IF;
      
    COMMIT;
    
    messages.add_message(
      messages.message_level_info,
      'Permission "' || p_permission || '" deleted', NULL);
    
  EXCEPTION
    WHEN exceptions.integrity_constraint_violated
    THEN
      messages.add_message(
        messages.message_level_error,
        'Permission cannot be deleted',
        'Permission "' || p_permission || '" is used by at least one permission set');
    
    WHEN OTHERS
    THEN
      logger.error('delete_permission failed');
      RAISE;
      
  END delete_permission;
  
  /*
  */
  FUNCTION permission_exists(
    p_permission IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_permission permissions_data.permission%TYPE;
    l_dummy INTEGER(1);
    
  BEGIN
    logger.entering('permission_exists');
    
    logger.fb(
      'p_permission=' || p_permission);
    
    l_permission := convert_permission(p_permission);
    
    SELECT NULL
      INTO l_dummy
      FROM permissions_data
     WHERE permission = l_permission;
    
    RETURN constants.yes;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      RETURN constants.no;
    
  END permission_exists;
  
  --xxx pri
  PROCEDURE assert_permission_exists(
    p_permission IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('permission_exists');
    
    logger.fb(
      'p_permission=' || p_permission);
    
    assert_is_true(
      permission_exists(p_permission) = constants.yes,
      'Permission "' || p_permission || '" Not Found');
    
  END assert_permission_exists;
  
  /*
  */
  FUNCTION get_permission_status(
    p_permission IN VARCHAR2
  )
  RETURN INTEGER
  IS
    l_permission permissions_data.permission%TYPE;
    l_result INTEGER;
    
  BEGIN
    logger.entering('get_permission_status');
    
    logger.fb(
      'p_permission=' || p_permission);
    
    l_permission := convert_permission(p_permission);
    
    SELECT status
      INTO l_result
      FROM permissions_data
     WHERE permission = l_permission;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      RETURN NULL;
    
  END get_permission_status;
  
  /*
  */
  PROCEDURE set_permission_status(
    p_permission IN VARCHAR2,
    p_status IN INTEGER
  )
  IS
    l_permission permissions_data.permission%TYPE;
    
  BEGIN
    logger.entering('set_permission_status');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_status=' || p_status);
     
    l_permission := convert_permission(p_permission);
    
    UPDATE permissions_data
       SET status = p_status
     WHERE permission = l_permission;
    
    assert_is_true(
      SQL%ROWCOUNT = 1, 'Permission "' || p_permission || '" Not Found', TRUE);
    
    COMMIT;
    
  END set_permission_status;
  
  FUNCTION get_permission_description(
    p_permission IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_permission permissions_data.permission%TYPE;
    l_result permissions_data.description%TYPE;
    
  BEGIN
    logger.entering('get_permission_description');
    
    logger.fb(
      'p_permission=' || p_permission);
    
    l_permission := convert_permission(p_permission);
    
    SELECT description
      INTO l_result
      FROM permissions_data
     WHERE permission = l_permission;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      RETURN NULL;
    
  END get_permission_description;
  
  PROCEDURE set_permission_description(
    p_permission IN VARCHAR2,
    p_permission_description IN VARCHAR2
  )
  IS
    l_permission permissions_data.permission%TYPE;
    
  BEGIN
    logger.entering('set_permission_description');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_permission_description=' || p_permission_description);
     
    l_permission := convert_permission(p_permission);
    
    UPDATE permissions_data
       SET description = p_permission_description
     WHERE permission = l_permission;
    
    assert_is_true(
      SQL%ROWCOUNT = 1, 'Permission "' || p_permission || '" Not Found', TRUE);
    
    COMMIT;
    
  END set_permission_description;
  
  FUNCTION update_permission(
    p_permission IN VARCHAR2,
    p_description IN VARCHAR2,
    p_description_old IN VARCHAR2,
    p_status IN INTEGER,
    p_status_old IN INTEGER
  )
  RETURN VARCHAR2
  IS
    l_permission permissions_data.permission%TYPE;
    l_result VARCHAR2(100);
    
  BEGIN
    logger.entering('update_permission');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_description=' || p_description ||
      ', p_description_old=' || p_description_old ||
      ', p_status=' || p_status ||
      ', p_status_old=' || p_status_old);
    
    l_permission := convert_permission(p_permission);
    
    UPDATE permissions_data
       SET description = p_description,
           status = p_status
     WHERE permission = l_permission
       AND NVL(description, '~x~') = NVL(p_description_old, '~x~')
       AND status = p_status_old
       AND (status != p_status OR
           NVL(description, '~x~') != NVL(p_description, '~x~'));
    
    IF (SQL%ROWCOUNT = 0)
    THEN
      messages.add_message(
        messages.message_level_info,
        'Permission "' || p_permission || '" not updated',
        'This could mean no changes have been made or the permission ' ||
        'was changed / deleted in the time between you loading the ' ||
        'permission and you requesting the permission update.');
      
      l_result := 'invalid';
      
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Permission "' || l_permission || '" updated', NULL);
        
      l_result := 'success';
      
    END IF;
    
    COMMIT;
    
    RETURN l_result;
    
  END update_permission;
  
  /*
  */
  PROCEDURE allow(
    p_permission IN VARCHAR2,
    p_permission_allowed IN VARCHAR2
  )
  IS
    l_permission permission_sets_data.permission%TYPE;
    l_permission_allowed permission_sets_data.permission%TYPE;
    l_status INTEGER;
    
    l_permission_loop_found EXCEPTION;
    
    /*
      Go through all of the permissions allowed for the specified
      permission making sure that l_permission is not found
    */
    PROCEDURE permission_loop_check(
      p_check_permission_allowed IN VARCHAR2
    )
    IS
    BEGIN
      logger.fb(
        'permission_loop_check: ' ||
        'p_check_permission_allowed=' || p_check_permission_allowed);
        
      FOR i IN (SELECT permission_allowed
                  FROM permission_sets_data
                 WHERE permission = p_check_permission_allowed)
      LOOP
        IF (l_permission = i.permission_allowed)
        THEN 
          messages.add_message(
            messages.message_level_error,
            'Failed to allow "' || p_permission || '" the "' ||
            p_permission_allowed || '" permission',
            '"' || l_permission || '" can not be allowed "' || 
            l_permission_allowed || 
            '" as this would create a permission loop');
            
          RAISE l_permission_loop_found;
            
        END IF;
        
        permission_loop_check(i.permission_allowed);
        
      END LOOP;
      
    END permission_loop_check;
    
  BEGIN
    logger.entering('allow');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_permission_allowed=' || p_permission_allowed);
    
    l_status := get_permission_status(p_permission);
    
    IF (l_status >= status_no_change)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to allow "' || p_permission || '" the "' ||
        p_permission_allowed || '" permission',
        'Permission "' || p_permission || '" cannot be changed');
      RETURN;
    END IF;
    
    l_status := get_permission_status(p_permission_allowed);
    
    IF (l_status >= status_no_allow)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to allow "' || p_permission || '" the "' ||
        p_permission_allowed || '" permission',
        'Permission "' || p_permission_allowed || '" cannot be allowed');
      RETURN;
    END IF;
    
    l_permission := convert_permission(p_permission);
    l_permission_allowed := convert_permission(p_permission_allowed);
    
    INSERT INTO permission_sets_data(
      permission, permission_allowed)
    VALUES(
      l_permission, l_permission_allowed);
      
    -- Make sure this call to allow is not creating a permission loop  
    permission_loop_check(l_permission_allowed);
    
    COMMIT;
    
    logger.info(
      'permission allowed. permission=' || l_permission ||
      '. permission allowed=' || l_permission_allowed);
    
    messages.add_message(
      messages.message_level_info,
      'Permission allowed',
      '"' || l_permission || '" has been allowed "' || l_permission_allowed || '"');
      
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to allow "' || p_permission || '" the "' ||
        p_permission_allowed || '" permission',
        'Permission "' || p_permission || '" is already allowed "' || 
        p_permission_allowed || '"');
      ROLLBACK;
      
    WHEN l_permission_loop_found
    THEN
      ROLLBACK;
        
  END allow;

  /*
  */
  PROCEDURE deny(
    p_permission IN VARCHAR2,
    p_permission_denied IN VARCHAR2
  )
  IS
    l_permission permission_sets_data.permission%TYPE;
    l_permission_denied permission_sets_data.permission%TYPE;
    l_status INTEGER;
    
  BEGIN
    logger.entering('deny');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_permission_denied=' || p_permission_denied);
    
    l_status := get_permission_status(p_permission);
    
    IF (l_status >= status_no_change)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to deny "' || p_permission || '" the "' ||
        p_permission_denied || '" permission',
        'Permission "' || p_permission || '" cannot be changed');
        
    END IF;
    
    l_status := get_permission_status(p_permission_denied);
    
    IF (l_status >= status_no_deny)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to deny "' || p_permission || '" the "' ||
        p_permission_denied || '" permission',
        'Permission "' || p_permission_denied || '" cannot be denied');
        
    END IF;
    
    l_permission := convert_permission(p_permission);
    l_permission_denied := convert_permission(p_permission_denied);
    
    DELETE FROM permission_sets_data
     WHERE permission = l_permission
       AND permission_allowed = l_permission_denied;
    
    IF (SQL%ROWCOUNT = 1)
    THEN
      logger.info(
        'permission denied. permission=' || l_permission ||
        '. permission denied=' || l_permission_denied);
        
      messages.add_message(
        messages.message_level_info,
        'Permission denied',
        '"' || l_permission || '" is no longer allowed "' || l_permission_denied || '"');
        
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Failed to deny "' || l_permission || '" the "' ||
        p_permission_denied || '" permission',
        'Permission "' || l_permission || '" was not allowed "' || l_permission_denied || '"');
      
    END IF;
    
    COMMIT;
    
  END deny;
  
  /*
  */
  FUNCTION get_allowable_permissions(
    p_permission IN VARCHAR2,
    p_search_string IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    l_permission permission_sets_data.permission%TYPE;
    
  BEGIN
    logger.entering('get_allowable_permissions');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_search_string=' || p_search_string);
      
    l_permission := convert_permission(p_permission);
    
    OPEN l_result FOR
    SELECT permissions_data.*
      FROM permissions_data
     WHERE UPPER(permissions_data.permission) LIKE '%' || UPPER(p_search_string) || '%'
       AND permissions_data.permission != l_permission
       AND permissions_data.permission NOT IN 
           (SELECT permission_allowed
              FROM permission_sets_data
             WHERE permission_sets_data.permission = l_permission);
    
    RETURN l_result;
    
  END get_allowable_permissions;
  
  /*
  */
  FUNCTION is_allowed(
    p_permission IN VARCHAR2,
    p_permission_required IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_permission permission_sets_data.permission%TYPE;
    l_permission_required permission_sets_data.permission%TYPE;
    
  BEGIN
    logger.entering('is_allowed');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_permission_required=' || p_permission_required);
    
    l_permission := convert_permission(p_permission);
    l_permission_required := convert_permission(p_permission_required);
    
    IF (permission_exists(p_permission) = constants.no)
    THEN
      logger.fb('permission does not exist. returning no');
      RETURN constants.no;
    END IF;
    
    IF (permission_exists(p_permission_required) = constants.no)
    THEN
      logger.fb('permission required does not exist. returning no');
      RETURN constants.no;
    END IF;
    
    IF (l_permission = l_permission_required)
    THEN
      logger.fb('permission same as permission required. returning yes');
      RETURN constants.yes;
    END IF;
    
    FOR i IN (SELECT permission
                FROM permission_sets_data
               WHERE permission_allowed = l_permission_required)
    LOOP
      IF (l_permission = i.permission)
      THEN
        logger.fb('(a) returning yes');
        RETURN constants.yes;
        
      ELSIF (is_allowed(l_permission, i.permission) = constants.yes)
      THEN
        -- Note: recursive permission sets will not be allowed so the
        -- recursive call above will never end up in an infinite loop
        logger.fb('(b) returning yes');
        RETURN constants.yes;
        
      END IF;
      
    END LOOP;
    
    logger.fb('returning no');
    RETURN constants.no;
    
  END is_allowed;
  
  /*
  */
  FUNCTION get_permissions(
    p_permission IN VARCHAR2,
    p_search_string IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    l_permission permission_sets_data.permission%TYPE;
    
  BEGIN
    logger.entering('get_permissions');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_search_string=' || p_search_string);
      
    l_permission := convert_permission(p_permission);
      /*10g xxx
    OPEN l_result FOR
    SELECT permissions_data.*, 
           l_permission AS permission_set
    FROM   permissions_data
           FULL JOIN permission_sets_data ON (
             permissions_data.permission = permission_sets_data.permission_allowed)
    WHERE  permission_sets_data.permission = l_permission
    AND    UPPER(permission_sets_data.permission_allowed) LIKE '%' || UPPER(p_search_string) || '%';
    */
    
    OPEN l_result FOR
    SELECT permissions_data.*, 
           l_permission AS permission_set
      FROM permissions_data,
           permission_sets_data
     WHERE permissions_data.permission = permission_sets_data.permission_allowed
       AND permission_sets_data.permission = l_permission
       AND UPPER(permission_sets_data.permission_allowed) LIKE '%' || UPPER(p_search_string) || '%'
     ORDER BY REPLACE(permissions_data.permission, '/', 'zz');
    
    RETURN l_result;
    
  END get_permissions;
  
  /*
  */
  FUNCTION get_permission_sets(
    p_permission IN VARCHAR2,
    p_search_string IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    l_permission permission_sets_data.permission%TYPE;
    
  BEGIN
    logger.entering('get_permission_sets');
    
    logger.fb(
      'p_permission=' || p_permission ||
      ', p_search_string=' || p_search_string);
      
    l_permission := convert_permission(p_permission);
      
    OPEN l_result FOR
    SELECT *
      FROM permissions_data
     WHERE permission IN 
           (SELECT permission
              FROM permission_sets_data
             WHERE permission_allowed = l_permission
               AND UPPER(permission) LIKE '%' || UPPER(p_search_string) || '%')
    ORDER BY REPLACE(permissions_data.permission, '/', 'zz');
    
    RETURN l_result;
    
  END get_permission_sets;
  
  /*
  */
  FUNCTION get_permission_statuses
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('get_permission_statuses');
    
    -- TO_CHAR is used to avoid faces value conversion errors
    OPEN l_result FOR
    SELECT permission.status_no_restrictions AS value, 'No Restrictions' AS label
      FROM dual
     UNION ALL
    SELECT permission.status_no_delete, 'No Delete'
      FROM dual
     UNION ALL
    SELECT permission.status_no_change, 'No Change'
      FROM dual
     UNION ALL
    SELECT permission.status_no_allow, 'No Allow'
      FROM dual
     UNION ALL
    SELECT permission.status_no_deny, 'No Deny'
      FROM dual;
    
    RETURN l_result;
    
  END get_permission_statuses;
  
/*
*/
BEGIN
  <<try_get_case_of_permission>>
  BEGIN
    g_case_of_permission := properties.get_property('permission', 'case_of_permission');
    
    g_case_of_permission := LOWER(g_case_of_permission);
    
    assert_is_true(
      g_case_of_permission IN ('upper', 'lower', 'sensitive'),
      'Invalid value for permission#case_of_permission. ' ||
      'Expected "upper", "lower" or "sensitive" but found "' || g_case_of_permission || '"');
    
    logger.fb('got g_case_of_permission. using ' || g_case_of_permission);
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.fb('failed to set g_case_of_permission. using default of upper');
      g_case_of_permission := 'upper'; --xxx
      
  END try_get_case_of_permission;
  
END permission;
/
