CREATE OR REPLACE PACKAGE BODY property_value
IS
  
  FUNCTION del(
    p_row_id IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_key IN VARCHAR2,
    p_old_property_description IN VARCHAR2,
    p_old_sort_order IN VARCHAR2,
    p_old_value IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_locked property_groups_data.locked%TYPE;
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);

  BEGIN
    logger.entering('del');
    
    <<check_locked>>
    BEGIN
      SELECT locked
        INTO l_locked
        FROM property_groups_data
       WHERE group_name = p_old_group_name;
      
      IF (l_locked = constants.yes)
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to delete property value ' || p_old_group_name || '#' || p_old_key,
          'Group is locked');
        
        RETURN 'error';
        
      END IF;
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to delete property value',
          'Group "' || p_old_group_name || '" does not exist');
        
        RETURN 'error';
        
    END check_locked;
    
    DELETE FROM property_values_data
     WHERE rowid = p_row_id 
       AND (group_name = p_old_group_name OR 
             (group_name IS NULL AND p_old_group_name IS NULL)) 
       AND (key = p_old_key OR 
             (key IS NULL AND p_old_key IS NULL)) 
       AND (property_description = p_old_property_description OR
             (property_description IS NULL AND p_old_property_description IS NULL)) 
       AND (sort_order = p_old_sort_order OR 
             (sort_order IS NULL AND p_old_sort_order IS NULL))
       AND (value = p_old_value OR
             (value IS NULL AND p_old_value IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      l_message_summary := 
        'Property value ' || p_old_group_name || '#' || p_old_key || ' not deleted';
      l_message_detail := 
        'This property value may have been deleted or updated by another session';
        
    ELSE
      l_message_summary := 'Property value deleted'; 
      l_message_detail := 
        p_old_group_name || '#' || p_old_key || '(' || p_old_value || ')';
        
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to delete property_value. p_row_id=' || p_row_id ||
        ', p_old_group_name=' || p_old_group_name ||
        ', p_old_key=' || p_old_key ||
        ', p_old_property_description=' || p_old_property_description ||
        ', p_old_value=' || p_old_value);

      messages.add_message(
        messages.message_level_error,
        'Failed to delete property value ' || 
        p_old_group_name || '#' || p_old_key || '(' || p_old_value || ')',
        SQLERRM);

    RETURN 'error';

  END del;

  FUNCTION ins(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_property_description IN VARCHAR2,
    p_sort_order IN VARCHAR2,
    p_value IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_locked property_groups_data.locked%TYPE;
    l_single_value property_groups_data.single_value_per_key%TYPE;
    l_count INTEGER;
    
  BEGIN
    logger.entering('ins');
    
    <<get_group_details>>
    BEGIN
      SELECT locked, single_value_per_key
        INTO l_locked, l_single_value
        FROM property_groups_data
       WHERE group_name = p_group_name;
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to create property value',
          'Group "' || p_group_name || '" does not exist');
        
        RETURN 'error';
        
    END get_group_details;
    
    IF (l_locked = constants.yes)
    THEN
      messages.add_message(
        messages.message_level_error,
        'Failed to create property value ' || p_group_name || '#' || p_key,
        'Group is locked');
        
      RETURN 'error';
        
    END IF;
      
    IF (l_single_value = constants.yes)
    THEN
      SELECT COUNT(*) INTO l_count
        FROM property_values_data
       WHERE group_name = p_group_name
         AND key = p_key;
      
      IF (l_count != 0)
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to create property value ' || p_group_name || '#' || p_key,
          'Group ' || p_group_name || 
          ' uses "single value per key" and already has a value for key ' || p_key);
          
        RETURN 'error';
        
      END IF;
      
    END IF;
    
    INSERT INTO property_values_data(
      group_name, key, property_description, sort_order, value)
    VALUES (
      p_group_name, p_key, p_property_description, p_sort_order, p_value);

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      'Property value created', 
      p_group_name || '#' || p_key || '(' || p_value || ')');

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to insert property_value. p_group_name=' || p_group_name ||
        ', p_key=' || p_key ||
        ', p_property_description=' || p_property_description ||
        ', p_value=' || p_value);

      messages.add_message(
        messages.message_level_error,
        'Failed to create property value ' || 
        p_group_name || '#' || p_key || '(' || p_value || ')',
        SQLERRM);

    RETURN 'error';

  END ins;

  FUNCTION upd(
    p_row_id IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_key IN VARCHAR2,
    p_key IN VARCHAR2,
    p_old_property_description IN VARCHAR2,
    p_property_description IN VARCHAR2,
    p_old_sort_order IN VARCHAR2,
    p_sort_order IN VARCHAR2,
    p_old_value IN VARCHAR2,
    p_value IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_locked property_groups_data.locked%TYPE;
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);

  BEGIN
    logger.entering('upd');
    
    <<check_locked>>
    BEGIN
      SELECT locked
        INTO l_locked
        FROM property_groups_data
       WHERE group_name = p_old_group_name;
      
      IF (l_locked = constants.yes)
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to update property value ' || p_old_group_name || '#' || p_old_key,
          'Group is locked');
        
        RETURN 'error';
        
      END IF;
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to update property value',
          'Group "' || p_old_group_name || '" does not exist');
        
        RETURN 'error';
        
    END check_locked;
    
    UPDATE property_values_data
       SET key = p_key,
           property_description = p_property_description,
           sort_order = p_sort_order,
           value = p_value
     WHERE rowid = p_row_id
       AND (key = p_old_key OR 
             (key IS NULL AND p_old_key IS NULL))
       AND (property_description = p_old_property_description OR 
             (property_description IS NULL AND p_old_property_description IS NULL))
       AND (sort_order = p_old_sort_order OR 
             (sort_order IS NULL AND p_old_sort_order IS NULL))
       AND (value = p_old_value OR 
             (value IS NULL AND p_old_value IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      l_message_summary := 
        'Property value ' || p_old_group_name || '#' || p_old_key || ' not updated';
      l_message_detail := 
        'This property value may have been deleted or updated by another session';
        
    ELSE
      l_message_summary := 'Property value updated';
      l_message_detail := p_old_group_name || '#' || p_old_key;
      
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to update property value. p_row_id=' || p_row_id ||
        ', p_old_group_name=' || p_old_group_name ||
        ', p_key=' || p_key ||
        ', p_property_description=' || p_property_description ||
        ', p_value=' || p_value);

      messages.add_message(
        messages.message_level_error,
        'Failed to update property_value ' || p_old_group_name || '#' || p_old_key,
        SQLERRM);

    RETURN 'error';

  END upd;
  
END property_value;
/
