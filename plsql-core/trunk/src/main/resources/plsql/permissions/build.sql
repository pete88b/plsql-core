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
  Build script for permissions.

  Depends on: logger.
  Depends on: exceptions.
  Depends on: messages.
  Depends on: properties.
*/

PROMPT ___ Start of permissions build.sql ___


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
    drop_object('TABLE permission_sets_data');
    drop_object('TABLE permissions_data');

  END IF;

  BEGIN
    properties.create_property_group(
      'permission',
      constants.yes,
      'Properties that are used by the permission package');

    properties.set_property(
      'permission',
      'case_of_permission',
      'upper',
      'Controls how permissions are saved and compared');

    
  EXCEPTION
    WHEN OTHERS
    THEN
      p('Failed to create property group "permission". This could be because the group already existed.');

  END;

END;
/


PROMPT Creating table permissions_data

CREATE TABLE permissions_data(
  permission VARCHAR2(100),
  description VARCHAR2(2000),
  status INTEGER NOT NULL,
  CONSTRAINT permissions_pk PRIMARY KEY(permission),
  CONSTRAINT valid_status CHECK (status IN (0, 1, 2, 3, 4))
);

PROMPT Creating table permission_sets

CREATE TABLE permission_sets_data(
  permission REFERENCES permissions_data(permission),
  permission_allowed REFERENCES permissions_data(permission),
  CONSTRAINT permission_sets_pk PRIMARY KEY (permission, permission_allowed),
  CONSTRAINT set_cant_allow_self CHECK (permission != permission_allowed)
);

PROMPT Creating permission package specification
@@permission.spc

PROMPT Creating permissions package specification
@@permissions.spc

PROMPT Creating permission package body
@@permission.bdy

PROMPT Creating permissions package body
@@permissions.bdy
  
PROMPT ___ End of permissions build.sql ___
