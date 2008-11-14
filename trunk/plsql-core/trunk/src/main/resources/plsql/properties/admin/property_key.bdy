PACKAGE BODY property_key
IS

  /*
    Deletes a Property Key by primary key.
  */
  PROCEDURE del(
    p_key_id IN INTEGER 
  )
  IS
    l_key VARCHAR2(32767);
    
  BEGIN
    logger.entering('del');
 
    logger.fb(
      'p_key_id=' || p_key_id);
 
    DELETE FROM 
      property_key_data
    WHERE
      key_id = p_key_id
    RETURNING
      key INTO l_key;
 
    IF (SQL%ROWCOUNT = 0)
    THEN
      messages.add_message(
        messages.message_level_info,
        'Key "' || l_key || '" not deleted',
        'This row has already been deleted');
 
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Key "' || l_key || '" deleted',
        NULL);
 
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
    Creates a Property Key returning it's new primary key value.
  */
  PROCEDURE ins(
    p_key_id OUT INTEGER,
    p_key_description IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_group_id IN INTEGER,
    p_key IN VARCHAR2 
  )
  IS
  BEGIN
    logger.entering('ins');
 
    logger.fb(
      'p_key_description=' || p_key_description || 
      ', p_single_value_per_key=' || p_single_value_per_key || 
      ', p_group_id=' || p_group_id || 
      ', p_key=' || p_key);
 
    IF (p_single_value_per_key IS NULL)
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key not created',
        'Single value per key must not be null');
        
      RETURN;
      
    END IF;
    
    IF (p_key IS NULL)
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key not created',
        'Please provide a key');
        
      RETURN;
      
    END IF;
    
    IF (p_key LIKE '%#%')
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key not created',
        'Keys must not contain the pound character "#"');
        
      RETURN;
      
    END IF;
            
    
    INSERT INTO property_key_data(
      key_description,
      single_value_per_key,
      group_id,
      key)
    VALUES(
      p_key_description,
      p_single_value_per_key,
      p_group_id,
      p_key)
    RETURNING
      key_id 
    INTO
      p_key_id;
 
    messages.add_message(
      messages.message_level_info,
      'Key "' || p_key || '" created',
      NULL);
 
    COMMIT;
    
    logger.exiting('ins', p_key_id);
    
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      messages.add_message(
        messages.message_level_info,
        'Key "' || p_key || '" not created',
        'This key already exists');
        
    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('ins failed');
      RAISE;
 
  END ins;
 

  /*
    Updates a Property Key by primary key.
  */
  PROCEDURE upd(
    p_key_id IN INTEGER,
    p_key_description IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_old_single_value_per_key IN VARCHAR2,
    p_group_id IN INTEGER,
    p_key IN VARCHAR2,
    p_old_key IN VARCHAR2
  )
  IS
    -- this will hold the property value for the key we will update
    l_value_data_row property_value_data%ROWTYPE;
    -- flag to indicate values will need updating
    l_values_need_update BOOLEAN := FALSE;

  BEGIN
    logger.entering('upd');
 
    logger.fb(
      'p_key_id=' || p_key_id || 
      ', p_key_description=' || p_key_description || 
      ', p_single_value_per_key=' || p_single_value_per_key || 
      ', p_old_single_value_per_key=' || p_old_single_value_per_key ||
      ', p_group_id=' || p_group_id || 
      ', p_key=' || p_key ||
      ', p_old_key=' || p_old_key);
 
    IF (p_single_value_per_key IS NULL)
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key "' || p_old_key || '" not updated',
        'You cannot set single value per key to null');
        
      RETURN;
      
    END IF;
    
    IF (p_key IS NULL)
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key "' || p_old_key || '" not updated',
        'You cannot set a key to null');
        
      RETURN;
      
    END IF;
    
    IF (p_key LIKE '%#%')
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key "' || p_old_key || '" not updated',
        'Keys must not contain the pound character "#"');
        
      RETURN;
      
    END IF;

    IF (p_single_value_per_key != p_old_single_value_per_key)
    THEN
      logger.fb('single_value_per_key is being updated');
      
      -- if the key already exists, we may have to update property_value_data.
      -- lock both tables that we may affect
      LOCK TABLE property_value_data IN EXCLUSIVE MODE NOWAIT;
      LOCK TABLE property_key_data IN EXCLUSIVE MODE NOWAIT;
      
      /*
        We need to update values if:
          - The key we will be updating has a value and
          - Single value per key is being changed.
      */
      <<get_value>>
      BEGIN
        -- load the value for the key we will update
        SELECT *
          INTO l_value_data_row
          FROM property_value_data
         WHERE key_id = p_key_id;

        logger.fb('found one value. values need update');

        l_values_need_update := TRUE;
        
        -- update single value per key for the value that we'll re-insert
        l_value_data_row.single_value_per_key := p_single_value_per_key;

        -- delete the value
        DELETE FROM property_value_data
        WHERE key_id = p_key_id;

        logger.fb(SQL%ROWCOUNT || ' values deleted');
        
      EXCEPTION
        WHEN TOO_MANY_ROWS
        THEN
          logger.fb('found more than one value');
          -- this is only a problem if we're changing to single value per key
          IF (p_single_value_per_key = 'Y')
          THEN
            messages.add_message(
              messages.message_level_warning,
              'Key "' || p_old_key || '" not updated',
              'You cannot change this key to single value per key as multiple values exist');
            --
            RETURN;
            
          END IF;

        WHEN NO_DATA_FOUND
        THEN
          logger.fb('no values found');

          l_values_need_update := FALSE;

      END get_value;
      
    END IF;
    
    -- always update the key
    UPDATE
      property_key_data
    SET
      key_description = p_key_description,
      single_value_per_key = p_single_value_per_key,
      group_id = p_group_id,
      key = p_key 
    WHERE
      key_id = p_key_id;

    logger.fb('key updated');

    -- if we need to update any values, re-insert them now
    IF (l_values_need_update)
    THEN
      INSERT INTO property_value_data(
        value_id,
        key_id,
        single_value_per_key,
        value,
        sort_order)
      VALUES(
        l_value_data_row.value_id,
        l_value_data_row.key_id,
        l_value_data_row.single_value_per_key,
        l_value_data_row.value,
        l_value_data_row.sort_order);

      logger.fb(SQL%ROWCOUNT || ' values re-inserted');

    END IF;

    -- always commit
    COMMIT;
      
    messages.add_message(
      messages.message_level_info,
      'Key "' || p_key || '" updated',
      NULL);
    
    logger.exiting('upd');
    
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      messages.add_message(
        messages.message_level_warning,
        'Key  "' || p_old_key || '" not updated',
        'The key you wanted to update to already exists');
     
    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('upd failed');
      RAISE;
 
  END upd;
 
  
  /*
    Returns all keys of this group.
  */   
  FUNCTION get_values(
    p_key_id IN INTEGER,
    p_value IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('get_values');
    
    OPEN l_result FOR
    SELECT
      *
    FROM 
      property_value_data
    WHERE 
      key_id = p_key_id
    AND (
      UPPER(value) LIKE '%' || UPPER(p_value) || '%'
      OR value IS NULL AND p_value IS NULL)
    ORDER BY 
      sort_order;
     
    RETURN l_result;
    
  END get_values;
  
  
END property_key;
/