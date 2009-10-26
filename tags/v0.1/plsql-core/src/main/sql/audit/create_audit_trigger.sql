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

/*
  Creates an audit trigger on the specified table. 
  i.e. Enables auditing for the specified table.
  
  The first argument should be the owner of the table.
  The second argument should be the name of the table.

  Example of use:
    SQL> @create_audit_trigger hr countries

  The audit triggers created by this script may also be called a$ triggers
  as their name always begins with a$.
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
  l_trigger_sql VARCHAR2(32767);
  -- Holds other dynamic SQL
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
  END fail;
  
  /*
    Appends some text to the SQL variable
  */
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    l_trigger_sql := l_trigger_sql || s || CHR(10);
  END p;
  
  /*
    Returns the audit name ID for the given name.
    
    The SQL statements in this function are dynamic as we have to use the
    audit names table that belongs to the specified owner.
    i.e. The table for which we are enabling auditing must be in the same
    schema as the audit names table from which the audit name ID's came from.
  */
  FUNCTION get_audit_name_id(
    p_name IN VARCHAR2
  )
  RETURN INTEGER
  IS
    -- Holds dynamic SQL used by this function
    l_get_audit_name_id_sql VARCHAR2(32767);
    -- Holds an audit name ID
    l_result INTEGER;
    
  BEGIN
    l_get_audit_name_id_sql := '
      SELECT 
        audit_name_id
      FROM 
        ' || l_owner || '.audit_names_data
      WHERE 
        audit_name = UPPER(:p_name)';
    
    -- See if this name already exists
    EXECUTE IMMEDIATE 
      l_get_audit_name_id_sql
    INTO 
      l_result
    USING 
      p_name;
     
    RETURN l_result;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      -- if the name doesn't exist yet, create it now
      l_get_audit_name_id_sql := '
        INSERT INTO ' || l_owner || '.audit_names_data(
          audit_name)
        VALUES (
          UPPER(:p_name))
        RETURNING 
          audit_name_id INTO :l_result';
      
      EXECUTE IMMEDIATE 
        l_get_audit_name_id_sql
      USING 
        p_name
      RETURNING INTO 
        l_result;
    
      RETURN l_result;
      
  END get_audit_name_id;
  
BEGIN
  DBMS_OUTPUT.ENABLE(100000);
  
  -- TODO: Check that we can handle all datatypes used by the specified table
  
  -- Load column names and their data types into the index-by tables
  SELECT 
    LOWER(column_name) AS column_name, data_type
  BULK COLLECT INTO 
    l_column_names, l_data_types
  FROM 
    all_tab_columns
  WHERE 
    owner = UPPER(l_owner)
  AND
    table_name = UPPER(l_table)
  ORDER BY 
    column_name;
   
  -- Check that the table exists
  IF (l_column_names.FIRST IS NULL)
  THEN
    fail('Table not found ' || l_owner || '.' || l_table || '. (or you may not have access to it)');
    
  END IF;
  
  DBMS_OUTPUT.PUT_LINE('Creating trigger ' || l_owner || '.a$' || get_audit_name_id(l_table));
  
  p('CREATE OR REPLACE TRIGGER ' || l_owner || '.a$' || get_audit_name_id(l_table));
  p('AFTER INSERT OR UPDATE OR DELETE ON ' || l_owner || '.' || l_table);
  p('FOR EACH ROW');
  p('/*');
  p('Created by create_audit_trigger.sql. Automated drop tag.');
  p('');
  p('Do not change the comment above (line 5) unless you want to stop this');
  p('trigger from being dropped programatically. See drop_audit_triggers.sql');
  p('*/');
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
    p('    IF (:OLD.' || l_column_names(i) || ' != :NEW.' || l_column_names(i) || ' OR');
    p('        :OLD.' || l_column_names(i) || ' IS NULL AND :NEW.' || l_column_names(i) || ' IS NOT NULL OR');
    p('        :OLD.' || l_column_names(i) || ' IS NOT NULL AND :NEW.' || l_column_names(i) || ' IS NULL)');
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
  EXECUTE IMMEDIATE l_trigger_sql;
  
END;
/
