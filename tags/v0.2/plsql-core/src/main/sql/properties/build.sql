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
  Build script for properties.
*/

PROMPT ___ Start of properties build.sql ___

DECLARE
  PROCEDURE p(
    p_data IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_data);
    
  END p;

  PROCEDURE drop_object(
    p_type_and_name IN VARCHAR2
  )
  IS
  BEGIN
    p('Dropping ' || p_type_and_name);
    EXECUTE IMMEDIATE 'DROP ' || p_type_and_name;
    p(p_type_and_name || ' dropped');
    p('-');
    
  EXCEPTION
    WHEN OTHERS
    THEN
      p(p_type_and_name || ' not found');
      p('-');
      
  END drop_object;

BEGIN
  IF (UPPER('&&drop_existing.') = 'YES' OR
      UPPER('&&drop_existing.') = 'Y')
  THEN
    drop_object('TABLE property_value_data');
    drop_object('TABLE property_key_data');
    drop_object('TABLE property_group_data');
    
    drop_object('SEQUENCE property_data_id');
    
  END IF;

END;
/

PROMPT Creating sequence property_data_id

CREATE SEQUENCE property_data_id
  MINVALUE 0
  MAXVALUE 99999999999999999999999999
  START WITH 0
  INCREMENT BY 1
  CACHE 10
  CYCLE
  ORDER;
  

PROMPT Creating table property_group_data

CREATE TABLE property_group_data(
  group_id INTEGER,
  group_name VARCHAR2(200) NOT NULL,
  group_description VARCHAR2(2000),
  CONSTRAINT property_group_data_pk 
    PRIMARY KEY (group_id),
  CONSTRAINT property_group_name_unique 
    UNIQUE (group_name),
  CONSTRAINT property_group_name_check 
    CHECK (INSTR(group_name, '#') = 0)
);

PROMPT Creating trigger bi_fer_property_group_data

CREATE OR REPLACE TRIGGER bi_fer_property_group_data
BEFORE INSERT ON property_group_data 
FOR EACH ROW
BEGIN
  SELECT property_data_id.NEXTVAL
    INTO :NEW.group_id
    FROM DUAL;
END;
/


PROMPT Creating table property_key_data

CREATE TABLE property_key_data(
  key_id INTEGER,
  group_id 
    NOT NULL
    CONSTRAINT property_key_must_have_group 
      REFERENCES property_group_data(group_id) 
      ON DELETE CASCADE,
  single_value_per_key VARCHAR2(1) NOT NULL,
  key VARCHAR2(1024) NOT NULL,
  key_description VARCHAR2(2000),
  CONSTRAINT property_key_data_pk 
    PRIMARY KEY (key_id),
  CONSTRAINT property_group_and_key_unique 
    UNIQUE (group_id, key),
  CONSTRAINT property_key_single_unique 
    UNIQUE (key_id, single_value_per_key),
  CONSTRAINT property_key_check 
    CHECK (INSTR(key, '#') = 0),
  CONSTRAINT single_value_per_key_y_or_n 
    CHECK (single_value_per_key IN ('Y', 'N'))
);

PROMPT Creating trigger bi_fer_property_key_data

CREATE OR REPLACE TRIGGER bi_fer_property_key_data
BEFORE INSERT ON property_key_data 
FOR EACH ROW
BEGIN
  SELECT property_data_id.NEXTVAL
    INTO :NEW.key_id
    FROM DUAL;
END;
/


PROMPT Creating table property_value_data

CREATE TABLE property_value_data(
  value_id INTEGER,
  key_id NOT NULL,
  single_value_per_key VARCHAR2(1) NOT NULL,
  value VARCHAR2(1024),
  sort_order INTEGER,
  CONSTRAINT property_value_data_pk 
    PRIMARY KEY (value_id),
  CONSTRAINT property_value_must_have_key 
    FOREIGN KEY (key_id, single_value_per_key)
    REFERENCES property_key_data(key_id, single_value_per_key)
    ON DELETE CASCADE
);

PROMPT Creating index property_value_single_check

CREATE UNIQUE INDEX property_value_single_check 
  ON property_value_data (
    CASE WHEN 
      single_value_per_key = 'Y' 
    THEN 
      key_id 
    END
  );

PROMPT Creating trigger bi_fer_property_value_data

CREATE OR REPLACE TRIGGER bi_fer_property_value_data
BEFORE INSERT ON property_value_data 
FOR EACH ROW
BEGIN
  -- if an ID has been specified, leave it alone
  IF (:NEW.value_id IS NULL)
  THEN
    -- if no ID has been specified, create one from sequence
    SELECT property_data_id.NEXTVAL
      INTO :NEW.value_id
      FROM DUAL;
  END IF;
END;
/


PROMPT Creating view property_keys_view

CREATE OR REPLACE VIEW property_keys_view AS
SELECT property_group_data.group_name,
       property_group_data.group_description,
       property_key_data.key,
       property_key_data.single_value_per_key,
       property_key_data.key_description,
       (SELECT COUNT(*)
          FROM property_value_data
         WHERE property_value_data.key_id = property_key_data.key_id) AS value_count
  FROM property_group_data,
       property_key_data
 WHERE property_group_data.group_id = property_key_data.group_id
 ORDER BY 
       property_group_data.group_name, 
       property_key_data.key;


PROMPT Creating view property_values_view

CREATE OR REPLACE VIEW property_values_view AS
SELECT property_group_data.group_name,
       property_group_data.group_description,
       property_key_data.key,
       property_key_data.single_value_per_key,
       property_key_data.key_description,
       property_value_data.value,
       property_value_data.sort_order
  FROM property_group_data,
       property_key_data,
       property_value_data
 WHERE property_group_data.group_id = property_key_data.group_id
   AND property_key_data.key_id = property_value_data.key_id
 ORDER BY 
       property_group_data.group_name, 
       property_key_data.key,
       property_value_data.sort_order;


-- Note: The varchar_table type may be used by other modules and should not be droppped
PROMPT Creating nested table type varchar_table 

CREATE OR REPLACE TYPE varchar_table IS TABLE OF VARCHAR2(4000);
/


PROMPT Creating property_manager package

@@property_manager.pck


PROMPT ___ End of properties build.sql ___
