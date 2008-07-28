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
  -- The owner of the table. Value got from the first SQL*Plus argument
  l_owner VARCHAR2(32767) := LOWER('&1');
  -- The name of the table. Value got from the second SQL*Plus argument
  l_table VARCHAR2(32767) := LOWER('&2');
  
  -- Define an index-by table type to hold text data
  TYPE varchar_table_type IS TABLE OF VARCHAR2(2000)
  INDEX BY BINARY_INTEGER;
  
  -- Holds column names
  l_column_names varchar_table_type;
  -- Holds column data types
  l_data_types varchar_table_type;
  
  -- Holds the SQL used to define/create the trigger
  l_sql VARCHAR2(32767);
  
  /*
    Called when we know we can't create the trigger
    e.g. When the table does not exist
  */
  PROCEDURE fail(
    message IN VARCHAR2
  )
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, message);
  END;
  
  /*
    Appends some text to the SQL variable
  */
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    l_sql := l_sql || s || CHR(10);
  END p;
  
  /*
    Returns the audit name ID for the given name
  */
  FUNCTION get_audit_name_id(
    p_name IN VARCHAR2
  )
  RETURN INTEGER
  IS
    l_result INTEGER;
    
  BEGIN
    -- See if this name already exists
    SELECT audit_name_id
      INTO l_result
      FROM audit_names_data
     WHERE audit_name = UPPER(p_name);
     
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      -- if the name doesn't exist yet, create it now
      INSERT INTO audit_names_data(audit_name)
      VALUES (UPPER(p_name))
      RETURNING audit_name_id INTO l_result;
      
      RETURN l_result;
      
  END;
  
BEGIN
  DBMS_OUTPUT.ENABLE(100000);
  
  -- TODO: Check that we can handle all datatypes used by the specified table
  
  <<check_table_exists>>
  DECLARE
    l_count INTEGER;
    
  BEGIN
    SELECT NULL
      INTO l_count
      FROM dba_tables
     WHERE owner = UPPER(l_owner)
       AND table_name = UPPER(l_table);
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      fail('table not found ' || l_owner || '.' || l_table);
      
  END check_table_exists;
  
  -- Load column names and their data types into the index-by tables
  SELECT LOWER(column_name) AS column_name, data_type
    BULK COLLECT INTO l_column_names, l_data_types
    FROM dba_tab_columns
   WHERE owner = UPPER(l_owner)
     AND table_name = UPPER(l_table)
   ORDER BY column_name;
  
  DBMS_OUTPUT.PUT_LINE('Creating trigger ' || l_owner || '.a$' || get_audit_name_id(l_table));
  
  p('CREATE OR REPLACE TRIGGER ' || l_owner || '.a$' || get_audit_name_id(l_table));
  p('AFTER INSERT OR UPDATE OR DELETE ON ' || l_owner || '.' || l_table);
  p('FOR EACH ROW');
  p('DECLARE');
  p('  l_event_id INTEGER;');
  p('');
  p('BEGIN');
  -- DELETING
  p('  IF (DELETING)');
  p('  THEN');
  p('    auditer.new_event(l_event_id, 1, ' || 
    get_audit_name_id(l_owner) || ', ' || get_audit_name_id(l_table) || ', :OLD.ROWID);');
  
  p('');
  -- INSERTING
  p('  ELSIF (INSERTING)');
  p('  THEN');
  p('    auditer.new_event(l_event_id, 2, ' || 
    get_audit_name_id(l_owner) || ', ' || get_audit_name_id(l_table) || ', :NEW.ROWID);');
    
  FOR i IN l_column_names.FIRST .. l_column_names.LAST
  LOOP
    IF (l_data_types(i) = 'DATE')
    THEN
      p('    auditer.new_change(l_event_id, ' || get_audit_name_id(l_column_names(i)) || 
        ', NULL, TO_CHAR(:NEW.' || 
        l_column_names(i) || ', ''YYYYMMDDHH24MISS''));');
        
    ELSE
      p('    auditer.new_change(l_event_id, ' || get_audit_name_id(l_column_names(i)) || 
        ', NULL, :NEW.' || l_column_names(i) || ');');
        
    END IF;
    
  END LOOP;
  p('');
  -- UPDATING
  p('  ELSE -- UPDATING');
  p('    auditer.new_event(l_event_id, 3, ' || 
    get_audit_name_id(l_owner) || ', ' || get_audit_name_id(l_table) || ', :NEW.ROWID);');
    
  p('');
  FOR i IN l_column_names.FIRST .. l_column_names.LAST
  LOOP
    p('    IF (NOT(:OLD.' || l_column_names(i) || ' = :NEW.' || l_column_names(i) ||
               ' OR (:OLD.' || l_column_names(i) || ' IS NULL AND :NEW.' || 
               l_column_names(i) || ' IS NULL)))');
    p('    THEN');
    
    IF (l_data_types(i) = 'DATE')
    THEN
      p('      auditer.new_change(l_event_id, ' || get_audit_name_id(l_column_names(i)) || ', TO_CHAR(:OLD.' || 
        l_column_names(i) || ', ''YYYYMMDDHH24MISS''), TO_CHAR(:NEW.' || 
        l_column_names(i) || ', ''YYYYMMDDHH24MISS''));');
        
    ELSE
      p('      auditer.new_change(l_event_id, ' || get_audit_name_id(l_column_names(i)) || ', :OLD.' || 
        l_column_names(i) || ', :NEW.' || l_column_names(i) || ');');
        
    END IF;

    p('    END IF;');
    p('');
    
  END LOOP;

  p('  END IF;');
  p('');
  p('EXCEPTION');
  p('  WHEN OTHERS');
  p('    THEN logger.error(''audit trigger failure'');');
  p('    RAISE;');
  p('');
  p('END;');
  
  -- create the trigger
  EXECUTE IMMEDIATE l_sql;
  
END;
/
