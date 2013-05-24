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
  Build script for audit.
*/

PROMPT ___ Start of audit build.sql ___

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
    p('-');
    p('******************************');
    p('Note: Not dropping a$ triggers');
    p('******************************');
    p('-');
    drop_object('VIEW audit_view');
    drop_object('TABLE audit_changes_data');
    drop_object('SEQUENCE audit_event_id');
    drop_object('TABLE audit_events_data');
    drop_object('SEQUENCE audit_name_id');
    drop_object('TABLE audit_names_data');
    drop_object('TABLE audit_reason_data');

  END IF;

END;
/

-- Set-up some varaibales to hold the database version
VARIABLE db_version VARCHAR2(2000);
VARIABLE db_compatibility VARCHAR2(2000);

-- Get the database version
BEGIN
  DBMS_UTILITY.DB_VERSION(:db_version, :db_compatibility);
  
  DBMS_OUTPUT.PUT_LINE('Found database version: ' || :db_version || CHR(10));

END;
/

-- get the max varchar2 column length based on the database version
-- use 4000 for 10g + 2000 for pre-10g
COLUMN max_varchar_col_length NEW_VALUE max_varchar_col_length NOPRINT
SELECT DECODE(SUBSTR(LTRIM(:db_version), 2, 1),
              '.', '2000',
              '4000') AS max_varchar_col_length
  FROM DUAL;


PROMPT Creating table audit_reason_data

CREATE GLOBAL TEMPORARY TABLE audit_reason_data(
  reason VARCHAR2(&max_varchar_col_length.)
)
ON COMMIT DELETE ROWS;


PROMPT Creating table audit_names_data

CREATE TABLE audit_names_data(
  audit_name_id INTEGER,
  audit_name VARCHAR2(30) NOT NULL,
  CONSTRAINT pk_audit_names_data PRIMARY KEY (audit_name_id)
);


PROMPT Creating sequence audit_name_id

CREATE SEQUENCE audit_name_id
  MINVALUE 0
  MAXVALUE 99999999999999999999999999
  START WITH 0
  INCREMENT BY 1
  CACHE 10
  CYCLE
  ORDER;


PROMPT Creating trigger bi_fer_audit_names_data

CREATE OR REPLACE TRIGGER bi_fer_audit_names_data
BEFORE INSERT ON audit_names_data 
FOR EACH ROW
BEGIN
  SELECT audit_name_id.NEXTVAL
    INTO :NEW.audit_name_id
    FROM DUAL;
END;
/


PROMPT Creating table audit_events_data

/*
  We save the ROWID in a VARCHAR2 field as some times triggers failed to compile
  when using the ROWID datatype. 
  The following would not compile when part of a trigger on hr.countries:
    ...
    IS
      l_row_id ROWID;
    BEGIN
      l_row_id := :NEW.ROWID;
    ...
  Changing l_row_id ROWID to l_row_id VARCHAR2(2000) worked.
*/
CREATE TABLE audit_events_data(
  event_id INTEGER,
  event_type_id INTEGER NOT NULL,
  event_user VARCHAR2(100) NOT NULL,
  event_date DATE NOT NULL,
  table_owner CONSTRAINT fk_audit_events_data_tab_owner REFERENCES audit_names_data(audit_name_id),
  table_name CONSTRAINT fk_audit_events_data_tab_name REFERENCES audit_names_data(audit_name_id),
  row_id VARCHAR2(&max_varchar_col_length.) NOT NULL,
  reason VARCHAR2(&max_varchar_col_length.),
  transaction_id VARCHAR2(&max_varchar_col_length.),
  CONSTRAINT pk_audit_events_data PRIMARY KEY (event_id)  
);


PROMPT Creating sequence audit_event_id

CREATE SEQUENCE audit_event_id
  MINVALUE 0
  MAXVALUE 99999999999999999999999999
  START WITH 0
  INCREMENT BY 1
  CACHE 10
  CYCLE
  ORDER;


PROMPT Creating table audit_changes_data

CREATE TABLE audit_changes_data(
  event_id CONSTRAINT fk_audit_changes_data REFERENCES audit_events_data(event_id),
  column_name CONSTRAINT fk_audit_changes_data_col_name REFERENCES audit_names_data(audit_name_id),
  old_value VARCHAR2(&max_varchar_col_length.),
  new_value VARCHAR2(&max_varchar_col_length.),
  CONSTRAINT pk_audit_changes_data PRIMARY KEY (event_id, column_name)
);


PROMPT Creating view audit_view

CREATE OR REPLACE VIEW audit_view
AS
SELECT e.event_id,
       DECODE(
         e.event_type_id, 
         1, 'Delete',  
         2, 'Insert',
         3, 'Update') AS event_type,
       e.event_user,
       e.event_date,
       (SELECT audit_name 
          FROM audit_names_data 
         WHERE audit_name_id = e.table_owner) AS table_owner,
       (SELECT audit_name 
          FROM audit_names_data 
         WHERE audit_name_id = e.table_name) AS table_name,
       e.row_id,
       (SELECT audit_name 
          FROM audit_names_data 
         WHERE audit_name_id = c.column_name) AS column_name,
       c.old_value,
       c.new_value,
       e.reason,
       e.transaction_id
  FROM audit_events_data e,
       audit_changes_data c
 WHERE e.event_id = c.event_id(+)
 ORDER BY e.event_id, c.column_name;


PROMPT Creating auditer package

@@auditer.pck


PROMPT ___ End of audit build.sql ___
