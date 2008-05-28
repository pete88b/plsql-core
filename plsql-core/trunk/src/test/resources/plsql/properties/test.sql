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


DECLARE
  l_loop_limit INTEGER := 9;
  
  l_group_single VARCHAR2(2000) := 'test.group.single';
  l_group_multiple VARCHAR2(2000) := 'test.group.multiple';
  
  l_key VARCHAR2(200) := 'key';
  l_key2 VARCHAR2(200) := 'key2';
  l_key3 VARCHAR2(200) := 'key3';
  l_key4 VARCHAR2(200) := 'key4';
  l_key5 VARCHAR2(200) := 'key5';
  
  l_value VARCHAR2(200) := 'value';
  l_value2 VARCHAR2(200) := 'value2';
  l_value3 VARCHAR2(200) := 'value3';
  l_value4 VARCHAR2(200) := 'value4';
  l_value5 VARCHAR2(200) := 'value5';
  
  e_assertion_error EXCEPTION;
  
  t types.max_varchar2_table;
  
  l_boolean BOOLEAN;
  l_boolean2 BOOLEAN;
  
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(s);
  END p;
  
  /*
  */
  PROCEDURE assertion_failure(
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20000, p_message);
      
  END assertion_failure;

  /*
  */
  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2  := NULL
  )
  IS
  BEGIN
    IF (p_condition IS NULL OR NOT p_condition)
    THEN
      assertion_failure(p_message || ' (assert.is_true: assertion error)');
    END IF;
         
  END assert;
  
  /*
  */
  PROCEDURE assert_no_rows(
    p_sql IN VARCHAR2,
    p_message IN VARCHAR2 := NULL
  )
  IS
    l_cursor SYS_REFCURSOR;
    l_dummy INTEGER;
    
  BEGIN
    OPEN l_cursor FOR 'SELECT NULL FROM (' || p_sql || ')';
    
    FETCH l_cursor INTO l_dummy;
    
    IF (l_cursor%FOUND)
    THEN
      assertion_failure(p_message || ' (assert.no_rows: at least one row found)');
      
    END IF;
    
  END assert_no_rows;
  
  /*
  */
  PROCEDURE assert_one_row(
    p_sql IN VARCHAR2,
    p_message IN VARCHAR2 := NULL
  )
  IS
    l_cursor SYS_REFCURSOR;
    l_dummy INTEGER;
    
  BEGIN
    OPEN l_cursor FOR 'SELECT NULL FROM (' || p_sql || ')';
    
    FETCH l_cursor INTO l_dummy;
    
    IF (l_cursor%NOTFOUND)
    THEN
      assertion_failure(p_message || ' (assert.one_row: no rows found)');
      
    END IF;
    
    FETCH l_cursor INTO l_dummy;
    
    IF (l_cursor%FOUND)
    THEN
      assertion_failure(p_message || ' (assert.one_row: more than one row found)');
      
    END IF;
    
  END assert_one_row;
  
  /*
  */
  PROCEDURE assert_raises_exception(
    p_plsql IN VARCHAR2,
    p_sqlcode IN INTEGER := NULL,
    p_sqlerrm IN VARCHAR2 := NULL,
    p_message IN VARCHAR2 := NULL
  )
  IS
  BEGIN
    EXECUTE IMMEDIATE 
      'DECLARE ' ||
      '  TYPE l_array_type IS TABLE OF VARCHAR2(32767) ' ||
      '  INDEX BY BINARY_INTEGER; ' ||
      '  l_array l_array_type; ' ||
      '  t types.max_varchar2_table; ' ||
      '  l_cur SYS_REFCURSOR; ' ||
      'BEGIN ' || 
      p_plsql || ' ' ||
      'END;';
    
    RAISE e_assertion_error;
    
  EXCEPTION
    WHEN e_assertion_error
    THEN
      assertion_failure(p_message || ' (assert.raises_exception: no exception raised)');
      
    WHEN OTHERS
    THEN
      IF (p_sqlcode IS NOT NULL AND p_sqlcode != SQLCODE)
      THEN
        assertion_failure(p_message || ' (assert.raises_exception: ' ||
          'expected sqlcode=' || p_sqlcode ||
          '. found sqlcode=' || SQLCODE || ')');
          
      END IF;
      
      IF (p_sqlerrm IS NOT NULL AND SQLERRM NOT LIKE '%' || p_sqlerrm || '%')
      THEN
        assertion_failure(p_message || ' (assert.raises_exception: ' ||
          'expected sqlerrm=' || p_sqlerrm ||
          '. found sqlerrm=' || SQLERRM || ')');

      END IF;
    
  END assert_raises_exception;
  
BEGIN
  p('Running PL/SQL test script for properties');
  p('Start time: ' || TO_CHAR(SYSDATE, 'dd-Mon-yyyy hh24:mi:ss'));
  p('');
  
  BEGIN
    properties.set_locked(l_group_single, constants.no);
    properties.remove_property_group(l_group_single);
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
  
  BEGIN
    properties.set_locked(l_group_multiple, constants.no);
    properties.remove_property_group(l_group_multiple);
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;
  END;
  
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking group_exists');
  
  assert(
    properties.group_exists(l_group_single) = constants.no,
    'group ' || l_group_single || ' should not exist');
    
  assert(
    properties.group_exists(l_group_multiple) = constants.no,
    'group ' || l_group_multiple || ' should not exist');
    
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data
     WHERE  group_name=''' || l_group_single || '''');
    
  properties.create_property_group(l_group_single);
  
  assert(
    properties.group_exists(l_group_single) = constants.yes,
    'group ' || l_group_single || ' should exist');
    
  assert(
    properties.group_exists(l_group_multiple) = constants.no,
    'group ' || l_group_multiple || ' should not exist');
    
  properties.remove_property_group(l_group_single);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert(
    properties.group_exists(l_group_single) = constants.no,
    'group ' || l_group_single || ' should not exist');
    
  assert(
    properties.group_exists(l_group_multiple) = constants.no,
    'group ' || l_group_multiple || ' should not exist');
    
  properties.create_property_group(l_group_single);
  
  assert(
    properties.group_exists(l_group_single) = constants.yes,
    'group ' || l_group_single || ' should exist');
    
  properties.set_group_description(l_group_single, 'desc');
  
  assert(
    properties.group_exists(l_group_single) = constants.yes,
    'group ' || l_group_single || ' should exist');
  
  properties.set_single_value_per_key(l_group_single, constants.no);
  
  assert(
    properties.group_exists(l_group_single) = constants.yes,
    'group ' || l_group_single || ' should exist');
  
  properties.remove_property_group(l_group_single);
    
  assert(
    properties.group_exists(l_group_single) = constants.no,
    'group ' || l_group_single || ' should not exist');
    
  p('group_exists: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking property_exists');
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property ' || l_group_single || '#' || l_key || ' should not exist');
    
  properties.create_property_group(l_group_single); 
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property ' || l_group_single || '#' || l_key || ' should not exist');
    
  properties.set_property(l_group_single, l_key, l_value);
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.yes,
    'property ' || l_group_single || '#' || l_key || ' should exist');
  
  properties.remove_property(l_group_single, l_key);
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property ' || l_group_single || '#' || l_key || ' should not exist');
  
  properties.remove_property_group(l_group_single);
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property ' || l_group_single || '#' || l_key || ' should not exist');
    
  properties.create_property_group(l_group_single); 
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key, i);
    assert(
      properties.property_exists(l_group_single, l_key) = constants.yes,
      'property ' || l_group_single || '#' || l_key || ' should exist');
      
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property ' || l_group_single || '#' || l_key || ' should not exist');
  
  p('property_exists: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking property_exists (part 2)');
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property ' || l_group_single || '#' || l_key || '#' || l_value || ' should not exist');
    
  properties.create_property_group(l_group_single); 
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property ' || l_group_single || '#' || l_key || '#' || l_value || ' should not exist');
        
  properties.set_property(l_group_single, l_key, l_value);
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.yes,
    'property ' || l_group_single || '#' || l_key || '#' || l_value || ' should not exist');
  
  properties.remove_property(l_group_single, l_key);
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property ' || l_group_single || '#' || l_key || '#' || l_value || ' should not exist');
  
  properties.remove_property_group(l_group_single);
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property ' || l_group_single || '#' || l_key || '#' || l_value || ' should not exist');
    
  properties.create_property_group(l_group_single); 
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key, i);
    assert(
      properties.property_exists(l_group_single, l_key, i) = constants.yes,
      'property ' || l_group_single || '#' || l_key || '#' || i || ' should exist');
      
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property ' || l_group_single || '#' || l_key || '#' || l_value || ' should not exist');
  
  p('property_exists (part 2): ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking format_no_or_yes');
  
  assert(
    properties.format_no_or_yes('y') = constants.yes,
    'expected format_no_or_yes y -> yes_C');
  
  assert(
    properties.format_no_or_yes('Y') = constants.yes,
    'expected format_no_or_yes Y -> yes_C');
    
  assert(
    properties.format_no_or_yes('n') = constants.no,
    'expected format_no_or_yes n -> no_C');
    
  assert(
    properties.format_no_or_yes('N') = constants.no,
    'expected format_no_or_yes N -> no_C');
  
  assert_raises_exception(
    'l_array(0) := properties.format_no_or_yes(NULL);',
    -20000,
    'Value of constants.yes or constants.no expected',
    '');
  
  FOR i IN 32 .. 126
  LOOP
    IF (CHR(i) IN ('y', 'Y', 'n', 'N'))
    THEN
      NULL; -- skipping y, Y, n or N
    ELSE
      assert_raises_exception(
        'l_array(0) := properties.format_no_or_yes(''' || REPLACE(CHR(i), '''', '''''') || ''');',
        -20000,
        'Value of constants.yes or constants.no expected',
        '');
    END IF;
  END LOOP;
  
  p('format_no_or_yes: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking create_property_group');
  
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key=''' || constants.yes || '''
     AND    group_description IS NULL');
  
  assert(
    properties.group_exists(l_group_single) = constants.yes,
    'group ' || l_group_single || ' should exist');
    
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.yes,
    'group ' || l_group_single || ' should be single value pre key');
  
  assert_raises_exception(
    'properties.create_property_group(''' || l_group_single || ''');',
    -20000,
    'Failed to create%already exists',
    '');
  
  properties.remove_property_group(l_group_single);
  
  properties.create_property_group(
    l_group_multiple, 
    constants.no);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    single_value_per_key=''' || constants.no || '''
     AND    group_description IS NULL');
  
  assert(
    properties.get_single_value_per_key(l_group_multiple) = constants.no,
    'group ' || l_group_multiple || ' should not be single value pre key');
  
  assert_raises_exception(
    'properties.create_property_group(''' || l_group_multiple || ''');',
    -20000,
    'Failed to create%already exists',
    '');
    
  assert_raises_exception(
    'properties.create_property_group(''' || l_group_multiple || ''');',
    -20000,
    'Failed to create%already exists',
    '');
    
  properties.remove_property_group(l_group_multiple);
  
  properties.create_property_group(
    l_group_multiple, 
    constants.no,
    'desc');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    single_value_per_key=''' || constants.no || '''
     AND    group_description = ''desc''');
  
  properties.remove_property_group(l_group_multiple);
  
  p('create_property_group: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking set_group_description');
  
  assert_raises_exception(
    'properties.set_group_description(''' || l_group_single || ''', ''desc'');',
    -20000,
    'group%not found');
    
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description IS NULL');
  
  properties.set_group_description(l_group_single, 'desc');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description = ''desc''');
     
  properties.set_group_description(l_group_single, 'desc2x');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description = ''desc2x''');
  
  properties.set_group_description(l_group_single, '');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description IS NULL');
     
  properties.remove_property_group(l_group_single);
  
  assert_raises_exception(
    'properties.set_group_description(''' || l_group_single || ''', ''desc'');',
    -20000,
    'group%not found');
  
  p('set_group_description: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking remove_property_group');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'properties.remove_property_group(''' || l_group_single || ''');',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description IS NULL');
 
  properties.remove_property_group(l_group_single);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'properties.remove_property_group(''' || l_group_single || ''');',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description IS NULL');
     
  assert(
    properties.get_locked(l_group_single) = constants.no,
    'new groups should not be locked');
     
  properties.set_locked(l_group_single, constants.yes);
  
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked');
    
  assert_raises_exception(
    'properties.remove_property_group(''' || l_group_single || ''');',
    -20000,
    'group%is locked');
    
  properties.set_locked(l_group_single, constants.no);
    
  properties.remove_property_group(l_group_single);
  
  p('remove_property_group: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_single_value_per_key');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'l_array(0) := properties.get_single_value_per_key(''' || l_group_single || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.yes || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.yes,
    l_group_single || ' should be single value per key');
    
  properties.set_single_value_per_key(l_group_single, constants.no);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.no || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.no,
    l_group_single || ' should not be single value per key');
  
  properties.set_single_value_per_key(l_group_single, constants.no);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.no || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.no,
    l_group_single || ' should not be single value per key');
    
  properties.set_single_value_per_key(l_group_single, constants.yes);
    
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.yes || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.yes,
    l_group_single || ' should be single value per key');
  
  properties.remove_property_group(l_group_single);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'l_array(0) := properties.get_single_value_per_key(''' || l_group_single || ''');',
    -20000,
    'Property group%not found');
  
  p('get_single_value_per_key: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking set_single_value_per_key');
  
  assert_raises_exception(
    'properties.set_single_value_per_key(''' || l_group_single || ''', ''' || constants.yes || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.yes || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.yes,
    l_group_single || ' should be single value per key');
    
  properties.set_single_value_per_key(l_group_single, constants.no);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.no || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.no,
    l_group_single || ' should not be single value per key');
  
  properties.set_single_value_per_key(l_group_single, constants.no);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.no || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.no,
    l_group_single || ' should not be single value per key');
    
  properties.set_single_value_per_key(l_group_single, constants.yes);
    
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    single_value_per_key = ''' || constants.yes || '''');
     
  assert(
    properties.get_single_value_per_key(l_group_single) = constants.yes,
    l_group_single || ' should be single value per key');
  
  properties.remove_property_group(l_group_single);
  
  assert_raises_exception(
    'properties.set_single_value_per_key(''' || l_group_single || ''', ''' || constants.yes || ''');',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    group_description IS NULL');
     
  assert(
    properties.get_locked(l_group_single) = constants.no,
    'new groups should not be locked');
     
  properties.set_locked(l_group_single, constants.yes);
  
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked');
    
  assert_raises_exception(
    'properties.set_single_value_per_key(''' || l_group_single || ''', ''' || constants.yes || ''');',
    -20000,
    'group%is locked');
    
  properties.set_locked(l_group_single, constants.no);
    
  properties.remove_property_group(l_group_single);
  
  p('set_single_value_per_key: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_locked');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'l_array(0) := properties.get_locked(''' || l_group_single || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.no || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.no,
    l_group_single || ' should not be locked'); 
    
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  properties.set_locked(l_group_single, constants.no);
    
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.no || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.no,
    l_group_single || ' should not be locked'); 
    
  properties.remove_property_group(l_group_single);   
    
  assert_raises_exception(
    'l_array(0) := properties.get_locked(''' || l_group_single || ''');',
    -20000,
    'Property group%not found');
    
  p('get_locked: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking set_locked');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'properties.set_locked(''' || l_group_single || ''', ''' || constants.yes || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_single);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.no || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.no,
    l_group_single || ' should not be locked'); 
    
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  properties.set_locked(l_group_single, constants.no);
    
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.no || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.no,
    l_group_single || ' should not be locked'); 
    
  properties.remove_property_group(l_group_single);   
    
  assert_raises_exception(
    'properties.set_locked(''' || l_group_single || ''', ''' || constants.yes || ''');',
    -20000,
    'Property group%not found');
  
  p('set_locked: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking set_property');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  assert_raises_exception(
    'properties.set_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_single);
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  assert_raises_exception(
    'properties.set_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_single, constants.no);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''');
  
  properties.set_property(l_group_single, l_key, l_value, 'testDesc');
  
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key, l_value || i);
    
    assert_one_row(
      'SELECT NULL 
       FROM   property_values_data 
       WHERE  group_name=''' || l_group_single || '''
       AND    key = ''' || l_key || '''
       AND    value = ''' || l_value || i || '''
       AND    property_description = ''testDesc''');
       
  END LOOP;
  
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key, l_value || i, 'testDesc' || i);
    
    assert_one_row(
      'SELECT NULL 
       FROM   property_values_data 
       WHERE  group_name=''' || l_group_single || '''
       AND    key = ''' || l_key || '''
       AND    value = ''' || l_value || i || '''
       AND    property_description = ''testDesc' || i || '''');
       
  END LOOP;
  
  properties.set_locked(l_group_single, constants.yes);
    
  assert_raises_exception(
    'properties.set_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_single, constants.no);
  
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key2, l_value2 || i);
    
    assert_one_row(
      'SELECT NULL 
       FROM   property_values_data 
       WHERE  group_name=''' || l_group_single || '''
       AND    key = ''' || l_key2 || '''
       AND    value = ''' || l_value2 || i || '''');
       
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  
  properties.create_property_group(l_group_single);
  
  properties.set_property(l_group_single, l_key, l_value, 'testDesc', 'testOrder');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder''
     AND    property_description = ''testDesc''');
  
  properties.set_property(l_group_single, l_key, l_value2);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value2 || '''
     AND    sort_order = ''testOrder''
     AND    property_description = ''testDesc''');
  
  properties.set_property(l_group_single, l_key, l_value, 'testDesc2');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder''
     AND    property_description = ''testDesc2''');
     
  properties.set_property(l_group_single, l_key, l_value, NULL, 'testOrder2');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder2''
     AND    property_description = ''testDesc2''');
  
  properties.remove_property_group(l_group_single);
  
  properties.create_property_group(l_group_single);
  
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key2, l_value2 || i, l_value2 || i);
    
    assert_one_row(
      'SELECT NULL 
       FROM   property_values_data 
       WHERE  group_name=''' || l_group_single || '''
       AND    key = ''' || l_key2 || '''
       AND    value = ''' || l_value2 || i || '''
       AND    property_description = ''' || l_value2 || i || '''');
       
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  
  properties.create_property_group(l_group_single);
  
  FOR i IN 1 .. l_loop_limit
  LOOP
    properties.set_property(l_group_single, l_key2, l_value2 || i, l_value2 || i, i);
    
    assert_one_row(
      'SELECT NULL 
       FROM   property_values_data 
       WHERE  group_name=''' || l_group_single || '''
       AND    key = ''' || l_key2 || '''
       AND    value = ''' || l_value2 || i || '''
       AND    sort_order = ''' || i || '''
       AND    property_description = ''' || l_value2 || i || '''');
       
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  assert_raises_exception(
    'properties.set_property(''' || l_group_multiple || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_multiple, constants.no);
  properties.set_locked(l_group_multiple, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_multiple) = constants.yes,
    l_group_multiple || ' should be locked'); 
    
  assert_raises_exception(
    'properties.set_property(''' || l_group_multiple || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_multiple, constants.no);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  properties.set_property(l_group_multiple, l_key, l_value || '0', 'testDesc');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '0''
     AND    property_description = ''testDesc''');
       
  FOR i IN 1 .. 9
  LOOP
    properties.set_property(l_group_multiple, l_key, l_value || i);
  END LOOP;
  
  DECLARE
    l_rowcount INTEGER := 0;
  BEGIN
    FOR i IN (SELECT * 
              FROM   property_values_data
              WHERE  group_name = l_group_multiple
              AND    key = l_key
              ORDER BY value)
    LOOP
      assert(
        i.value = l_value || l_rowcount,
        'invalid value. expected ' || l_value || l_rowcount || '. found ' || i.value);
        
      l_rowcount := l_rowcount + 1;
      
    END LOOP;
    assert(
      l_rowcount = 10,
      'should have been 10 entries. found ' || l_rowcount);
      
  END;
  
  properties.remove_property_group(l_group_multiple);
  
  properties.create_property_group(l_group_multiple, constants.no);
  
  properties.set_property(l_group_multiple, l_key, l_value);
  properties.set_property(l_group_multiple, l_key, l_value, 'testDesc');
  properties.set_property(l_group_multiple, l_key, l_value, 'testDesc', 'testOrder');
  properties.set_property(l_group_multiple, l_key, l_value, NULL, 'testOrder');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
     
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description = ''testDesc''');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder''
     AND    property_description = ''testDesc''');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder''
     AND    property_description IS NULL');
  
  properties.remove_property_group(l_group_multiple);
  
  p('set_property: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking update_property_description');
  
  assert_raises_exception(
    'properties.update_property_description(''' || l_group_single || ''', ''' || l_key || ''', NULL);',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  properties.set_locked(l_group_single, constants.yes);
    
  assert_raises_exception(
    'properties.update_property_description(''' || l_group_single || ''', ''' || l_key || ''', NULL);',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_single, constants.no);
  
  assert_raises_exception(
    'properties.update_property_description(''' || l_group_single || ''', ''' || l_key || ''', NULL);',
    -20000,
    'Property not found');
    
  properties.set_property(l_group_single, l_key, l_value);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
  
  properties.update_property_description(l_group_single, l_key, 'testDesc');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description =''testDesc''');
  
  properties.remove_property_group(l_group_single);
  
    
  properties.create_property_group(l_group_multiple, constants.no);
  
  properties.set_locked(l_group_multiple, constants.yes);
  
  assert_raises_exception(
    'properties.update_property_description(''' || l_group_multiple || ''', ''' || l_key || ''', NULL);',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_multiple, constants.no);
       
  properties.set_property(l_group_multiple, l_key, l_value);
  properties.set_property(l_group_multiple, l_key, l_value2);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
     
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value2 || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
  
  properties.update_property_description(l_group_multiple, l_key, 'testDesc');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description = ''testDesc''');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value2 || '''
     AND    sort_order IS NULL
     AND    property_description = ''testDesc''');
  
  properties.remove_property_group(l_group_multiple);
  
  p('update_property_description: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking update_property_sort_order');
  
  assert_raises_exception(
    'properties.update_property_sort_order(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''', NULL);',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  properties.set_locked(l_group_single, constants.yes);
    
  assert_raises_exception(
    'properties.update_property_sort_order(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''', NULL);',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_single, constants.no);
  
  assert_raises_exception(
    'properties.update_property_sort_order(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''', NULL);',
    -20000,
    'Property not found');
    
  properties.set_property(l_group_single, l_key, l_value);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
  
  properties.update_property_sort_order(l_group_single, l_key, l_value, 'testOrder');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder''
     AND    property_description IS NULL');
  
  properties.remove_property_group(l_group_single);
  
    
  properties.create_property_group(l_group_multiple, constants.no);
  
  properties.set_locked(l_group_multiple, constants.yes);
  
  assert_raises_exception(
    'properties.update_property_sort_order(''' || l_group_multiple || ''', ''' || l_key || ''', ''' || l_value || ''', NULL);',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_multiple, constants.no);
       
  properties.set_property(l_group_multiple, l_key, l_value);
  properties.set_property(l_group_multiple, l_key, l_value2);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
     
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value2 || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
  
  properties.update_property_sort_order(l_group_multiple, l_key, l_value, 'testOrder');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value || '''
     AND    sort_order = ''testOrder''
     AND    property_description IS NULL');
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''
     AND    key = ''' || l_key || '''
     AND    value = ''' || l_value2 || '''
     AND    sort_order IS NULL
     AND    property_description IS NULL');
  
  properties.remove_property_group(l_group_multiple);
  
  p('update_property_sort_order: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking remove_property');
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''');',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''');',
    -20000,
    'group%is locked');
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property should not exist');
  
  properties.set_locked(l_group_single, constants.no);
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
    
  assert(
    properties.property_exists(l_group_single, l_key) = constants.no,
    'property should not exist');
  
  properties.set_property(l_group_single, l_key, l_value);
  
  assert(
    properties.property_exists(l_group_single, l_key) = constants.yes,
    'property should exist');
  
  properties.remove_property(l_group_single,l_key);
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
  
  properties.remove_property_group(l_group_single);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_multiple || ''', ''' || l_key || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_multiple, constants.no);
  properties.set_locked(l_group_multiple, constants.yes);
  
  assert(
    properties.get_locked(l_group_multiple) = constants.yes,
    l_group_multiple || ' should be locked'); 
    
  assert_raises_exception(
    'properties.remove_property(''' || l_group_multiple || ''', ''' || l_key || ''');',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_multiple, constants.no);
       
  FOR i IN 1 .. 9
  LOOP
    properties.set_property(l_group_multiple, l_key, l_value || i);
  END LOOP;
  
  DECLARE
    l_rowcount INTEGER := 0;
  BEGIN
    FOR i IN (SELECT * 
              FROM   property_values_data
              WHERE  group_name = l_group_multiple
              AND    key = l_key
              ORDER BY value)
    LOOP
      l_rowcount := l_rowcount + 1;
      assert(
        i.value = l_value || l_rowcount,
        'invalid value. expected ' || l_value || l_rowcount || '. found ' || i.value);
      
    END LOOP;
    assert(
      l_rowcount = 9,
      'should have been 9 entries. found ' || l_rowcount);
      
  END;
  
  properties.remove_property(l_group_multiple,l_key);
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_multiple || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
  
  properties.remove_property_group(l_group_multiple);
  
  p('remove_property: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking remove_property2');
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  properties.set_locked(l_group_single, constants.yes);
  
  assert_one_row(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_single || '''
     AND    locked = ''' || constants.yes || '''');
     
  assert(
    properties.get_locked(l_group_single) = constants.yes,
    l_group_single || ' should be locked'); 
    
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'group%is locked');
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property should not exist');
  
  properties.set_locked(l_group_single, constants.no);
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'Property not found');
    
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.no,
    'property should not exist');
  
  properties.set_property(l_group_single, l_key, l_value);
  
  assert(
    properties.property_exists(l_group_single, l_key, l_value) = constants.yes,
    'property should exist');
  
  properties.remove_property(l_group_single, l_key, l_value);
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_single || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'Property not found');
  
  properties.remove_property_group(l_group_single);
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_groups_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  assert_no_rows(
    'SELECT NULL 
     FROM   property_values_data 
     WHERE  group_name=''' || l_group_multiple || '''');
  
  assert_raises_exception(
    'properties.remove_property(''' || l_group_multiple || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'Property group%not found');
    
  properties.create_property_group(l_group_multiple, constants.no);
  properties.set_locked(l_group_multiple, constants.yes);
  
  assert(
    properties.get_locked(l_group_multiple) = constants.yes,
    l_group_multiple || ' should be locked'); 
    
  assert_raises_exception(
    'properties.remove_property(''' || l_group_multiple || ''', ''' || l_key || ''', ''' || l_value || ''');',
    -20000,
    'group%is locked');
  
  properties.set_locked(l_group_multiple, constants.no);
       
  FOR i IN 1 .. 9
  LOOP
    properties.set_property(l_group_multiple, l_key, l_value || i);
  END LOOP;
  
  FOR i IN 1 .. 9
  LOOP
    properties.remove_property(l_group_multiple, l_key, l_value || i);
    assert_raises_exception(
      'properties.remove_property(''' || l_group_multiple || ''', ''' || l_key || ''', ''' || l_value || i || ''');',
      -20000,
      'Property not found');
      
  END LOOP;
  
  properties.remove_property_group(l_group_multiple);
  
  p('remove_property2: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_group_names');
  
  properties.create_property_group(l_group_single);
  properties.create_property_group(l_group_multiple, constants.no);
  
  t.DELETE;
  properties.get_group_names(t);
  
  l_boolean := FALSE;
  l_boolean2 := FALSE;
  
  FOR i in t.FIRST .. t.LAST
  LOOP
    IF (t(i) = l_group_single)
    THEN
      l_boolean := TRUE;
    END IF;
    IF (t(i) = l_group_multiple)
    THEN
      l_boolean2 := TRUE;
    END IF;
   
  END LOOP;
  
  assert(
    l_boolean,
    'did not find single');
  
  assert(
    l_boolean2,
    'did not find multiple');
  
  properties.remove_property_group(l_group_single);
  
  t.DELETE;
  properties.get_group_names(t);
  
  l_boolean := FALSE;
  l_boolean2 := FALSE;
  
  FOR i in t.FIRST .. t.LAST
  LOOP
    IF (t(i) = l_group_single)
    THEN
      l_boolean := TRUE;
    END IF;
    IF (t(i) = l_group_multiple)
    THEN
      l_boolean2 := TRUE;
    END IF;
   
  END LOOP;
  
  assert(
    NOT l_boolean,
    'found single - single was removed');
  
  assert(
    l_boolean2,
    'did not find multiple');
  
  properties.remove_property_group(l_group_multiple);
  
  t.DELETE;
  properties.get_group_names(t);
  
  l_boolean := FALSE;
  l_boolean2 := FALSE;
  
  FOR i in t.FIRST .. t.LAST
  LOOP
    IF (t(i) = l_group_single)
    THEN
      l_boolean := TRUE;
    END IF;
    IF (t(i) = l_group_multiple)
    THEN
      l_boolean2 := TRUE;
    END IF;
   
  END LOOP;
  
  assert(
    NOT l_boolean,
    'found single - single was removed');
  
  assert(
    NOT l_boolean2,
    'found multiple - multiple was removed');
  
  p('get_group_names: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_keys');
  
  assert_raises_exception(
    'properties.get_keys(''' || l_group_single || ''', t);',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  
  FOR i IN 1 ..6
  LOOP
    properties.set_property(l_group_single, 'key' || i, i);
  END LOOP;
  
  t.DELETE;
  properties.get_keys(l_group_single, t);
  
  assert(
    t.LAST = 6,
    'expected 6 elements. found ' || t.LAST);
  
  FOR i IN t.FIRST .. t.LAST
  LOOP
    assert(
      t(i) = 'key' || i,
      'invalid key. expected key' || i || ' found ' || t(i));
      
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  
  assert_raises_exception(
    'properties.get_keys(''' || l_group_single || ''', t);',
    -20000,
    'Property group%not found');
  
  p('get_keys: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_property');
  
  assert_raises_exception(
    'l_array(0) := properties.get_property(''' || l_group_single || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
  
  properties.create_property_group(l_group_single);
  
  assert_raises_exception(
    'l_array(0) := properties.get_property(''' || l_group_single || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
    
  properties.set_property(l_group_single, l_key, l_value);
  
  assert(
    properties.get_property(l_group_single, l_key) = l_value,
    'invalid property. expected ' || l_value || ' found ' || properties.get_property(l_group_single, l_key));
  
  properties.remove_property_group(l_group_single);
  
  assert_raises_exception(
    'l_array(0) := properties.get_property(''' || l_group_multiple || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
    
  properties.create_property_group(l_group_multiple, constants.no);
  
  assert_raises_exception(
    'l_array(0) := properties.get_property(''' || l_group_multiple || ''', ''' || l_key || ''');',
    -20000,
    'Property not found');
    
  properties.set_property(l_group_multiple, l_key, l_value);
  
  assert(
    properties.get_property(l_group_multiple, l_key) = l_value,
    'invalid property. expected ' || l_value || ' found ' || properties.get_property(l_group_multiple, l_key));
  
  properties.set_property(l_group_multiple, l_key, l_value2);
  
  assert_raises_exception(
    'l_array(0) := properties.get_property(''' || l_group_multiple || ''', ''' || l_key || ''');',
    -20000,
    'property has more than one value');
  
  properties.remove_property_group(l_group_multiple);
  
  p('get_property: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_values');
  
  assert_raises_exception(
    'properties.get_values(''' || l_group_single || ''', ''' || l_key || ''', t);',
    -20000,
    'Property not found');
  
  properties.create_property_group(l_group_single);
  
  assert_raises_exception(
    'properties.get_values(''' || l_group_single || ''', ''' || l_key || ''', t);',
    -20000,
    'Property not found');
    
  properties.set_property(l_group_single, l_key, l_value);
  
  t.DELETE;
  properties.get_values(l_group_single, l_key, t);
  
  assert(
    t.LAST = 1,
   'expected one property returned. got ' || t.LAST);
  
  assert(
    t(1) = l_value,
    'invalid property. expected ' || l_value || ' found ' || t(1));
  
  properties.set_property(l_group_single, l_key, l_value2);
  
  t.DELETE;
  properties.get_values(l_group_single, l_key, t);
  
  assert(
    t.LAST = 1,
   'expected one property returned. got ' || t.LAST);
  
  assert(
    t(1) = l_value2,
    'invalid property. expected ' || l_value2 || ' found ' || t(1));
  
  properties.remove_property_group(l_group_single);
  
  assert_raises_exception(
    'properties.get_values(''' || l_group_multiple || ''', ''' || l_key || ''', t);',
    -20000,
    'Property not found');
    
  properties.create_property_group(l_group_multiple, constants.no);
  
  assert_raises_exception(
    'properties.get_values(''' || l_group_multiple || ''', ''' || l_key || ''', t);',
    -20000,
    'Property not found');
    
  properties.set_property(l_group_multiple, l_key, l_value);
  
  t.DELETE;
  properties.get_values(l_group_multiple, l_key, t);
  
  assert(
    t.LAST = 1,
   'expected one property returned. got ' || t.LAST);
  
  assert(
    t(1) = l_value,
    'invalid property. expected ' || l_value || ' found ' || t(1));
  
  properties.set_property(l_group_multiple, l_key, l_value2);
  
  t.DELETE;
  properties.get_values(l_group_multiple, l_key, t);
  
  assert(
    t.LAST = 2,
   'expected 2 properties returned. got ' || t.LAST);
  
  assert(
    t(1) IN (l_value, l_value2),
    '(1) invalid property. expected ' || l_value || ' or ' || l_value2 || ' found ' || t(1));

  assert(
    t(2) IN (l_value, l_value2),
    '(2) invalid property. expected ' || l_value || ' or ' || l_value2 || ' found ' || t(1));
  
  properties.remove_property_group(l_group_multiple);
  
  properties.create_property_group(l_group_multiple, constants.no);
  
  properties.set_property(l_group_multiple, l_key, 1);
  properties.set_property(l_group_multiple, l_key, 2);
  properties.set_property(l_group_multiple, l_key, 3);
  
  t.DELETE;
  properties.get_values(l_group_multiple, l_key, t);
  
  assert(
    t(1) = 1 AND t(2) = 2 AND t(3) = 3,
    'expected 1 2 3. found ' || t(1) || ' ' || t(2) || ' ' || t(3));
    
  properties.set_property(l_group_multiple, l_key, 1, NULL, 3);
  properties.set_property(l_group_multiple, l_key, 2, NULL, 2);
  properties.set_property(l_group_multiple, l_key, 3, NULL, 1);
  
  t.DELETE;
  properties.get_values(l_group_multiple, l_key, t);
  
  assert(
    t(1) = 3 AND t(2) = 2 AND t(3) = 1,
    'expected 1 2 3. found ' || t(1) || ' ' || t(2) || ' ' || t(3));
  
  properties.remove_property_group(l_group_multiple);
  
  p('get_values: ok');
  --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  p('checking get_properties');
  
  assert_raises_exception(
    'properties.get_properties(''' || l_group_single || ''', l_cur);',
    -20000,
    'Property group%not found');
  
  properties.create_property_group(l_group_single);
  properties.set_property(l_group_single, l_key, l_value);
  properties.set_property(l_group_single, l_key2, l_value2);
  properties.create_property_group(l_group_multiple, constants.no);
  properties.set_property(l_group_multiple, l_key, l_value);
  properties.set_property(l_group_multiple, l_key, l_value2);
  properties.set_property(l_group_multiple, l_key2, l_value2);
  
  FOR i IN 1 .. l_loop_limit
  LOOP
    <<single_check>>
    DECLARE
      l_cur SYS_REFCURSOR;
      l_k VARCHAR2(32767);
      l_v VARCHAR2(32767);
      l_row INTEGER := 0;
      
    BEGIN
      properties.get_properties(l_group_single, l_cur);
      
      LOOP
        FETCH l_cur INTO l_k, l_v;
        EXIT WHEN l_cur%NOTFOUND;
        l_row := l_row + 1;
        
        IF (l_row = 1)
        THEN
          assert(
            l_k = l_key,
            'expected l_key (' || l_key || ') found ' || l_k);
          assert(
            l_v = l_value,
            'expected l_value (' || l_value || ') found ' || l_v);
          
        ELSE
          assert(
            l_k = l_key2,
            'expected l_key2 (' || l_key2 || ') found ' || l_k);
          assert(
            l_v = l_value2,
            'expected l_value2 (' || l_value2 || ') found ' || l_v);
            
        END IF;
        
      END LOOP;
      
      assert(
        l_row = 2,
        'expected 2 rows. found ' || l_row);
      
    END single_check;
    
    <<multiple_check>>
    DECLARE
      l_cur SYS_REFCURSOR;
      l_k VARCHAR2(32767);
      l_v VARCHAR2(32767);
      l_row INTEGER := 0;
      
    BEGIN
      properties.get_properties(l_group_multiple, l_cur);
      
      LOOP
        FETCH l_cur INTO l_k, l_v;
        EXIT WHEN l_cur%NOTFOUND;
        l_row := l_row + 1;
        
        IF (l_row = 1)
        THEN
          assert(
            l_k = l_key,
            'expected l_key (' || l_key || ') found ' || l_k);
          assert(
            l_v = l_value,
            'expected l_value (' || l_value || ') found ' || l_v);
          
        ELSIF (l_row = 2)
        THEN
          assert(
            l_k = l_key,
            'expected l_key (' || l_key || ') found ' || l_k);
          assert(
            l_v = l_value2,
            'expected l_value2 (' || l_value2 || ') found ' || l_v);
            
        ELSE
          assert(
            l_k = l_key2,
            'expected l_key2 (' || l_key2 || ') found ' || l_k);
          assert(
            l_v = l_value2,
            'expected l_value2 (' || l_value2 || ') found ' || l_v);
        
        END IF;
        
      END LOOP;
      
      assert(
        l_row = 3,
        'expected 3 rows. found ' || l_row);
      
      -- set sort order
      properties.update_property_sort_order(l_group_multiple, l_key, l_value2, 'anything');
      
      l_row := 0;
      
      properties.get_properties(l_group_multiple, l_cur);
      
      LOOP
        FETCH l_cur INTO l_k, l_v;
        EXIT WHEN l_cur%NOTFOUND;
        l_row := l_row + 1;
        
        IF (l_row = 1)
        THEN
          assert(
            l_k = l_key,
            'expected l_key (' || l_key || ') found ' || l_k);
          assert(
            l_v = l_value2,
            'expected l_value2 (' || l_value2 || ') found ' || l_v);
          
        ELSIF (l_row = 2)
        THEN
          assert(
            l_k = l_key,
            'expected l_key (' || l_key || ') found ' || l_k);
          assert(
            l_v = l_value,
            'expected l_value (' || l_value || ') found ' || l_v);
        
        END IF;
        
      END LOOP;
      
      -- re-set sort order
      properties.update_property_sort_order(l_group_multiple, l_key, l_value2, NULL);
      
    END multiple_check;
    
  END LOOP;
  
  properties.remove_property_group(l_group_single);
  properties.remove_property_group(l_group_multiple);
  
  p('get_properties: ok');
  
END;
