/*
  Build script for value groups.

  Depends on: logger.
  Depends on: exceptions.
  Depends on: messages.
  Depends on: properties.
  Depends on: util.
*/

PROMPT ___ Start of value groups build.sql ___


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
    drop_object('TABLE value_group_values_data');
    drop_object('TABLE value_groups_data');
    
  END IF;
END;
/


PROMPT Creating table value_groups

CREATE TABLE value_groups_data(
  group_name VARCHAR2(100),
  description VARCHAR2(2000),
  values_sql VARCHAR2(4000),
  CONSTRAINT value_groups_pk PRIMARY KEY(group_name)
);

PROMPT Creating table value_groups_values

CREATE TABLE value_group_values_data(
  group_name REFERENCES value_groups_data(group_name),
  value VARCHAR2(2000),
  label VARCHAR2(2000),
  description VARCHAR2(2000),
  enabled VARCHAR2(1)
);

PROMPT Creating index for table value_groups_values

CREATE UNIQUE INDEX value_group_values_unique 
ON value_group_values_data (group_name, value);

PROMPT Creating value group package specification
@@value_group.spc

PROMPT Creating value groups package specification
@@value_groups.spc

PROMPT Creating value group values package specification
@@value_group_value.spc
  
  
PROMPT Creating value group package body
@@value_group.bdy

PROMPT Creating value groups package body
@@value_groups.bdy

PROMPT Creating value group values package body
@@value_group_value.bdy

PROMPT ___ End of value groups build.sql ___
