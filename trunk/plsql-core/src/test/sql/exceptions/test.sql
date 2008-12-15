-- exceptions test
DECLARE
  PROCEDURE p(
    p_data IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_data);
    
  END;
  
  PROCEDURE fail(
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20111, p_message);
    
  END;
  
  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2 := NULL
  )
  IS
  BEGIN
    IF (p_condition)
    THEN
      NULL;
    ELSE
      fail(NVL(p_message, 'assertion error'));
      
    END IF;
    
  END;
  
  PROCEDURE drop_exceptions_test
  IS
    PROCEDURE e(
      p_sql IN VARCHAR2
    )
    IS
    BEGIN
      EXECUTE IMMEDIATE p_sql;
    EXCEPTION
      WHEN OTHERS
      THEN
        NULL;
    END;
  BEGIN
    e('DROP TABLE exceptions_test');
    e('DROP PROCEDURE exceptions_test');
    
  END;
  
  PROCEDURE exec(
    p_sql IN VARCHAR2
  )
  IS
  BEGIN
    p(p_sql);
    EXECUTE IMMEDIATE p_sql;
  END;
  
BEGIN
  drop_exceptions_test;
  
  exec('
    CREATE TABLE exceptions_test(
      a VARCHAR2(100),
      b VARCHAR2(100) CONSTRAINT exceptions_test_nn NOT NULL,
      c CONSTRAINT exceptions_test_fk REFERENCES exceptions_test(a),
      CONSTRAINT exceptions_test_pk PRIMARY KEY (a),
      CONSTRAINT exceptions_test_check CHECK (a != ''fail'')
    )');
    
  -- check_constraint_violated section
  BEGIN
    exec('
      INSERT INTO exceptions_test(
        a, b)
      VALUES(
        ''fail'', ''fail'')');
        
    fail('f1');
        
  EXCEPTION
    WHEN exceptions.check_constraint_violated
    THEN
      NULL;
      
  END;
  
  
  -- parent_key_not_found section
  DECLARE
    l_sql VARCHAR2(32767) := '
      INSERT INTO exceptions_test(
        a, b, c)
      VALUES(
        ''a'', ''b'', ''c'')'; 
        
  BEGIN
    exec(l_sql);
    fail('f2');
        
  EXCEPTION
    WHEN exceptions.parent_key_not_found
    THEN
      NULL;
      
  END;
  
  
  -- child_record_found section
  BEGIN
    exec('
      INSERT INTO exceptions_test(
        a, b)
      VALUES(
        ''a'', ''b'')');
        
    exec('
      INSERT INTO exceptions_test(
        a, b, c)
      VALUES(
        ''a2'', ''b2'', ''a'')');
        
    exec('DELETE FROM exceptions_test WHERE a = ''a''');
    
    fail('f3');
        
  EXCEPTION
    WHEN exceptions.child_record_found
    THEN
      NULL;
      
  END;
  
  
  -- cannot_insert_null section
  BEGIN
    exec('
      INSERT INTO exceptions_test(
        a, b)
      VALUES(
        ''c'', NULL)');
        
    fail('f4');
        
  EXCEPTION
    WHEN exceptions.cannot_insert_null
    THEN
      NULL;
      
  END;
  
  
  -- name_already_used section
  BEGIN
    exec('CREATE TABLE exceptions_test(a VARCHAR2(100))');
    fail('f5');
        
  EXCEPTION
    WHEN exceptions.name_already_used
    THEN
      NULL;
      
  END;
  
  
  -- table_or_view_not_found section
  BEGIN
    exec('DROP TABLE exceptions_test');
    exec('DROP TABLE exceptions_test');
    fail('f6');
        
  EXCEPTION
    WHEN exceptions.table_or_view_not_found
    THEN
      NULL;
      
  END;
  
  
  -- sequence_not_found section
  BEGIN
    exec('DROP SEQUENCE exceptions_test');
    fail('f7');
        
  EXCEPTION
    WHEN exceptions.sequence_not_found
    THEN
      NULL;
      
  END;
  
  
  -- object_not_found section
  BEGIN
    exec('DROP PACKAGE exceptions_test');
    fail('f8');
        
  EXCEPTION
    WHEN exceptions.object_not_found
    THEN
      NULL;
      
  END;
  
  
  -- trigger_not_found section
  BEGIN
    exec('DROP TRIGGER exceptions_test');
    fail('f9');
        
  EXCEPTION
    WHEN exceptions.trigger_not_found
    THEN
      NULL;
      
  END;
  
  
  -- success_with_compilation_err section
  BEGIN
    drop_exceptions_test;
    exec('CREATE PROCEDURE exceptions_test');
    fail('f10');
        
  EXCEPTION
    WHEN exceptions.success_with_compilation_err
    THEN
      drop_exceptions_test;
      
  END;
  
  
  -- application problem section
  assert(exceptions.application_problem_code = -20000);
  
  BEGIN
    exceptions.throw_problem('test problem message');
    fail('a');
    
  EXCEPTION
    WHEN exceptions.application_problem
    THEN
      NULL;
      
  END;

  -- application error section
  assert(exceptions.application_error_code = -20999);
  
  BEGIN
    exceptions.throw_error('test error message');
    fail('b');
    
  EXCEPTION
    WHEN exceptions.application_error
    THEN
      NULL;
      
  END;

  -- cannot be null section
  assert(exceptions.cannot_be_null_code = -20001);
  
  BEGIN
    exceptions.throw_if_null('not null', 'test item');
    exceptions.throw_if_null('', 'test item');
    fail('c');
    
  EXCEPTION
    WHEN exceptions.cannot_be_null
    THEN
      NULL;
      
  END;
  
  -- condition not true section
  assert(exceptions.condition_not_true_code = -20002);
  
  BEGIN
    exceptions.throw_if_not_true(TRUE, 'test message (throw_if_not_true TRUE)');
    exceptions.throw_if_not_true(FALSE, 'test message (throw_if_not_true FALSE)');
    fail('d');
    
  EXCEPTION
    WHEN exceptions.condition_not_true
    THEN
      NULL;
      
  END;
  
  BEGIN
    exceptions.throw_if_not_true(NULL, 'test message (throw_if_not_true NULL)');
    fail('e');
    
  EXCEPTION
    WHEN exceptions.condition_not_true
    THEN
      NULL;
      
  END;
  
END;
