CREATE OR REPLACE PACKAGE BODY property_group
IS

  /*
    Deletes a Property Group by primary key.
  */
  PROCEDURE del(
    p_group_id IN INTEGER
  )
  IS
    l_group_name VARCHAR2(32767);

  BEGIN
    logger.entering('del');

    logger.fb(
      'p_group_id=' || p_group_id);

    DELETE FROM
      property_group_data
    WHERE
      group_id = p_group_id
    RETURNING
      group_name INTO l_group_name;

    IF (SQL%ROWCOUNT = 0)
    THEN
      user_messages.add_info_message(
        'Group not deleted. This row has already been deleted');

    ELSE
      user_messages.add_info_message(
        'Group "{1}" deleted',
        user_messages.add_argument(1, l_group_name));

    END IF;

    COMMIT;

    logger.exiting('del');

  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('del failed');
      RAISE;

  END del;


  /*
    Creates a Property Group.
  */
  PROCEDURE ins(
    p_group_id OUT INTEGER,
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('ins');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_group_description=' || p_group_description);

    IF (p_group_name IS NULL)
    THEN
      user_messages.add_warn_message(
        'Group not created. You cannot create a group with no name');

      RETURN;

    END IF;

    IF (p_group_name LIKE '%#%')
    THEN
      user_messages.add_warn_message(
        'Group not created, Group names must not contain the pound character "#"');

      RETURN;

    END IF;

    INSERT INTO property_group_data(
      group_name,
      group_description)
    VALUES(
      p_group_name,
      p_group_description)
    RETURNING
      group_id
    INTO
      p_group_id;

    user_messages.add_info_message(
      'Group "{1}" created',
        user_messages.add_argument(1, p_group_name));

    COMMIT;

    logger.exiting('ins', p_group_id);

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      user_messages.add_warn_message(
        'Group "{1}" not created. This group already exists',
        user_messages.add_argument(1, p_group_name));

    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('ins failed');
      RAISE;

  END ins;


  /*
    Updates a Property Group by primary key.
  */
  PROCEDURE upd(
    p_group_id IN INTEGER,
    p_group_name IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('upd');

    logger.fb(
      'p_group_id=' || p_group_id ||
      ', p_group_name=' || p_group_name ||
      ', p_old_group_name=' || p_old_group_name ||
      ', p_group_description=' || p_group_description);

    IF (p_group_name IS NULL)
    THEN
      user_messages.add_warn_message(
        'Group "{1}" not updated, You cannot set a group name to null',
        user_messages.add_argument(1, p_old_group_name));

      RETURN;

    END IF;

    IF (p_group_name LIKE '%#%')
    THEN
      user_messages.add_warn_message(
        'Group "{1}" not updated. Group names must not contain the pound character "#"',
        user_messages.add_argument(1, p_old_group_name));

      RETURN;

    END IF;

    UPDATE
      property_group_data
    SET
      group_name = p_group_name,
      group_description = p_group_description
    WHERE
      group_id = p_group_id;

    IF (SQL%ROWCOUNT = 0)
    THEN
      user_messages.add_info_message(
        'Group "{1}" not updated. This row has been deleted',
        user_messages.add_argument(1, p_old_group_name));

    ELSE
      user_messages.add_info_message(
        'Group "{1}" updated',
        user_messages.add_argument(1, p_group_name));

    END IF;

    COMMIT;

    logger.exiting('upd');

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      user_messages.add_warn_message(
        'Group "{1}" not updated. The group name you wanted to update to already exists',
        user_messages.add_argument(1, p_old_group_name));

    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('upd failed');
      RAISE;

  END upd;


  /*
    Returns all keys of the specified group.
  */
  FUNCTION get_keys(
    p_group_id IN INTEGER,
    p_key IN VARCHAR2,
    p_key_description IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;

  BEGIN
    logger.entering('get_keys');

    logger.fb(
      'p_group_id=' || p_group_id ||
      ', p_key=' || p_key ||
      ', p_key_description=' || p_key_description ||
      ', p_single_value_per_key=' || p_single_value_per_key);

    OPEN l_result FOR
    SELECT
      *
    FROM
      property_key_data
    WHERE
      group_id = p_group_id
    AND (
      UPPER(key) LIKE '%' || UPPER(p_key) || '%'
      OR key IS NULL AND p_key IS NULL)
    AND (
      UPPER(key_description) LIKE '%' || UPPER(p_key_description) || '%'
      OR key_description IS NULL AND p_key_description IS NULL)
    AND (
      UPPER(single_value_per_key) LIKE '%' || UPPER(p_single_value_per_key) || '%'
      OR single_value_per_key IS NULL AND p_single_value_per_key IS NULL)
    ORDER BY
      key;

    RETURN l_result;

  END get_keys;


END property_group;
/
