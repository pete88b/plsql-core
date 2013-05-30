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

  /*
    Deletes a Permission by primary key.
  */
  PROCEDURE del(
    p_permission_id IN INTEGER,
    p_old_permission_name IN VARCHAR2,
    p_old_permission_description IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('del');

    logger.fb(
      'p_permission_id=' || p_permission_id ||
      ', p_old_permission_name=' || p_old_permission_name ||
      ', p_old_permission_description=' || p_old_permission_description);

    DELETE FROM
      permission_data
    WHERE
      permission_id = p_permission_id
    AND (
      permission_name = p_old_permission_name OR
      (permission_name IS NULL AND p_old_permission_name IS NULL))
    AND (
      permission_description = p_old_permission_description OR
      (permission_description IS NULL AND p_old_permission_description IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      user_messages.add_warn_message(
        'Permission "{1}" not deleted. ' ||
        'This data has been deleted or changed by another session',
        user_messages.add_argument(1, p_old_permission_name));

    ELSE
      user_messages.add_info_message(
        'Permission "{1}" deleted',
        user_messages.add_argument(1, p_old_permission_name));

    END IF;

    COMMIT;

  EXCEPTION
    WHEN exceptions.child_record_found
    THEN
      user_messages.add_warn_message(
        'Permission "{1}" not deleted. ' ||
        'This permission is allowed one or more permissions',
        user_messages.add_argument(1, p_old_permission_name));
      ROLLBACK;

    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('del failed');
      RAISE;

  END del;


  /*
    Creates a Permission returning it's new primary key value.
  */
  PROCEDURE ins(
    p_permission_id OUT INTEGER,
    p_permission_name IN VARCHAR2,
    p_permission_description IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('ins');

    logger.fb(
      'p_permission_name=' || p_permission_name ||
      ', p_permission_description=' || p_permission_description);

    IF (p_permission_name IS NULL)
    THEN
      user_messages.add_warn_message(
        'Permission not created. Name must be provided');
      RETURN;
    END IF;

    INSERT INTO permission_data(
      permission_name,
      permission_description)
    VALUES(
      p_permission_name,
      p_permission_description)
    RETURNING
      permission_id
    INTO
      p_permission_id;

    user_messages.add_info_message(
      'Permission "{1}" created',
      user_messages.add_argument(1, p_permission_name));

    COMMIT;

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      user_messages.add_warn_message(
        'Permission "{1}" not created. Name must be unique',
        user_messages.add_argument(1, p_permission_name));
      ROLLBACK;

    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('ins failed');
      RAISE;

  END ins;


  /*
    Updates a Permission by primary key.
  */
  PROCEDURE upd(
    p_permission_id IN INTEGER,
    p_permission_name IN VARCHAR2,
    p_permission_description IN VARCHAR2,
    p_old_permission_name IN VARCHAR2,
    p_old_permission_description IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('upd');

    logger.fb(
      'p_permission_id=' || p_permission_id ||
      ', p_permission_name=' || p_permission_name ||
      ', p_permission_description=' || p_permission_description ||
      ', p_old_permission_name=' || p_old_permission_name ||
      ', p_old_permission_description=' || p_old_permission_description);

    IF (p_permission_name IS NULL)
    THEN
      user_messages.add_warn_message(
        'Permission "{1}" not updated. Name must be provided',
        user_messages.add_argument(1, p_permission_name));
      RETURN;
    END IF;

    UPDATE
      permission_data
    SET
      permission_name = p_permission_name,
      permission_description = p_permission_description
    WHERE
      permission_id = p_permission_id
    AND (
      permission_name = p_old_permission_name OR
      (permission_name IS NULL AND p_old_permission_name IS NULL))
    AND (
      permission_description = p_old_permission_description OR
      (permission_description IS NULL AND p_old_permission_description IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      user_messages.add_warn_message(
        'Permission "{1}" not updated. ' ||
        'This data has been deleted or changed by another session',
        user_messages.add_argument(1, p_permission_name));

    ELSE
      user_messages.add_info_message(
        'Permission "{1}" updated',
        user_messages.add_argument(1, p_permission_name));

    END IF;

    COMMIT;

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      user_messages.add_warn_message(
        'Permission "{1}" not updated. Name must be unique',
        user_messages.add_argument(1, p_permission_name));
      ROLLBACK;

    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('upd failed');
      RAISE;

  END upd;


  /*
    Returns all Permissions directly allowed to the specified permission.
  */
  FUNCTION get_permissions(
    p_permission_id IN INTEGER,
    p_permission_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;

  BEGIN
    logger.entering('get_permissions');

    OPEN l_result FOR
    SELECT
      p_permission_id AS parent_permission_id,
      p_permission_name AS parent_permission_name,
      permission_data.*
    FROM
      permission_data
    WHERE EXISTS (
      SELECT NULL
        FROM permission_set_data
       WHERE p_permission_id = permission_set_data.permission_id
         AND permission_data.permission_id = permission_set_data.permission_allowed_id)
    ORDER BY
      REPLACE(permission_name, '/', 'zz');

    RETURN l_result;

  END get_permissions;


  /*
    Returns the name of the specified permission or '???' if it does not exist.
  */
  FUNCTION get_permission_name(
    p_permission_id IN INTEGER
  )
  RETURN VARCHAR2
  IS
    l_result VARCHAR2(32767);

  BEGIN
    SELECT
      permission_data.permission_name
    INTO
      l_result
    FROM
      permission_data
    WHERE
      permission_data.permission_id = p_permission_id;

    RETURN l_result;

  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.error('failed to get permission name of permission ' || p_permission_id);
      RETURN '???';

  END get_permission_name;


  /*
    Allows p_permission_allowed_id to p_permission_id.
  */
  PROCEDURE allow(
    p_permission_id IN INTEGER,
    p_permission_allowed_id IN INTEGER
  )
  IS
    l_permission_loop_found EXCEPTION;

    /*
      Go through all of the permissions allowed for the specified
      permission making sure that l_permission is not found
    */
    PROCEDURE permission_loop_check(
      p_check_permission_allowed_id IN VARCHAR2
    )
    IS
    BEGIN
      logger.fb(
        'permission_loop_check: ' ||
        'p_check_permission_allowed=' || p_check_permission_allowed_id);

      FOR i IN (SELECT permission_allowed_id
                  FROM permission_set_data
                 WHERE permission_id = p_check_permission_allowed_id)
      LOOP
        IF (p_permission_id = i.permission_allowed_id)
        THEN
          user_messages.add_warn_message(
            'Failed to allow "{1}" the "{2}" permission. ' ||
            'Allowing this would create a permission loop',
            user_messages.add_argument(1, get_permission_name(p_permission_id),
            user_messages.add_argument(2, get_permission_name(p_permission_allowed_id))));

          RAISE l_permission_loop_found;

        END IF;

        permission_loop_check(i.permission_allowed_id);

      END LOOP;

    END permission_loop_check;

  BEGIN
    logger.entering('allow');

    logger.fb(
      'p_permission_id=' || p_permission_id ||
      ', p_permission_allowed_id=' || p_permission_allowed_id);

    INSERT INTO permission_set_data(
      permission_id, permission_allowed_id)
    VALUES(
      p_permission_id, p_permission_allowed_id);

    -- Make sure this call to allow is not creating a permission loop
    permission_loop_check(p_permission_allowed_id);

    COMMIT;

    logger.fb('permission allowed');

    user_messages.add_info_message(
      'Permission allowed. "{1}" has been allowed "{2}"',
      user_messages.add_argument(1, get_permission_name(p_permission_id),
      user_messages.add_argument(2, get_permission_name(p_permission_allowed_id))));

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      user_messages.add_warn_message(
        'Failed to allow "{1}" the "{2}" permission. Permission is already allowed',
        user_messages.add_argument(1, get_permission_name(p_permission_id),
        user_messages.add_argument(2, get_permission_name(p_permission_allowed_id))));
      ROLLBACK;

    WHEN l_permission_loop_found
    THEN
      ROLLBACK;

  END allow;


  /*
    Denies p_permission_allowed_id from p_permission_id.
  */
  PROCEDURE deny(
    p_permission_id IN INTEGER,
    p_permission_denied_id IN INTEGER
  )
  IS
  BEGIN
    logger.entering('deny');

    logger.fb(
      'p_permission_id=' || p_permission_id ||
      ', p_permission_denied_id=' || p_permission_denied_id);

    DELETE FROM
      permission_set_data
    WHERE
      permission_id = p_permission_id
    AND
      permission_allowed_id = p_permission_denied_id;

    IF (SQL%ROWCOUNT = 1)
    THEN
      logger.info('permission denied');

      user_messages.add_info_message(
        'Permission denied. "{1}" is no longer allowed "{2}"',
        user_messages.add_argument(1, get_permission_name(p_permission_id),
        user_messages.add_argument(2, get_permission_name(p_permission_denied_id))));

    ELSE
      user_messages.add_warn_message(
        'Failed to deny "{1}" the "{2}" permission. Permission has not been allowed',
        user_messages.add_argument(1, get_permission_name(p_permission_id),
        user_messages.add_argument(2, get_permission_name(p_permission_denied_id))));

    END IF;

    COMMIT;

  END deny;


  /*
    Returns the description of the specified permission.
  */
  FUNCTION get_permission_description(
    p_permission_name IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_result VARCHAR2(32767);

  BEGIN
    logger.entering('get_permission_description');

    logger.fb(
      'p_permission_name=' || p_permission_name);

    SELECT permission_data.permission_description
      INTO l_result
      FROM permission_data
     WHERE permission_data.permission_name = p_permission_name;

    RETURN l_result;

  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      RETURN p_permission_name || ' (unknown permission)';

  END get_permission_description;


END permission;
/
