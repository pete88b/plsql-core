CREATE OR REPLACE PACKAGE property_manager
IS


  /*
    Provides facilities for managing and retrieving properties.
    
    Properties are organised into property groups. 
    Property groups are saved in the property_group_data table. 
    Property groups can have any number of keys. 
    Keys are saved in the property_key_data table. 
    
    There are two main types of key: 
      Keys that allow no more than one value. Known as single value keys. 
      Keys that allow any number of values. Known as multiple value keys. 
      
    Values are saved in the property_value_data table. 

    A property is identified by it's group and key. 
    Property values are identified by value_id. 

    A property is said to not exist if: 
      It's property group does not exist or 
      It's key does not exist (within it's group). 
      
    A property is said to have no value if: 
      It's property group does not exist, 
      It's key does not exist (within it's group) or 
      It has no value. i.e. no row in the property_value_data table. 
      
    Property group names, keys and values are all case sensitive. 
    NULL cannot be used as a group name or key. 
    NULL is a valid value. 

    None of the modules in the properties package affect the transaction 
    from which they are called. 
  */
  
  
  /*opb-package
    field
      name=group_name
      datatype=VARCHAR2
      in_load=ignored;
 
    field
      name=group_description
      datatype=VARCHAR2
      in_load=ignored;
 
    field
      name=key
      datatype=VARCHAR2
      in_load=ignored;

    field
      name=single_value_per_key
      datatype=VARCHAR2
      in_load=ignored;
 
    field
      name=key_description
      datatype=VARCHAR2
      in_load=ignored;
 
    field
      name=value_count
      datatype=INTEGER
      in_load=ignored;
      
    field
      name=value
      datatype=VARCHAR2
      in_load=ignored;
 
    field
      name=sort_order
      datatype=INTEGER
      in_load=ignored;
 
  */
  

  /*
    The error code used to indicate a property group could not be found.
  */
  group_not_found_code CONSTANT INTEGER := -20100;
  
  /*
    The exception used to indicate a property group could not be found.
  */
  group_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(group_not_found, -20100);
  
  
  /*
    The error code used to indicate a property key could not be found.
  */
  key_not_found_code CONSTANT INTEGER := -20101;
  
  /*
    The exception used to indicate a property key could not be found.
  */
  key_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(key_not_found, -20101);
  
  
  /*
    The error code used to indicate a property value could not be found.
  */
  value_not_found_code CONSTANT INTEGER := -20102;
  
  /*
    The exception used to indicate a property value could not be found.
  */
  value_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(value_not_found, -20102);
  
  
  /*
    The error code used to indicate a property value could not be found.
  */
  too_many_values_code CONSTANT INTEGER := -20103;
  
  /*
    The exception used to indicate a property value could not be found.
  */
  too_many_values EXCEPTION;
  PRAGMA EXCEPTION_INIT(too_many_values, -20103);
  

  /*
    Returns all Property Groups that meet the search criteria.
  */
  /*opb
    param
      name=p_group_name
      field=group_name;
 
    param
      name=p_group_description
      field=group_description;
 
    param
      name=RETURN
      datatype=cursor?property_group;
  */
  FUNCTION get_filtered_groups(
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2 
  )
  RETURN SYS_REFCURSOR;
 
  
  /*
    Returns full details of all keys that meet the search criteria.
    The results returned will be from the property keys view.
  */
  /*opb
    param
      name=p_group_name
      field=group_name;
 
    param
      name=p_group_description
      field=group_description;

    param
      name=p_key
      field=key;
 
    param
      name=p_single_value_per_key
      field=single_value_per_key;
      
    param
      name=p_key_description
      field=key_description;
 
    param
      name=p_value_count
      field=value_count;
 
    param
      name=RETURN
      use_result_cache=N;
  */
  FUNCTION get_keys_view(
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2,
    p_key IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_key_description IN VARCHAR2,
    p_value_count IN INTEGER
  )
  RETURN SYS_REFCURSOR;
  
  
  /*
    Returns full details of all values that meet the search criteria.
    The results returned will be from the property values view.
  */
  /*opb
    param
      name=p_group_name
      field=group_name;
 
    param
      name=p_group_description
      field=group_description;

    param
      name=p_key
      field=key;
 
    param
      name=p_single_value_per_key
      field=single_value_per_key;
      
    param
      name=p_key_description
      field=key_description;

    param
      name=p_value
      field=value;
 
    param
      name=p_sort_order
      field=sort_order;
 
    param
      name=RETURN
      use_result_cache=N;
  */
  FUNCTION get_values_view(
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2,
    p_key IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_key_description IN VARCHAR2,
    p_value IN VARCHAR2,
    p_sort_order IN INTEGER
  )
  RETURN SYS_REFCURSOR;
  
  
  /*
    Creates or updates a property group.

    An exception is raised if we fail to create or udpate the group.
    
    Parameters:
      p_group_name 
        The name of the group to create or update.
        This must not be NULL.
        If this is not already used as a property group name, this call
        will create a new group.
        If this is already used as a property group name, we will update
        the description of the existing group.
        
      p_description
        The description of the group.
  */
  PROCEDURE create_or_update_group(
    p_group_name IN VARCHAR2,
    p_description IN VARCHAR2 := NULL
  );


  /*
    Creates or updates a property key.

    An exception is raised if we fail to create the key.
    
    Parameters:
      p_group_name 
        The name of the group to which the new key should belong.
        This must be a property group name.
        
      p_key
        The name of the key to create or update.
        This must not be NULL.
        
      p_description
        The description of the key.
        
      p_single_value_per_key
        Pass 'N' to allow this key to have multiple values.
        The default 'Y' creates a key that can have one value at most.
  */
  /*opb
    param
      name=p_single_value_per_key
      datatype=BOOLEAN;
  */
  PROCEDURE create_or_update_key(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_description IN VARCHAR2 := NULL,
    p_single_value_per_key IN VARCHAR2 := 'Y'
  );
  
  
  /*
    Removes a group, all keys that belong to the group and all values 
    of the keys removed.
    
    Parameters:
      p_group_name 
        This must be a property group name.
  */
  PROCEDURE remove_group(
    p_group_name IN VARCHAR2
  );
  
  
  /*
    Removes all keys that belong to the specified group and all values 
    of the keys removed.
    
    Parameters:
      p_group_name 
        This must be a property group name.
  */
  PROCEDURE remove_keys(
    p_group_name IN VARCHAR2
  );
  
  
  /*
    Removes a key an all of it's values.
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
  */
  PROCEDURE remove_key(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  );
  
  
  /*
    Removes all values of the specified key.
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
  */
  PROCEDURE remove_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  );
  
  
  /*
    Sets a property value.

    If the specified key does not yet have a value, a value will be created.

    If the specified key does have a value, it's value will be updated.
    
    An exception will be raised if the specified key is not limited to
    having a single value. 
    i.e. single_value_per_key must = 'Y' for the specified key. 
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
        
      p_value
        The value for this property.
  */
  PROCEDURE set_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  );
  
  
  /*
    Adds a property value.

    Use this procedure to create multiple values for a key.
    
    An exception will be raised if the specified key is limited to
    having a single value. 
    i.e. single_value_per_key must = 'N' for the specified key.
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
        
      p_value
        The value for this property.
        
      p_sort_order
        Used (by get_values and get_properties) to determine the
        order of values that use the same key.
  */
  PROCEDURE add_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2,
    p_sort_order IN INTEGER := NULL
  );
  
  
  /*
    Returns the value of the specified property.

    An exception is raised if the property has no value.
    An exception is raised if the property has multiple values.
    No exceptions will be raised if the property has one value - 
      even if the specified key is not limited to having a single value. 
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  
  /*
    Returns the value of the specified property or p_default if
    the property has no value.

    An exception is raised if the property has multiple values.
    No exceptions will be raised if the property has at most one value - 
      even if the specified key is not limited to having a single value. 
    
    Parameters:
      p_group_name 
        A property group name that may or may not exist.
        
      p_key
        A key that may or may not exist.
        
      p_default
        The value to return if the specified property can not be found.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_default IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  
  /*
    Returns the value of the first property that has a value.
    
    An exception is raised if the property group does not exist.
    An exception is raised if a property is found to have multiple values.
    An exception is raised if none of the specified keys have a value.
    An exception is raised if p_keys is NULL or contains no elements.
    No exceptions will be raised if a property is found to have one value -
      even if it's key is not limited to having a single value. 
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        One of these should be a key that belongs to the specified group.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_keys IN varchar_table
  )
  RETURN VARCHAR2;
  
  
  /*
    Returns the value of the first property that has a value or 
    p_default if none of the properties have a value.

    An exception is raised if the property has multiple values.
    No exceptions will be raised if the property has at most one value - 
      even if the specified key is not limited to having a single value. 
    
    Parameters:
      p_group_name 
        A property group name that may or may not exist.
        
      p_keys
        A set of keys that may or may not exist.
        If p_keys is NULL or contains no elements, p_default is returned.
        
      p_default
        The value to return if none of the specified properties 
        can not be found.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_keys IN varchar_table,
    p_default IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  
  /*
    Returns all values for the specified property.

    Results will be sorted by sort_order.

    An exception is raised if the specified property does not exist.
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
  */
  FUNCTION get_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN varchar_table;
  
  
  /*
    Returns all values for the specified property or
    p_default if the property does not exist.

    If the specified property exists: 
      results will be sorted by sort_order.
      
    Parameters:
      p_group_name 
        A property group name that may or may not exist.
        
      p_key
        A key that may or may not exist.
        
      p_default
        The values to return if the specified property can not be found.
  */
  FUNCTION get_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_default IN varchar_table
  )
  RETURN varchar_table;
  
  
END property_manager;
/
CREATE OR REPLACE PACKAGE BODY property_manager
IS

  /*
    Used to catch the exception thrown by Oracle when an integrity 
    constraint has been violated due to a missing parent key.
  */
  parent_key_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(parent_key_not_found, -02291);
  
 
  /*
  */
  FUNCTION get_filtered_groups(
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2 
  )
  RETURN SYS_REFCURSOR 
  IS
    l_result SYS_REFCURSOR;
 
  BEGIN
    logger.entering('get_filtered_groups');
 
    logger.fb(
      'p_group_name=' || p_group_name || 
      ', p_group_description=' || p_group_description);
 
    OPEN l_result FOR
    SELECT
      property_group_data.*
    FROM
      property_group_data
    WHERE (
      UPPER(group_name) LIKE '%' || UPPER(p_group_name) || '%'
      OR group_name IS NULL AND p_group_name IS NULL) 
    AND (
      UPPER(group_description) LIKE '%' || UPPER(p_group_description) || '%'
      OR group_description IS NULL AND p_group_description IS NULL)
    ORDER BY
      group_name;
 
    RETURN l_result;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('get_filtered_groups failed');
      RAISE;
 
  END get_filtered_groups;
 
  
  /*
  */
  FUNCTION get_keys_view(
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2,
    p_key IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_key_description IN VARCHAR2,
    p_value_count IN INTEGER
  )
  RETURN SYS_REFCURSOR 
  IS
    l_result SYS_REFCURSOR;
 
  BEGIN
    logger.entering('get_keys_view');
 
    logger.fb(
      'p_group_name=' || p_group_name || 
      ', p_group_description=' || p_group_description ||
      ', p_key=' || p_key ||
      ', p_single_value_per_key=' || p_single_value_per_key || 
      ', p_key_description=' || p_key_description || 
      ', p_value_count=' || p_value_count);
 
    OPEN l_result FOR
    SELECT
      property_keys_view.*
    FROM
      property_keys_view
    WHERE (
      UPPER(group_name) LIKE '%' || UPPER(p_group_name) || '%'
      OR group_name IS NULL AND p_group_name IS NULL) 
    AND (
      UPPER(group_description) LIKE '%' || UPPER(p_group_description) || '%'
      OR group_description IS NULL AND p_group_description IS NULL)
    AND (
      UPPER(key) LIKE '%' || UPPER(p_key) || '%'
      OR key IS NULL AND p_key IS NULL)
    AND (
      UPPER(single_value_per_key) LIKE '%' || UPPER(p_single_value_per_key) || '%'
      OR single_value_per_key IS NULL AND p_single_value_per_key IS NULL)
    AND (
      UPPER(key_description) LIKE '%' || UPPER(p_key_description) || '%'
      OR key_description IS NULL AND p_key_description IS NULL) 
    AND (
      value_count = p_value_count
      OR p_value_count IS NULL) 
    ORDER BY 
      group_name, key;
 
    RETURN l_result;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('get_filtered failed');
      RAISE;
 
  END get_keys_view;

  
  /*
  */
  FUNCTION get_values_view(
    p_group_name IN VARCHAR2,
    p_group_description IN VARCHAR2,
    p_key IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_key_description IN VARCHAR2,
    p_value IN VARCHAR2,
    p_sort_order IN INTEGER
  )
  RETURN SYS_REFCURSOR 
  IS
    l_result SYS_REFCURSOR;
 
  BEGIN
    logger.entering('get_values_view');
 
    logger.fb(
      'p_group_name=' || p_group_name || 
      ', p_group_description=' || p_group_description ||
      ', p_key=' || p_key ||
      ', p_single_value_per_key=' || p_single_value_per_key || 
      ', p_key_description=' || p_key_description || 
      ', p_value=' || p_value ||
      ', p_sort_order=' || p_sort_order);
 
    OPEN l_result FOR
    SELECT
      property_values_view.*
    FROM
      property_values_view
    WHERE (
      UPPER(group_name) LIKE '%' || UPPER(p_group_name) || '%'
      OR group_name IS NULL AND p_group_name IS NULL) 
    AND (
      UPPER(group_description) LIKE '%' || UPPER(p_group_description) || '%'
      OR group_description IS NULL AND p_group_description IS NULL)
    AND (
      UPPER(key) LIKE '%' || UPPER(p_key) || '%'
      OR key IS NULL AND p_key IS NULL)
    AND (
      UPPER(single_value_per_key) LIKE '%' || UPPER(p_single_value_per_key) || '%'
      OR single_value_per_key IS NULL AND p_single_value_per_key IS NULL)
    AND (
      UPPER(key_description) LIKE '%' || UPPER(p_key_description) || '%'
      OR key_description IS NULL AND p_key_description IS NULL) 
    AND (
      UPPER(value) LIKE '%' || UPPER(p_value) || '%'
      OR value IS NULL AND p_value IS NULL) 
    AND (
      sort_order = p_sort_order
      OR p_sort_order IS NULL) 
    ORDER BY 
      group_name, key, sort_order;
 
    RETURN l_result;
 
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('get_values_view failed');
      RAISE;
 
  END get_values_view;
  
  
  /*
    Private function to return the ID of the specified group.
  */
  FUNCTION get_group_id(
    p_group_name IN VARCHAR2
  )
  RETURN INTEGER
  IS
    l_result INTEGER;
    
  BEGIN
    logger.entering('get_group_id');
    
    SELECT group_id
      INTO l_result
      FROM property_group_data
     WHERE group_name = p_group_name;
      
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('group not found');
      
      RAISE_APPLICATION_ERROR(
        group_not_found_code, 
        'Property group "' || p_group_name || '" not found');
      
  END get_group_id;

  
  /*
    Private function to return the ID of the specified key.
    
    This implementation will run 2 select statements:
      - 1 for the get_group_id call and 
      - 1 to get the key from property_key_data.
    It would be possible to get the key_id with a single query that joins 
    property_key_data and property_group_data.
    This implementation was chosen so that we can provide different messages for:
      - when the group cannot be found and
      - when the group can be found but it does not contain the specified key
  */
  FUNCTION get_key_id(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN INTEGER
  IS
    l_result INTEGER;
    -- ID of the group to which the specified key belongs
    l_group_id INTEGER;
    
  BEGIN
    logger.entering('get_key_id');

    l_group_id := get_group_id(p_group_name);

    SELECT key_id
      INTO l_result
      FROM property_key_data
     WHERE group_id = l_group_id
       AND key = p_key;
      
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('key not found');
      
      RAISE_APPLICATION_ERROR(
        key_not_found_code, 
        'Property key "' || p_group_name || '#' || p_key || '" not found');
      
  END get_key_id;
  

  /*
    Creates or updates a property group called p_group_name.
  */
  PROCEDURE create_or_update_group(
    p_group_name IN VARCHAR2,
    p_description IN VARCHAR2 := NULL
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('create_or_update_group');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_description=' || p_description);
    
    MERGE INTO 
      property_group_data
    USING (
      SELECT
        p_group_name AS group_name
      FROM 
        dual
       ) data
    ON (
      property_group_data.group_name = data.group_name)
    WHEN MATCHED 
    THEN 
      UPDATE SET 
        property_group_data.group_description = p_description
    WHEN NOT MATCHED 
    THEN 
      INSERT (
        property_group_data.group_name, 
        property_group_data.group_description)
      VALUES (
        data.group_name, 
        p_description);

    COMMIT;
    
  END create_or_update_group;


  /*
    Creates or updates a property key called p_key that belongs 
    to the group called p_group_name.
  */
  PROCEDURE create_or_update_key(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_description IN VARCHAR2 := NULL,
    p_single_value_per_key IN VARCHAR2 := 'Y'
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the group to which this key should belong
    l_group_id INTEGER;
    
  BEGIN
    logger.entering('create_or_update_key');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_description=' || p_description ||
      ', p_single_value_per_key=' || p_single_value_per_key);
    
    l_group_id := get_group_id(p_group_name);
    
    -- if the key already exists, we may have to update property_value_data.
    -- lock both tables that we may affect 
    LOCK TABLE property_value_data IN EXCLUSIVE MODE NOWAIT;
    LOCK TABLE property_key_data IN EXCLUSIVE MODE NOWAIT;
    
    <<try_insert>>
    BEGIN
      logger.fb('start of try_insert');
      
      INSERT INTO property_key_data(
        group_id, key, key_description, single_value_per_key)
      VALUES(
        l_group_id, p_key, p_description, p_single_value_per_key);
      
      COMMIT;
      
      logger.exiting('create_or_update_key', 'new key created');
      -- if the insert succeeds, we're done
      RETURN;
      
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX
      THEN
        -- if the insert fails, we'll need to update the existing key
        logger.fb1('key already exists');
        
    END try_insert;
    
    /*
      If single value per key is being changed for the key, we will need to
      update any values that exist for the key. 
      If we can update single value per key, the key will have one value
      at most.
      If a value needs updating we'll need to:
        - load the value (for the key we will update) into memory,
        - delete the value from the values table,
        - update the key and
        - re-insert the value from memory (with the new single value per key).
      This is due to the non-deferrable foreign key 
      property_value_must_have_key on the values table.
    */
    <<try_update>>
    DECLARE
      -- get the ID of the key we will be updating
      l_key_id INTEGER := get_key_id(p_group_name, p_key);
      -- this will hold the property value for the key we will update
      l_value_data_row property_value_data%ROWTYPE;
      -- flag to indicate values will need updating 
      l_values_need_update BOOLEAN := FALSE;
      
    BEGIN
      logger.fb('start of try_update');
      
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
         WHERE key_id = l_key_id;
        
        logger.fb('found one value');
        
        l_values_need_update := 
          l_value_data_row.single_value_per_key != p_single_value_per_key;
        
      EXCEPTION
        WHEN TOO_MANY_ROWS
        THEN
          logger.fb('found more than one value');
          -- this is only a problem if we're changing to single value per key
          IF (p_single_value_per_key = 'Y')
          THEN
            RAISE_APPLICATION_ERROR(
              -20000,
              'You cannot change ' || p_group_name || '#' || p_key || 
              ' to single value per key as multiple values exist for this key');
              
          END IF;
           
        WHEN NO_DATA_FOUND
        THEN
          logger.fb('no values found');
          
          l_values_need_update := FALSE;
          
      END get_value;
      
      -- if we need to update any values, we'll delete them now
      IF (l_values_need_update)
      THEN
        logger.fb('values need update');
        
        -- update single value per key for the value that we'll re-insert
        l_value_data_row.single_value_per_key := p_single_value_per_key;
        
        -- delete the value
        DELETE FROM property_value_data
        WHERE key_id = l_key_id;
        
        logger.fb(SQL%ROWCOUNT || ' values deleted');
        
      END IF; -- End of IF (l_values_need_update)
      
      -- update the key
      UPDATE property_key_data
         SET key = p_key,
             key_description = p_description,
             single_value_per_key = p_single_value_per_key
       WHERE key_id = l_key_id;
      
      logger.fb('key updated');
      
      -- if we "updated" a value, re-insert it now
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
      
      COMMIT;
      
      logger.exiting('create_or_update_key', 'key updated');
      
    END try_update;
    
  END create_or_update_key;
  
  
  /*
    Removes a group, all of the keys that belong to the group and all values 
  */
  PROCEDURE remove_group(
    p_group_name IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the group which we will remove
    l_group_id INTEGER;
    
  BEGIN
    logger.entering('remove_group');
    
    logger.fb(
      'p_group_name=' || p_group_name);
    
    l_group_id := get_group_id(p_group_name);
    
    DELETE FROM property_group_data
    WHERE group_id = l_group_id;
    
    COMMIT;
    
    logger.exiting('remove_group', SQL%ROWCOUNT || ' rows deleted');
    
  END remove_group;
  
  
  /*
    Removes all keys that belong to the specified group and all values 
    of the keys removed.
  */
  PROCEDURE remove_keys(
    p_group_name IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the group who's keys we will remove
    l_group_id INTEGER;
    
  BEGIN
    logger.entering('remove_keys');
    
    logger.fb(
      'p_group_name=' || p_group_name);
    
    l_group_id := get_group_id(p_group_name);
    
    DELETE FROM property_key_data
    WHERE group_id = l_group_id;
    
    COMMIT;
    
    logger.exiting('remove_keys', SQL%ROWCOUNT || ' rows deleted');
    
  END remove_keys;
  
  
  /*
    Removes a key an all of it's values.
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
  */
  PROCEDURE remove_key(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the key which we will remove
    l_key_id INTEGER;
    
  BEGIN
    logger.entering('remove_key');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);
    
    l_key_id := get_key_id(p_group_name, p_key);
    
    DELETE FROM property_key_data
    WHERE key_id = l_key_id;
    
    COMMIT;
    
    logger.exiting('remove_key', SQL%ROWCOUNT || ' rows deleted');
    
  END remove_key;
  
  
  /*
    Removes all values of the specified key.
    
    Parameters:
      p_group_name 
        This must be a property group name.
        
      p_key
        This must be a key that belongs to the specified group.
  */
  PROCEDURE remove_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the key who's values we will remove
    l_key_id INTEGER;
    
  BEGIN
    logger.entering('remove_values');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);
    
    l_key_id := get_key_id(p_group_name, p_key);
    
    DELETE FROM property_value_data
    WHERE key_id = l_key_id;
    
    COMMIT;
    
    logger.exiting('remove_values', SQL%ROWCOUNT || ' rows deleted');
    
  END remove_values;
  
  
  /*
    Sets a property value.
  */
  PROCEDURE set_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the property that we will set
    l_key_id INTEGER;
    
  BEGIN
    logger.entering('set_value');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_value=' || p_value);
    
    l_key_id := get_key_id(p_group_name, p_key);
    
    MERGE INTO 
      property_value_data
    USING (
      SELECT
        l_key_id AS key_id
      FROM 
        dual) data
    ON (
      property_value_data.key_id = data.key_id)
    WHEN MATCHED 
    THEN 
      UPDATE SET 
        property_value_data.value = p_value,
        property_value_data.single_value_per_key = 'Y'
    WHEN NOT MATCHED 
    THEN 
      INSERT (
        property_value_data.key_id,
        property_value_data.value,
        property_value_data.single_value_per_key)
      VALUES (
        data.key_id, 
        p_value,
        'Y');
    
    COMMIT;
  
  EXCEPTION
    WHEN parent_key_not_found
    THEN
      -- we'll only see this if the specified key has 
      -- single_value_per_key set to 'N'
      RAISE_APPLICATION_ERROR(
        -20000, 
        'Property "' || p_group_name || '#' || p_key || 
        '" does not use single value per key');
  
  END set_value;
  
  
  /*
    Adds a property value.
  */
  PROCEDURE add_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2,
    p_sort_order IN INTEGER := NULL
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- ID of the property that we will set
    l_key_id INTEGER;
    
  BEGIN
    logger.entering('add_value');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_value=' || p_value ||
      ', p_sort_order=' || p_sort_order);
    
    l_key_id := get_key_id(p_group_name, p_key);
    
    INSERT INTO property_value_data(
      key_id, value, sort_order, single_value_per_key)
    VALUES(
      l_key_id, p_value, p_sort_order, 'N');
        
    COMMIT;
    
  EXCEPTION
    WHEN parent_key_not_found
    THEN
      -- we'll only see this if the specified key has 
      -- single_value_per_key set to 'Y'
      RAISE_APPLICATION_ERROR(
        -20000, 
        'Property "' || p_group_name || '#' || p_key || 
        '" uses single value per key');
    
  END add_value;
  
  
  /*
    Returns the value of the specified property.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    -- holds the result
    l_result VARCHAR2(32767);
    -- ID of the key who's value we will return
    l_key_id INTEGER;
    
  BEGIN
    logger.entering('get_value');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);
    
    l_key_id := get_key_id(p_group_name, p_key);
    
    SELECT value
      INTO l_result
      FROM property_value_data
     WHERE key_id = l_key_id;
    
    logger.exiting('get_value', l_result);
    
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('Property not found');
      
      RAISE_APPLICATION_ERROR(
        value_not_found_code, 
        'Property "' || p_group_name || '#' || p_key || '" not found');
      
    WHEN TOO_MANY_ROWS
    THEN
      logger.fb('Multiple values found');
      
      RAISE_APPLICATION_ERROR(
        too_many_values_code, 
        'Property "' || p_group_name || '#' || p_key || '" has multiple values');
    
  END get_value;
  
  
  /*
    Returns the value of the specified property or the specified default if
    the property does not exist.
    
    Note: 
      A property does not exist if:
        The group does not exist,
        The key does not exists or
        No value has been set.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_default IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    -- holds the result
    l_result VARCHAR2(32767);
    
  BEGIN
    logger.entering('get_value');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_default=' || p_default);
    
    SELECT value
      INTO l_result
      FROM property_values_view
     WHERE group_name = p_group_name
       AND key = p_key;
    
    logger.exiting('get_value', l_result);
    
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('Property not found. will return default');
      
      logger.exiting('get_value', p_default);
      
      RETURN p_default;
      
    WHEN TOO_MANY_ROWS
    THEN
      logger.fb('Multiple values found');
      
      RAISE_APPLICATION_ERROR(
        too_many_values_code, 
        'Property "' || p_group_name || '#' || p_key || '" has multiple values');
    
  END get_value;
  
  
  /*
    Returns the value of the first property that has a value.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_keys IN varchar_table
  )
  RETURN VARCHAR2
  IS
    -- make a copy of keys so we can edit the collection
    l_keys varchar_table := p_keys;
    
    -- Handles the situation where either a key of a value could not be found
    PROCEDURE key_or_value_not_found
    IS
    BEGIN
      IF (l_keys.FIRST = l_keys.LAST)
      THEN
        -- if we just tried the last key, we've failed to get the value
        logger.fb('Property not found (multiple keys)');
      
        RAISE_APPLICATION_ERROR(
          value_not_found_code, 
          'Last property "' || p_group_name || '#' || l_keys(l_keys.FIRST) || 
          '" not found');
      
      ELSE
        -- otherwise, remove the first key so the next can be tried
        l_keys.DELETE(l_keys.FIRST);
        
      END IF;
      
    END key_or_value_not_found;
    
  BEGIN
    logger.entering('get_value');
    
    logger.fb(
      'p_group_name=' || p_group_name);
    
    -- check p_keys is not null
    IF (p_keys IS NULL)
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 
        'p_keys is null (has not been initialized)');
        
    END IF;
    
    -- check p_keys contains at least one key
    IF (p_keys.FIRST IS NULL)
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 
        'p_keys contains no keys');
        
    END IF;
    
    -- keys_loop will exit in one of 2 ways:
    --   1) get_value(VARCHAR2, VARCHAR2) succeeds and we return a result
    --   2) key_or_value_not_found raises an exception
    <<keys_loop>>
    LOOP
      BEGIN
        -- if this get_value call works, we've found the value
        RETURN get_value(p_group_name, l_keys(l_keys.FIRST));
        
      EXCEPTION
        WHEN key_not_found
        THEN
          key_or_value_not_found;
          
        WHEN value_not_found
        THEN
          key_or_value_not_found;
          
      END;
      
    END LOOP keys_loop;
    
  END get_value;
  
  
  /*
    Returns the value of the first property that has a value or 
    p_default if none of the properties exist.
  */
  FUNCTION get_value(
    p_group_name IN VARCHAR2,
    p_keys IN varchar_table,
    p_default IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
  BEGIN
    logger.entering('get_value');
    
    IF (p_keys IS NULL)
    THEN
      logger.fb('p_keys IS NULL');
      
      RETURN p_default;
      
    END IF;
    
    IF (p_keys.FIRST IS NULL)
    THEN
      logger.fb('p_keys is empty');
      
      RETURN p_default;
      
    END IF;
    
    RETURN get_value(p_group_name, p_keys);
    
  EXCEPTION
    WHEN group_not_found
    THEN
      RETURN p_default;
      
    WHEN value_not_found
    THEN
      RETURN p_default;
    
  END get_value;
  
  
  /*
    Returns all values for the specified property.
  */
  FUNCTION get_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN varchar_table
  IS
    l_result varchar_table;
    -- ID of the key who's values we will return
    l_key_id INTEGER;
    
  BEGIN
    logger.entering('get_values');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);
    
    l_key_id := get_key_id(p_group_name, p_key);
    
    SELECT value
      BULK COLLECT INTO l_result
      FROM property_value_data
     WHERE key_id = l_key_id
     ORDER BY sort_order;
     
    RETURN l_result;
    
  END get_values;

  
  /*
    Returns all values for the specified property or
    the values in p_default if the property does not exist.
  */
  FUNCTION get_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_default IN varchar_table
  )
  RETURN varchar_table
  IS
    -- handles the situation when a group or a key cannot be found.
    -- returns a cursor containing the default values
    FUNCTION group_or_key_not_found
    RETURN varchar_table
    IS
      l_result varchar_table;
      
    BEGIN
      logger.entering('group_or_key_not_found');
      
      SELECT COLUMN_VALUE AS value
        BULK COLLECT INTO l_result
        FROM TABLE(CAST(p_default AS varchar_table));
      
      RETURN l_result;
      
    END group_or_key_not_found;
    
  BEGIN
    logger.entering('get_values');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);
    
    RETURN get_values(p_group_name, p_key);
    
  EXCEPTION
    WHEN group_not_found
    THEN
      RETURN group_or_key_not_found;
    
    WHEN key_not_found
    THEN
      RETURN group_or_key_not_found;
    
  END get_values;
  
  
END property_manager;
/
