DECLARE
  t types.max_varchar2_table_type;
  
  l_transaction_id VARCHAR2(32767);
  
  l_max_name_length INTEGER := 1000;
  
  TYPE SYS_REFCURSOR IS REF CURSOR;
  
  e_assertion_error EXCEPTION;
  
  l_count INTEGER;
  
  /*
  */
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    IF (LENGTH(s) > 255)
    THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR(s, 1, 252) || '...');
    ELSE
      DBMS_OUTPUT.PUT_LINE(s);
    END IF;
  END p;
  
  /*
  */
  PROCEDURE assertion_failure(
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20000, p_message);
      
  END assertion_failure;

  /*
  */
  PROCEDURE local_assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2  := NULL
  )
  IS
  BEGIN
    IF (p_condition IS NULL OR NOT p_condition)
    THEN
      assertion_failure(p_message || ' (assert.is_true: assertion error)');
    END IF;
         
  END local_assert;
  
  /*
  */
  PROCEDURE assert_no_rows(
    p_sql IN VARCHAR2,
    p_message IN VARCHAR2 := NULL
  )
  IS
    l_cursor SYS_REFCURSOR;
    l_dummy INTEGER;
    
  BEGIN
    OPEN l_cursor FOR 'SELECT NULL FROM (' || p_sql || ')';
    
    FETCH l_cursor INTO l_dummy;
    
    IF (l_cursor%FOUND)
    THEN
      assertion_failure(p_message || ' (assert.no_rows: at least one row found)');
      
    END IF;
    
  END assert_no_rows;
  
  /*
  */
  PROCEDURE assert_one_row(
    p_sql IN VARCHAR2,
    p_message IN VARCHAR2 := NULL
  )
  IS
    l_cursor SYS_REFCURSOR;
    l_dummy INTEGER;
    
  BEGIN
    OPEN l_cursor FOR 'SELECT NULL FROM (' || p_sql || ')';
    
    FETCH l_cursor INTO l_dummy;
    
    IF (l_cursor%NOTFOUND)
    THEN
      assertion_failure(p_message || ' (assert.one_row: no rows found)');
      
    END IF;
    
    FETCH l_cursor INTO l_dummy;
    
    IF (l_cursor%FOUND)
    THEN
      assertion_failure(p_message || ' (assert.one_row: more than one row found)');
      
    END IF;
    
  END assert_one_row;
  
  /*
  */
  PROCEDURE assert_raises_exception(
    p_plsql IN VARCHAR2,
    p_sqlcode IN INTEGER := NULL,
    p_sqlerrm IN VARCHAR2 := NULL,
    p_message IN VARCHAR2 := NULL
  )
  IS
  BEGIN
    EXECUTE IMMEDIATE 
      'DECLARE ' ||
      '  TYPE l_array_type IS TABLE OF VARCHAR2(32767) ' ||
      '  INDEX BY BINARY_INTEGER; ' ||
      '  l_array l_array_type; ' ||
      '  t types.max_varchar2_table_type; ' ||
      '  TYPE SYS_REFCURSOR IS REF CURSOR; ' ||
      '  l_cur SYS_REFCURSOR; ' ||
      'BEGIN ' || 
      p_plsql || ' ' ||
      'END;';
    
    RAISE e_assertion_error;
    
  EXCEPTION
    WHEN e_assertion_error
    THEN
      assertion_failure(p_message || ' (assert.raises_exception: no exception raised)');
      
    WHEN OTHERS
    THEN
      IF (p_sqlcode IS NOT NULL AND p_sqlcode != SQLCODE)
      THEN
        p(SQLERRM);
        assertion_failure(p_message || ' (assert.raises_exception: ' ||
          'expected sqlcode=' || p_sqlcode ||
          '. found sqlcode=' || SQLCODE || ')');
          
      END IF;
      
      IF (p_sqlerrm IS NOT NULL AND SQLERRM NOT LIKE '%' || p_sqlerrm || '%')
      THEN
        assertion_failure(p_message || ' (assert.raises_exception: ' ||
          'expected sqlerrm=' || p_sqlerrm ||
          '. found sqlerrm=' || SQLERRM || ')');

      END IF;
    
  END assert_raises_exception;
  
BEGIN
  p('Running PL/SQL test script for assert');
  p('Start time: ' || TO_CHAR(SYSDATE, 'dd-Mon-yyyy hh24:mi:ss'));
  p('');
  
  
    
  p('testing is_equal');
  
  -- local assert_raises_exception is a bit slow
  /*
  FOR i IN 0 .. 126
  LOOP
    FOR j IN 0 .. 126
    LOOP
      IF (i = j)
      THEN
        assert.is_equal(CHR(i), CHR(j));
        
      ELSE
        assert_raises_exception(
          'assert.is_equal(CHR(' || i || '), CHR(' || j || '));');
          
      END IF;
      
    END LOOP;
    
  END LOOP;
  */
  p('is_equal ok');
  
END;