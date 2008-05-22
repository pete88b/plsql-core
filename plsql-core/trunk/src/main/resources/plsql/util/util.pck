CREATE OR REPLACE PACKAGE util
IS
  /*
  Define SYS_REFCURSOR so this package can be used in pre-10g databases.
  */
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  FUNCTION dummy_cursor
  RETURN SYS_REFCURSOR;
  
  PROCEDURE drop_if_exists(
    p_type_and_name IN VARCHAR2
  );
  
END util;
/
CREATE OR REPLACE PACKAGE BODY util
IS

  FUNCTION dummy_cursor
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;
  BEGIN
    OPEN l_result FOR
    SELECT NULL FROM DUAL WHERE 1=2;
    RETURN l_result;
  END;
  
  PROCEDURE drop_if_exists(
    p_type_and_name IN VARCHAR2
  )
  IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP ' || p_type_and_name;
    
  EXCEPTION
    WHEN exceptions.table_or_view_not_found
    THEN
      NULL;
      
    WHEN exceptions.sequence_not_found
    THEN
      NULL;
      
    WHEN exceptions.object_not_found
    THEN
      NULL;
      
    WHEN exceptions.trigger_not_found
    THEN
      NULL;
      
  END drop_if_exists;
  
END util;
/
