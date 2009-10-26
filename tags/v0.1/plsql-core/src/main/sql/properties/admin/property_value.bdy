PACKAGE BODY property_value
IS
 

  /*
    Deletes a Property Value by primary key.
  */
  PROCEDURE del(
    p_value_id IN INTEGER 
  )
  IS
  BEGIN
    logger.entering('del');
 
    logger.fb(
      'p_value_id=' || p_value_id);
 
    DELETE FROM 
      property_value_data
    WHERE
      value_id = p_value_id;
 
    IF (SQL%ROWCOUNT = 0)
    THEN
      messages.add_message(
        messages.message_level_info,
        'Value "' || p_value_id || '" not deleted',
        'This row has already been deleted');
 
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Value "' || p_value_id || '" deleted',
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
    Creates a Property Value returning it's new primary key value.
  */
  PROCEDURE ins(
    p_value_id OUT INTEGER,
    p_sort_order IN INTEGER,
    p_value IN VARCHAR2,
    p_key_id IN INTEGER 
  )
  IS
    l_single_value_per_key VARCHAR2(1);
    
  BEGIN
    logger.entering('ins');
 
    logger.fb(
      'p_sort_order=' || p_sort_order || 
      ', p_value=' || p_value || 
      ', p_key_id=' || p_key_id);
      
    SELECT single_value_per_key
      INTO l_single_value_per_key
      FROM property_key_data
     WHERE key_id = p_key_id;
      
    INSERT INTO property_value_data(
      sort_order,
      value,
      single_value_per_key,
      key_id)
    VALUES(
      p_sort_order,
      p_value,
      l_single_value_per_key,
      p_key_id)
    RETURNING
      value_id 
    INTO
      p_value_id;
 
    messages.add_message(
      messages.message_level_info,
      'Value "' || p_value_id || '" created',
      NULL);
 
    COMMIT;
    
    logger.exiting('upd', p_value_id);
    
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      messages.add_message(
        messages.message_level_info,
        'Value not created',
        'This key is set to single value per key and already has a value');
    
    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('ins failed');
      RAISE;
 
  END ins;
 
 
  /*
    Updates a Property Value by primary key.
  */
  PROCEDURE upd(
    p_value_id IN INTEGER,
    p_sort_order IN INTEGER,
    p_value IN VARCHAR2,
    p_key_id IN INTEGER 
  )
  IS
  BEGIN
    logger.entering('upd');
 
    logger.fb(
      'p_value_id=' || p_value_id || 
      ', p_sort_order=' || p_sort_order || 
      ', p_value=' || p_value || 
      ', p_key_id=' || p_key_id);
 
    UPDATE
      property_value_data
    SET
      sort_order = p_sort_order,
      value = p_value,
      key_id = p_key_id 
    WHERE
      value_id = p_value_id;
 
    IF (SQL%ROWCOUNT = 0)
    THEN
      messages.add_message(
        messages.message_level_info,
        'Value "' || p_value_id || '" not updated',
        'This row has been deleted');
 
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Value "' || p_value_id || '" updated',
        NULL);
 
    END IF;
 
    COMMIT;
    
    logger.exiting('upd');
    
  EXCEPTION
    WHEN OTHERS
    THEN
      ROLLBACK;
      logger.error('upd failed');
      RAISE;
 
  END upd;
 
 
END property_value;
/