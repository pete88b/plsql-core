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

  Depends on: constants.
  Depends on: logger.
  Depends on: types.
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
    drop_object('TABLE property_values_data');
    drop_object('TABLE property_groups_data');

  END IF;

END;
/

PROMPT Creating table property_groups_data

CREATE TABLE property_groups_data(
  group_name VARCHAR2(200),
  single_value_per_key VARCHAR2(1) DEFAULT 'Y' NOT NULL,
  locked VARCHAR2(1) DEFAULT 'N' NOT NULL,
  group_description VARCHAR2(4000),
  CONSTRAINT properties_groups_pk PRIMARY KEY (group_name),
  CONSTRAINT single_value_per_key_y_or_n CHECK (
    single_value_per_key IN ('Y', 'N')
  ),
  CONSTRAINT locked_y_or_n CHECK (
    locked IN ('Y', 'N')
  )
);

PROMPT Creating table property_values_data

CREATE TABLE property_values_data(
  group_name CONSTRAINT properties_data_fk REFERENCES property_groups_data(group_name),
  key VARCHAR2(1024) NOT NULL,
  value VARCHAR2(4000),
  sort_order VARCHAR2(10),
  property_description VARCHAR2(4000)
);

PROMPT Creating properties package

@@properties.pck


PROMPT ___ End of properties build.sql ___
