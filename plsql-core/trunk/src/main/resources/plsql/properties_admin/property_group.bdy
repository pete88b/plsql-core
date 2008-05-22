CREATE OR REPLACE PACKAGE BODY property_group
IS
  
  FUNCTION ins(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_group_description IN VARCHAR2 := NULL
  )
  RETURN VARCHAR2
  IS
  BEGIN
    logger.entering('ins');
    
    INSERT INTO property_groups_data
      (group_name, single_value_per_key, group_description)
    VALUES
      (p_group_name, UPPER(p_single_value_per_key), p_group_description);

    COMMIT;
    
    messages.add_message(
      messages.message_level_info,
      'Property group created', p_group_name);
    
    RETURN NULL;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to create property group. p_group_name=' || p_group_name ||
        ', p_single_value_per_key=' || p_single_value_per_key ||
        ', p_group_description=' || p_group_description);
      
      messages.add_message(
        messages.message_level_error,
        'Failed to create property group ' || p_group_name,
        SQLERRM);
      
      RETURN 'error';
            
  END ins;
  
  FUNCTION del(
    p_row_id IN VARCHAR2,
    p_force IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_single_value_per_key IN VARCHAR2,
    p_old_locked IN VARCHAR2,
    p_old_group_description IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_locked property_groups_data.locked%TYPE;
    l_group_name property_groups_data.group_name%TYPE;
    l_value_count INTEGER;
    
  BEGIN
    logger.entering('del');
    
    logger.fb(
      'p_row_id=' || p_row_id ||
      ', p_force=' || p_force ||
      ', p_old_group_name=' || p_old_group_name ||
      ', p_old_single_value_per_key=' || p_old_single_value_per_key || 
      ', p_old_locked=' || p_old_locked ||
      ', p_old_group_description=' || p_old_group_description);
    
    IF (p_force = constants.yes)
    THEN
      logger.fb('doing force delete');
      
      SELECT group_name INTO l_group_name 
        FROM property_groups_data
       WHERE ROWID = p_row_id;
       
      IF (l_group_name != p_old_group_name)
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to force delete property group ' || p_old_group_name,
          'ROWID refers to group ' || l_group_name);
        
        RETURN 'error';
      
      END IF; -- End of IF (l_group_name != p_old_group_name)
      
      DELETE FROM property_values_data
       WHERE group_name = l_group_name;
         
      l_value_count := SQL%ROWCOUNT;
      
      DELETE FROM property_groups_data
       WHERE ROWID = p_row_id;
         
      messages.add_message(
        messages.message_level_info,
        'Property group ' || l_group_name || ' (and it''s ' || 
        l_value_count || ' property values) deleted', NULL);
        
      COMMIT;
        
      RETURN NULL;
      
    END IF; -- End of IF (p_force = constants.yes)
    
    
    logger.fb('doing normal delete');
    
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
          'Failed to delete property group ' || p_old_group_name,
          'Group is locked');
        
        RETURN 'error';
        
      END IF;
      
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
        messages.add_message(
          messages.message_level_error,
          'Failed to delete property group ' || p_old_group_name,
          'Group does not exist');
        
        RETURN 'error';
        
    END check_locked;
    
    DELETE FROM property_groups_data
     WHERE ROWID = p_row_id
       AND (single_value_per_key = p_old_single_value_per_key OR 
            single_value_per_key IS NULL AND p_old_single_value_per_key IS NULL)
       AND (locked = p_old_locked OR 
            locked IS NULL AND p_old_locked IS NULL)
       AND (group_description = p_old_group_description OR 
            group_description IS NULL AND p_old_group_description IS NULL);
       
    IF (SQL%ROWCOUNT = 0)
    THEN
      messages.add_message(
        messages.message_level_info,
        'Property group ' || p_old_group_name || ' not deleted',
        'This group may have been updated or deleted by another session');
      
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Property group deleted', p_old_group_name);
        
    END IF;
    
    COMMIT;
    
    RETURN NULL;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to delete property group. p_row_id=' || p_row_id ||
        ', p_force=' || p_force ||
        ', p_old_group_name=' || p_old_group_name ||
        ', p_old_single_value_per_key=' || p_old_single_value_per_key ||
        ', p_old_locked=' || p_old_locked ||
        ', p_old_group_description=' || p_old_group_description);
      
      messages.add_message(
        messages.message_level_error,
        'Failed to delete property group ' || p_old_group_name,
        SQLERRM);
      
      RETURN 'error';
      
  END del;
  
  FUNCTION upd(
    p_row_id IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_single_value_per_key IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_old_locked IN VARCHAR2,
    p_locked IN VARCHAR2,
    p_old_group_description IN VARCHAR2,
    p_group_description IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_locked property_groups_data.locked%TYPE;
    
  BEGIN
    logger.entering('upd');
    
    <<check_locked>>
    IF (NOT p_locked = constants.no)
    THEN
      BEGIN
        SELECT locked
          INTO l_locked
          FROM property_groups_data
         WHERE group_name = p_old_group_name;
        
        IF (l_locked = constants.yes)
        THEN
          messages.add_message(
            messages.message_level_error,
            'Failed to update property group ' || p_old_group_name,
            'Group is locked');
          
          RETURN 'error';
          
        END IF;
        
      EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          messages.add_message(
            messages.message_level_error,
            'Failed to update property group ' || p_old_group_name,
            'Group does not exist');
          
          RETURN 'error';
          
      END check_locked;
      
    END IF; -- End of IF (NOT p_locked = constants.no)
    
    UPDATE property_groups_data
       SET single_value_per_key = p_single_value_per_key,
           locked = p_locked,
           group_description = p_group_description
     WHERE ROWID = p_row_id
       AND (single_value_per_key = p_old_single_value_per_key OR 
            single_value_per_key IS NULL AND p_old_single_value_per_key IS NULL)
       AND (locked = p_old_locked OR 
            locked IS NULL AND p_old_locked IS NULL)
       AND (group_description = p_old_group_description OR 
            group_description IS NULL AND p_old_group_description IS NULL);
            
    IF (SQL%ROWCOUNT = 0)
    THEN
      messages.add_message(
        messages.message_level_info,
        'Property group ' || p_old_group_name || ' not updated',
        'This group may have been updated or deleted by another session');
      
    ELSE
      messages.add_message(
        messages.message_level_info,
        'Property group updated', p_old_group_name);
        
    END IF;
    
    COMMIT;
    
    RETURN NULL;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to update property group. p_row_id=' || p_row_id ||
        ', p_old_group_name=' || p_old_group_name ||
        ', p_single_value_per_key=' || p_single_value_per_key ||
        ', p_locked=' || p_locked ||
        ', p_group_description=' || p_group_description);
      
      messages.add_message(
        messages.message_level_error,
        'Failed to update property group ' || p_old_group_name,
        SQLERRM);
      
      RETURN 'error';
      
  END upd;
  
  FUNCTION get_property_values(
    p_old_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS 
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('get_property_values');
    
    OPEN l_result FOR
    SELECT ROWIDTOCHAR(ROWID) AS row_id, 
           property_values_data.*, 
           DECODE(INSTR(value, CHR(10)), 0, 'N', NULL, 'N', 'Y') AS value_contains_cr
      FROM property_values_data
     WHERE group_name = p_old_group_name
     ORDER BY key, sort_order, value;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to get property values. p_old_group_name=' || p_old_group_name);
      RAISE;
    
  END get_property_values;
  
END property_group;
/
