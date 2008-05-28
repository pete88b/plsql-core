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

CREATE OR REPLACE PACKAGE properties
IS

  /*
    Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  /*
    This package provides functionality for managing and retrieving properties.
    
    Properties are organised into property groups. 
    Property groups can have any number of keys. 
    Every key will have at least one value.
    
    A property is identified by it's property group and key.
    A property can have more than one value (see below).
    
    If the property group is constrained to use a single value per key, i.e.
    get_single_value_per_key('<group name>') returns yes, every key will have
    a single value.
    If the property group is not constrained to use a single value per key, i.e.
    get_single_value_per_key('<group name>') returns no, every key will have
    at least one value. In this case there is no limit to the number of values
    per key.
    
    If the property group is locked, i.e. get_locked('<group name>') returns yes,
    no changes can be made to the property group (except for un-locking the property
    group) and no changes can be made to it's properties.
    
    Property group names are case sensitive. NULL is NOT a valid group name.
    Keys are case sensitive. NULL is NOT a valid value for a key.
    Values are case sensitive. NULL is a valid value for a value.
    When comparing property values, NULL is considered to be equal to NULL.
    
    None of the modules in this package affect the transaction from which they are called.
    
    Example of use:
    
    The following PL/SQL block uses get_group_names, get_keys, get_property and
    get_values to output all properties and their values.
    
    DECLARE
      l_group_names properties.group_names_type;
      l_keys properties.keys_type;
      l_values properties.values_type;
    
    BEGIN
      properties.get_group_names(l_group_names);
      
      IF (l_group_names.FIRST IS NULL)
      THEN
        DBMS_OUTPUT.PUT_LINE('No groups found');
        RETURN;
        
      END IF;
      
      FOR i IN l_group_names.FIRST .. l_group_names.LAST
      LOOP
        properties.get_keys(l_group_names(i), l_keys);
      
        IF (l_keys.FIRST IS NULL)
        THEN
          DBMS_OUTPUT.PUT_LINE('No keys for group ' || l_group_names(i));
        
        ELSE
          FOR j IN l_keys.FIRST .. l_keys.LAST
          LOOP
            IF (properties.get_single_value_per_key(l_group_names(i)) = properties.yes)
            THEN
              DBMS_OUTPUT.PUT_LINE(
                l_group_names(i) || ':' || l_keys(j) || '=' ||
                properties.get_property(l_group_names(i), l_keys(j)));
            
            ELSE
              properties.get_values(l_group_names(i), l_keys(j), l_values);
            
              FOR k IN l_values.FIRST .. l_values.LAST
              LOOP
                DBMS_OUTPUT.PUT_LINE(l_group_names(i) || ':' || l_keys(j) || '=' || l_values(k));
                
              END LOOP;
            
            END IF;
          
          END LOOP;
        
        END IF;
      
      END LOOP;
    
    END;
    
  */
  
  /*
    Returns yes if a property group named p_group_name exists, no otherwise.
  */
  FUNCTION group_exists(
    p_group_name IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Returns yes if a property group named p_group_name has a property with key p_key, 
    no otherwise.
  */
  FUNCTION property_exists(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Returns yes if a property group named p_group_name has a property with key p_key and
    value p_value, no otherwise.
  */
  FUNCTION property_exists(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  )
  RETURN VARCHAR2;

  /*
    Returns yes if upper(p_data) = yes or no if upper(p_data) = no.
    An exception is raised if upper(p_data) is not yes or no.
  */
  FUNCTION format_no_or_yes(
    p_data IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Creates a property group named p_group_name.
    
    An exception is raised if p_group_name is already used as a property group name.
    An exception is raised if p_single_value_per_key is not yes or no.
  */
  PROCEDURE create_property_group(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2 := constants.yes,
    p_description IN VARCHAR2 := NULL
  );
  
  /*
    Sets the description of a group.
    
    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE set_group_description(
    p_group_name IN VARCHAR2,
    p_description IN VARCHAR2
  );
  
  /*
    Removes a property group and all of it's properties.
    
    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE remove_property_group(
    p_group_name IN VARCHAR2
  );
  
  /*
    Returns yes if the specified group is constrained to use a single value per key,
    no otherwise.
    An exception is raised if no group with name p_group_name can be found.
  */
  FUNCTION get_single_value_per_key(
    p_group_name IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Use a value of yes for p_single_value_per_key to constrain this group to use 
    a single value per key.
    Use a value of no for p_single_value_per_key to allow this group to use 
    multiple values per key.
    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if the group is locked.
    An exception is raised if p_single_value_per_key is not yes or no.
  */
  PROCEDURE set_single_value_per_key(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2
  );
  
  /*
    Returns yes if the specified group is locked, no otherwise.
    An exception is raised if no group with name p_group_name can be found.
  */
  FUNCTION get_locked(
    p_group_name IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Sets the locked status of this group. 
  
    Use a value of constants.yes for p_locked to lock this group.
    Use a value of constants.no for p_locked to un-lock this group.

    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if p_single_value_per_key is not yes or no.
  */
  PROCEDURE set_locked(
    p_group_name IN VARCHAR2,
    p_locked IN VARCHAR2
  );
  
  /*
    Sets a property.
    
    If the property does not exist it will be created with a value of p_value.
    
    If the property exists and the group is constrained to use a single value 
    per key, the property value is updated to p_value. 
    
    If the property is updated and p_description is not null, the property
    description is updated. 
    To set a property description to null, use update_property_description.
    
    If the property is updated and p_sort_order is not null, the property
    sort order is updated. 
    To set a property sort order to null, use update_property_sort_order.
    
    
    If the property exists and the group is not constrained to use a single value 
    per key, the specified value is added to the property.
    
    The sort order is used (by get_values and get_properties) to determine the
    order of values that use the same key. 
    It doesn't make sense to set the sort order for values of a single value 
    group, but doing so will not raise an exception.
    
    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE set_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2,
    p_description IN VARCHAR2 := NULL,
    p_sort_order IN VARCHAR2 := NULL
  );
  
  /*
    Updates the description of a property. 
    All values of the property will be updated.
    
    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE update_property_description(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_description IN VARCHAR2
  );
  
  /*
    Updates the sort order of a property value.
    All values matching the specified group name, key and value will be updated.
    
    An exception is raised if no group with name p_group_name can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE update_property_sort_order(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2,
    p_sort_order IN VARCHAR2
  );
  
  /*
    Removes the specified property and all of it's values.
    
    An exception is raised if a no property with group name p_group_name and key p_key
    can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE remove_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  );
  
  /*
    Removes the specified property.
    
    An exception is raised if a no property with group name p_group_name, key p_key
    and value p_value can be found.
    An exception is raised if the group is locked.
  */
  PROCEDURE remove_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  );
  
  /*
    Returns all group names.
  */ 
  PROCEDURE get_group_names(
    p_group_names OUT types.max_varchar2_table
  );
  
  /*
    Returns all keys for the specified group.
    An exception is raised if no group with name p_group_name can be found.
  */
  PROCEDURE get_keys(
    p_group_name IN VARCHAR2,
    p_keys OUT types.max_varchar2_table
  );
  
  /*
    Returns the value of the specified property.
    
    An exception is raised if a no property with group name p_group_name and 
    key p_key can be found.
    An exception is raised if the property has multiple values.
  */
  FUNCTION get_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Returns the value of the specified property or the specified default if
    the property does not exist.
    
    An exception is raised if the property has multiple values.
  */
  FUNCTION get_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_default IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  /*
    Returns all values of the specified property.
    
    An exception is raised if a no property with group name p_group_name and key p_key
    can be found.
  */
  PROCEDURE get_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_values OUT types.max_varchar2_table
  );
  
  /*
    Returns all properties in the specified property group.
    
    The ref cursor will contain colums key and value.
    Results will be sorted by key hen value.
    
    An exception is raised if no group with name p_group_name can be found.
  */
  PROCEDURE get_properties(
    p_group_name IN VARCHAR2,
    p_ref_cursor OUT SYS_REFCURSOR
  );
  
END properties;
/
CREATE OR REPLACE PACKAGE BODY properties
IS

  /*
    Private procedure that raises an exception using p_msg if p_condition 
    is not true.
  */
  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_msg IN VARCHAR2)
  IS
  BEGIN
    logger.entering('assert');
    
    IF (NOT NVL(p_condition, FALSE))
    THEN
      RAISE_APPLICATION_ERROR(-20000, p_msg);

    END IF;

  END assert;
  
  /*
    Private procedure that raises an exception if the specified group is locked.
  */
  PROCEDURE assert_group_not_locked(
    p_group_name IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('assert_group_not_locked');
    
    assert(
      get_locked(p_group_name) = constants.no,
      'Property group "' || p_group_name || '" is locked');
      
  END assert_group_not_locked;
  
  /*
    Private procedure that should be called when tasks must not be performed 
    concurrently for the same property group.
    This procedure locks the row in properties_groups for the specified group. 
    It is the callers responsibility to release the lock - i.e. end the transaction.
  */
  PROCEDURE serialize_on_group(
    p_group_name IN VARCHAR2
  )
  IS
    l_dummy INTEGER(1);
    
  BEGIN
    logger.entering('serialize_on_group');
    
    SELECT NULL
      INTO l_dummy
      FROM property_groups_data
     WHERE group_name = p_group_name
       FOR UPDATE;
      
  END serialize_on_group;
  
  /*
    Private procedure to raise an exception to indicate that a group could not 
    be found.
  */
  PROCEDURE raise_group_not_found(
    p_group_name IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('raise_group_not_found');
    
    RAISE_APPLICATION_ERROR(
      -20000,
      'Property group "' || p_group_name || '" not found');
      
  END raise_group_not_found;
  
  /*
    Returns yes if a property group named p_group_name exists, no otherwise.
  */
  FUNCTION group_exists(
    p_group_name IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_dummy INTEGER;
    
  BEGIN
    logger.entering('group_exists');
    
    logger.fb(
      'p_group_name=' || p_group_name);
    
    SELECT NULL
      INTO l_dummy
      FROM property_groups_data
     WHERE group_name = p_group_name;
    
    logger.fb('returning ' || constants.yes);
    
    RETURN constants.yes;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('returning ' || constants.no);
      
      RETURN constants.no;
    
  END group_exists;
  
  /*
    Private procedure that raises an exception if the specified group does 
    not exist.
  */
  PROCEDURE assert_group_exists(
    p_group_name IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('assert_group_exists');
    
    IF (group_exists(p_group_name) = constants.no)
    THEN
      raise_group_not_found(p_group_name);
      
    END IF;
    
  END assert_group_exists;
  
  /*
    Returns yes if a property group named p_group_name has a property with key 
    p_key, no otherwise.
  */
  FUNCTION property_exists(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_dummy INTEGER;
    
  BEGIN
    logger.entering('property_exists (1)');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);
    
    -- The predicate ROWNUM < 2 is needed as some properties may have multiple 
    -- values and we don't want to have to handle TOO_MANY_ROWS
    SELECT NULL
      INTO l_dummy
      FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key
       AND ROWNUM < 2;
    
    logger.fb('returning ' || constants.yes);
    
    RETURN constants.yes;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('returning ' || constants.no);
      
      RETURN constants.no;
    
  END property_exists;
  
  /*
    Private procedure that raises an exception if the specified property does 
    not exist.
  */
  PROCEDURE assert_property_exists(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('assert_property_exists (1)');
    
    assert(
      property_exists(p_group_name, p_key) = constants.yes,
      'Property not found. Property group name=' || p_group_name ||
      ', key=' || p_key);
    
  END assert_property_exists;

  /*
    Returns yes if a property group named p_group_name has a property with 
    key p_key and value p_value, no otherwise.
  */
  FUNCTION property_exists(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_dummy INTEGER;
    
  BEGIN
    logger.entering('property_exists (2)');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_value=' || p_value);
    
    -- Note: value can be NULL
    SELECT NULL
      INTO l_dummy
      FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key
       AND ((value = p_value) OR
           value IS NULL AND p_value IS NULL)
       AND ROWNUM < 2;
    
    logger.fb('returning ' || constants.yes);
    
    RETURN constants.yes;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('returning ' || constants.no);
      
      RETURN constants.no;
    
  END property_exists;
  
  /*
    Private procedure that raises an exception if the specified property 
    does not exist.
  */
  PROCEDURE assert_property_exists(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('assert_property_exists (2)');
    
    assert(
      property_exists(p_group_name, p_key, p_value) = constants.yes,
      'Property not found. Property group name=' || p_group_name ||
      ', key=' || p_key || ', value=' || p_value);
    
  END assert_property_exists;

  /*
    Returns yes if upper(p_data) = yes or no if upper(p_data) = no.
    An exception is raised if upper(p_data) is not yes or no.
  */
  FUNCTION format_no_or_yes(
    p_data IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
  BEGIN
    logger.entering('format_no_or_yes');
    
    logger.fb(
      'p_data=' || p_data);
    
    assert(
      p_data IS NOT NULL AND UPPER(p_data) IN (constants.yes, constants.no),
      'Value of constants.yes or constants.no expected (case ignored) but value was "' || p_data || '"');
    
    RETURN UPPER(p_data);
    
  END format_no_or_yes;
  
  /*
    Creates a property group named p_group_name.
  */
  PROCEDURE create_property_group(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2 := constants.yes,
    p_description IN VARCHAR2 := NULL
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('create_property_group');
    
    logger.fb(
      'p_group_name=' || p_group_name || 
      ', p_single_value_per_key=' || p_single_value_per_key ||
      ', p_description=' || p_description);
    
    assert(
      group_exists(p_group_name) = constants.no,
      'Failed to create property group as group "' || p_group_name || '" already exists');
    
    INSERT INTO property_groups_data
      (group_name, single_value_per_key, group_description)
    VALUES
      (p_group_name, format_no_or_yes(p_single_value_per_key), p_description);
      
    COMMIT;
    
    logger.fb('Property group created.');
    
  END create_property_group;
  
  /*
    Sets the description of the property group named p_group_name.
  */
  PROCEDURE set_group_description(
    p_group_name IN VARCHAR2,
    p_description IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('set_group_description');
    
    logger.fb(
      'p_group_name=' || p_group_name || 
      ', p_description=' || p_description);
    
    -- Note: assert_group_not_locked makes sure that the group exists
    assert_group_not_locked(p_group_name);
    
    UPDATE property_groups_data
       SET group_description = p_description
     WHERE group_name = p_group_name;
      
    COMMIT;
    
    logger.fb('Group description updated');

  END set_group_description;
  
  /*
    Removes a property group and all of it's properties.
  */
  PROCEDURE remove_property_group(
    p_group_name IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('remove_property_group');

    logger.fb(
      'p_group_name=' || p_group_name);

    -- Note: assert_group_not_locked makes sure that the group exists
    assert_group_not_locked(p_group_name);

    DELETE FROM property_values_data
     WHERE group_name = p_group_name;

    logger.fb('properties deleted. SQL%ROWCOUNT=' || SQL%ROWCOUNT);

    DELETE FROM property_groups_data
     WHERE group_name = p_group_name;
    
    logger.fb('properties group deleted. SQL%ROWCOUNT=' || SQL%ROWCOUNT);
    
    COMMIT;
    
  END remove_property_group;
  
  /*
    Returns yes if the specified group is constrained to use a single value per key,
    no otherwise.
    An exception is raised if no group with name p_group_name can be found.
  */
  FUNCTION get_single_value_per_key(
    p_group_name IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_result property_groups_data.single_value_per_key%TYPE;
    
  BEGIN
    logger.entering('get_single_value_per_key');

    logger.fb(
      'p_group_name=' || p_group_name);

    assert_group_exists(p_group_name);

    SELECT single_value_per_key
      INTO l_result
      FROM property_groups_data
     WHERE group_name = p_group_name;

    logger.fb('returning ' || l_result);

    RETURN l_result;
        
  END get_single_value_per_key;
  
  /*
    Sets the value of single value for key for the specified group.
  */
  PROCEDURE set_single_value_per_key(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('set_single_value_per_key');

    logger.fb(
      'p_group_name=' || p_group_name || 
      ', p_single_value_per_key=' || p_single_value_per_key);

    -- Note: assert_group_not_locked makes sure that the group exists
    assert_group_not_locked(p_group_name);

    IF (get_single_value_per_key(p_group_name) = format_no_or_yes(p_single_value_per_key))
    THEN
      logger.fb('New value for single_value_per_key is the same as the old value. Returning');
      -- Rollback to end the autonomous transaction
      ROLLBACK;
      -- return
      RETURN;
      
    END IF; -- End of IF (get_single_value_per_key(p_group_name) = p_single_value_per_key)
    
    IF (format_no_or_yes(p_single_value_per_key) = constants.yes)
    THEN
      logger.fb('Checking for multiple values per key in this group');
      
      <<check_multiple_values_per_key>>
      DECLARE
        l_dummy INTEGER(1);
        
      BEGIN
        SELECT NULL
          INTO l_dummy
          FROM (SELECT NULL
                  FROM property_values_data
                 WHERE group_name = p_group_name
                 GROUP BY group_name, key
                HAVING COUNT(*) > 1)
         WHERE ROWNUM < 2;
        
        logger.fb('Multiple values per key found. Raising exception');
        
        RAISE_APPLICATION_ERROR(
          -20000,
          'single_value_per_key cannot be set to "' || p_single_value_per_key || '" ' ||
          'for group "' || p_group_name || '" as this group containts multiple values ' ||
          'for at least one key');
        
      EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          logger.fb('No multiple values per key found');
          
      END check_multiple_values_per_key;
      
    END IF; -- End of IF (p_single_value_per_key = no_c)

    UPDATE property_groups_data
       SET single_value_per_key = format_no_or_yes(p_single_value_per_key)
     WHERE group_name = p_group_name;
    
    COMMIT;
     
    logger.fb('Update executed. SQL%ROWCOUNT=' || SQL%ROWCOUNT);
    
  END set_single_value_per_key;
  
  /*
    Returns yes if the specified group is locked, no otherwise.
    An exception is raised if no group with name p_group_name can be found.
  */
  FUNCTION get_locked(
    p_group_name IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_result VARCHAR2(1);
    
  BEGIN
    logger.entering('get_locked');

    logger.fb(
      'p_group_name=' || p_group_name);

    assert_group_exists(p_group_name);
    
    SELECT locked
      INTO l_result
      FROM property_groups_data
     WHERE group_name = p_group_name;
     
    logger.fb('returning ' || l_result);
    
    RETURN l_result;

  END get_locked;
  
  /*
    Sets the value of locked for the specified group.
  */
  PROCEDURE set_locked(
    p_group_name IN VARCHAR2,
    p_locked IN VARCHAR2
  )
  IS 
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('set_locked');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_locked=' || p_locked);

    assert_group_exists(p_group_name);
    
    UPDATE property_groups_data
       SET locked = format_no_or_yes(p_locked)
     WHERE group_name = p_group_name;
    
    COMMIT;
    
    logger.fb('Property group updated');

  END set_locked;
  
  /*
    Set a property.
  */
  PROCEDURE set_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2,
    p_description IN VARCHAR2 := NULL,
    p_sort_order IN VARCHAR2 := NULL
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('set_property');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_value=' || p_value ||
      ', p_description=' || p_description ||
      ', p_sort_order=' || p_sort_order);

    -- Note: assert_group_not_locked makes sure that the group exists
    assert_group_not_locked(p_group_name);
    
    -- Make sure only one session is setting property values for a group at any time. 
    -- If we don't do this, it would be possible for two sessions to insert 
    -- a property with the same key for a group that should not have multiple 
    -- values per key.
    serialize_on_group(p_group_name);
    
    IF (get_single_value_per_key(p_group_name) = constants.yes AND
       property_exists(p_group_name, p_key) = constants.yes)
    THEN
      UPDATE property_values_data
         SET value = p_value,
             property_description = 
               DECODE(p_description, NULL, property_description, p_description),
             sort_order = 
               DECODE(p_sort_order, NULL, sort_order, p_sort_order)
       WHERE group_name = p_group_name
         AND key = p_key;
        
      logger.fb('property updated');
      
    ELSE
      INSERT INTO property_values_data(
        group_name, key, value, property_description, sort_order)
      VALUES(
        p_group_name, p_key, p_value, p_description, p_sort_order);
        
      logger.fb('property added');
      
    END IF; -- End of IF (get_single_value_per_key(p_group_name) = yes_c) AND ...
      
    COMMIT;
    
  END set_property;
  
  /*
    Updates a property description.
  */
  PROCEDURE update_property_description(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_description IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('update_property_description');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_description=' || p_description);
    
    assert_group_not_locked(p_group_name);
    
    assert_property_exists(p_group_name, p_key);
    
    UPDATE property_values_data
       SET property_description = p_description
     WHERE group_name = p_group_name
       AND key = p_key;
    
    logger.fb('property updated. ' || SQL%ROWCOUNT || ' values updated');
    
    COMMIT;
    
  END update_property_description;
  
  /*
    Updates the sort order of a property value.
  */
  PROCEDURE update_property_sort_order(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2,
    p_sort_order IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('update_property_sort_order');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_value=' || p_value ||
      ', p_sort_order=' || p_sort_order);
      
    assert_group_not_locked(p_group_name);
    
    assert_property_exists(p_group_name, p_key, p_value);
    
    UPDATE property_values_data
       SET sort_order = p_sort_order
     WHERE group_name = p_group_name
       AND key = p_key
       AND value = p_value;
    
    logger.fb('property updated');
    
    COMMIT;
    
  END update_property_sort_order;
  
  /*
    Removes the specified property.
  */
  PROCEDURE remove_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('remove_property (1)');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);

    -- Note: assert_group_not_locked makes sure that the group exists
    assert_group_not_locked(p_group_name);

    assert_property_exists(p_group_name, p_key);
    
    DELETE FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key;
    
    COMMIT;
    
    logger.fb('Property removed. SQL%ROWCOUNT=' || SQL%ROWCOUNT);

  END remove_property;

  /*
    Removes the specified property.
  */
  PROCEDURE remove_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_value IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('remove_property (2)');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_value=' || p_value);

    -- Note: assert_group_not_locked makes sure that the group exists
    assert_group_not_locked(p_group_name);

    assert_property_exists(p_group_name, p_key, p_value);
    
    DELETE FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key
       AND ((value = p_value) OR
           value IS NULL AND p_value IS NULL);
    
    COMMIT;
    
    logger.fb('Property removed. SQL%ROWCOUNT=' || SQL%ROWCOUNT);

  END remove_property;
  
  /*
    Returns all group names.
  */
  PROCEDURE get_group_names(
    p_group_names OUT types.max_varchar2_table
  )
  IS
  BEGIN
    logger.entering('get_group_names');

    SELECT group_name
      BULK COLLECT INTO p_group_names
      FROM property_groups_data
     ORDER BY group_name;

  END get_group_names;

  /*
    Returns all keys for the specified group.
  */
  PROCEDURE get_keys(
    p_group_name IN VARCHAR2,
    p_keys OUT types.max_varchar2_table
  )
  IS
  BEGIN
    logger.entering('get_keys');

    logger.fb(
      'p_group_name=' || p_group_name);

    assert_group_exists(p_group_name);
    
    SELECT DISTINCT key
      BULK COLLECT INTO p_keys
      FROM property_values_data
     WHERE group_name = p_group_name
     ORDER BY key;

  END get_keys;

  /*
    Returns the value of the specified property.
  */
  FUNCTION get_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_result property_values_data.value%TYPE;
    
  BEGIN
    logger.entering('get_property');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);

    assert_property_exists(p_group_name, p_key);

    SELECT value
      INTO l_result
      FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key;
       
    logger.fb('returning ' || l_result);
       
    RETURN l_result;
    
  EXCEPTION
    WHEN TOO_MANY_ROWS
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 
        'This property has more than one value. ' ||
        'Property group name=' || p_group_name || ', key=' || p_key ||
        '. Use get_values to get all values for this property or ' ||
        'remove_property so that this property has only one value');

  END get_property;
  
  /*
    Returns the value of the specified property or the specified default if 
    the property does not exist.
  */
  FUNCTION get_property(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_default IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_result property_values_data.value%TYPE;
    
  BEGIN
    logger.entering('get_property (with default)');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key ||
      ', p_default=' || p_default);

    SELECT value
      INTO l_result
      FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key;
       
    logger.fb('property found. returning ' || l_result);
       
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.fb('property not found. returning default');
      
      RETURN p_default;
    
    WHEN TOO_MANY_ROWS
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 
        'This property has more than one value. ' ||
        'Property group name=' || p_group_name || ', key=' || p_key ||
        '. Use get_values to get all values for this property or ' ||
        'remove_property so that this property has only one value');

  END get_property;

  /*
    Returns the values of the specified property.
  */
  PROCEDURE get_values(
    p_group_name IN VARCHAR2,
    p_key IN VARCHAR2,
    p_values OUT types.max_varchar2_table
  )
  IS
  BEGIN
    logger.entering('get_values');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_key=' || p_key);

    assert_property_exists(p_group_name, p_key);
    
    SELECT value
      BULK COLLECT INTO p_values
      FROM property_values_data
     WHERE group_name = p_group_name
       AND key = p_key
     ORDER BY sort_order, value;
     
  END get_values;

  /*
    Returns all properties in the specified property group.
  */
  PROCEDURE get_properties(
    p_group_name IN VARCHAR2,
    p_ref_cursor OUT SYS_REFCURSOR
  )
  IS
  BEGIN
    logger.entering('get_properties');

    logger.fb(
      'p_group_name=' || p_group_name);
      
    assert_group_exists(p_group_name);
    
    OPEN p_ref_cursor FOR 
    SELECT key, value
      FROM property_values_data
     WHERE group_name = p_group_name
     ORDER BY key, sort_order, value;
      
  END get_properties;

END properties;
/
