/*
  Build script for event mediator.

  Depends on: logger.
*/

PROMPT ___ Start of event mediator build.sql ___

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
    drop_object('TABLE event_mediator_data');

  END IF;
END;
/


PROMPT Creating table event_mediator_data

CREATE TABLE event_mediator_data(
  event_name VARCHAR2(1000),
  observer VARCHAR2(1000),
  CONSTRAINT event_mediator_data_pk PRIMARY KEY (event_name, observer)
);

PROMPT Creating event mediator package
@@event_mediator.pck

PROMPT ___ End of event mediator build.sql ___