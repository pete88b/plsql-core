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
  Drops all audit triggers for the specified owner.

  The first argument should be the owner of the tables for which auditing
  may have been enabled.

  Example of use:
    SQL> @drop_audit_triggers hr

  Triggers will be dropped if:
    They are owner by the specified owner and
    The name of the trigger starts with a$ and
    Line 5 of the triggers' source code starts with
      'Created by create_audit_trigger.sql. Automated drop tag'.
*/

DECLARE
  -- The owner of the triggers. Value got from the first SQL*Plus argument
  l_owner VARCHAR2(32767) := LOWER('&1');
  
  -- Define an index-by table type to hold text data
  TYPE varchar_table_type IS TABLE OF VARCHAR2(2000)
    INDEX BY BINARY_INTEGER;
  
  -- Holds trigger names
  l_trigger_names varchar_table_type;
  
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
  
BEGIN
  DBMS_OUTPUT.ENABLE(100000);
  
  <<check_owner_exists>>
  DECLARE
    l_count INTEGER;
    
  BEGIN
    SELECT NULL
      INTO l_count
      FROM all_users
     WHERE username = UPPER(l_owner);
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      fail('owner not found: ' || l_owner);
      
  END check_owner_exists;
  
  -- Load column names and their data types into the index-by tables
  SELECT LOWER(name)
    BULK COLLECT INTO l_trigger_names
    FROM all_source
   WHERE owner = UPPER(l_owner)
     AND type = 'TRIGGER'
     AND name LIKE 'A$%'
     AND line = 5
     AND text LIKE 'Created by create_audit_trigger.sql. Automated drop tag%';
  
  IF (l_trigger_names.LAST IS NULL)
  THEN
    DBMS_OUTPUT.PUT_LINE('No audit triggers found for owner: ' || l_owner);

  ELSE
    FOR i IN l_trigger_names.FIRST .. l_trigger_names.LAST
    LOOP
      DBMS_OUTPUT.PUT_LINE('Droping trigger ' || l_owner || '.' || l_trigger_names(i));
      EXECUTE IMMEDIATE 'DROP TRIGGER ' || l_owner || '.' || l_trigger_names(i);

    END LOOP;
    
  END IF;
  
END;
/
