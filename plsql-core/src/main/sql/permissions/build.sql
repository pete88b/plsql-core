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
    drop_object('TABLE permission_set_data');
    drop_object('TABLE permission_data');
    drop_object('SEQUENCE permission_id_sequence');

  END IF;

END;
/


PROMPT Creating table permission_data

CREATE TABLE permission_data(
  permission_id INTEGER,
  permission_name VARCHAR2(1024) NOT NULL,
  permission_description VARCHAR2(2000),
  CONSTRAINT permission_data_pk PRIMARY KEY(permission_id),
  CONSTRAINT permission_name_unique UNIQUE(permission_name)
);

PROMPT Creating sequence permission_id_sequence

CREATE SEQUENCE permission_id_sequence
  MINVALUE 0
  MAXVALUE 99999999999999999999999999
  START WITH 0
  INCREMENT BY 1
  CACHE 10
  CYCLE
  ORDER;

PROMPT Creating trigger bi_fer_permission

CREATE OR REPLACE TRIGGER bi_fer_permission
BEFORE INSERT ON permission_data
FOR EACH ROW
BEGIN
  SELECT permission_id_sequence.NEXTVAL
    INTO :NEW.permission_id
    FROM DUAL;
END;
/

PROMPT Creating table permission_set_data

CREATE TABLE permission_set_data(
  permission_id 
    NOT NULL
    CONSTRAINT permission_must_exists
      REFERENCES permission_data(permission_id)
      ON DELETE CASCADE,
  permission_allowed_id
    NOT NULL
    CONSTRAINT permission_allowed_must_exists
      REFERENCES permission_data(permission_id)
      ON DELETE CASCADE,
  CONSTRAINT permission_set_data_pk 
    PRIMARY KEY (permission_id, permission_allowed_id),
  CONSTRAINT permission_set_cant_allow_self
    CHECK (permission_id != permission_allowed_id)
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
