DECLARE
  t types.max_varchar2_table_type;
  
  l_transaction_id VARCHAR2(32767);
  
  l_max_name_length INTEGER := 1000;
  
  l_event_name VARCHAR2(32767) := 'test_event';
  l_test_observer VARCHAR2(32767) := 'test_observer';
  l_real_observer VARCHAR2(32767) := 'logger_utils';
  
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
  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2  := NULL
  )
  IS
  BEGIN
    IF (p_condition IS NULL OR NOT p_condition)
    THEN
      assertion_failure(p_message || ' (assert.is_true: assertion error)');
    END IF;
         
  END assert;
  
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
  p('Running PL/SQL test script for event_monitor');
  p('Start time: ' || TO_CHAR(SYSDATE, 'dd-Mon-yyyy hh24:mi:ss'));
  p('');
  
  event_mediator.remove_observers;
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data',
    'no observers should be registered for any events. Clear all observers before starting test');
  
  p('testing add_observer');
  
  assert_raises_exception(
    'event_mediator.add_observer(RPAD(1, ' || l_max_name_length || ' + 1, 2), ''' || l_test_observer ||''');',
    NULL,
    'value too large');
  
  assert_raises_exception(
    'event_mediator.add_observer(''' || l_event_name ||''', RPAD(1, ' || l_max_name_length || '+ 1, 2));',
    NULL,
    'value too large');
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should not yet be registered');
  
  event_mediator.add_observer(l_event_name, l_test_observer);
  
  assert(
    dbms_transaction.local_transaction_id IS NULL,
    'adding an observer should not have started a transaction');
    
  ROLLBACK; -- should have no effect on add_observer
  
  assert_one_row(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should be registered');
  
  assert_raises_exception(
    'event_mediator.add_observer(''' || l_event_name ||''', ''' || l_test_observer || ''');',
    -1);
  
  event_mediator.remove_observer(l_event_name, l_test_observer);
  
  -- start a transaction. Note: we need logger_flags to exist for this to work
  UPDATE logger_flags
  SET    log_user = log_user;
  
  l_transaction_id := dbms_transaction.local_transaction_id;
  
  assert(
    l_transaction_id IS NOT NULL,
    'transaction should not be null');
    
  event_mediator.add_observer(UPPER(l_event_name), l_test_observer);
  
  assert(
    l_transaction_id = dbms_transaction.local_transaction_id,
    'add_observer should not end the transaction');
  
  l_transaction_id := NULL;
  
  ROLLBACK;
  
  assert_one_row(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should be registered');
  
  assert_raises_exception(
    'event_mediator.add_observer(''' || l_event_name ||''', ''' || l_test_observer || ''');',
    -1);
    
  event_mediator.remove_observer(l_event_name, l_test_observer);
  
  event_mediator.add_observer(l_event_name, UPPER(l_test_observer));
  ROLLBACK;
  
  assert_one_row(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should be registered');
    
  assert_raises_exception(
    'event_mediator.add_observer(''' || UPPER(l_event_name) ||''', ''' || l_test_observer || ''');',
    -1);
    
  event_mediator.remove_observer(l_event_name, l_test_observer);
  
  event_mediator.add_observer(UPPER(l_event_name), UPPER(l_test_observer));
  ROLLBACK;
  
  assert_one_row(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should be registered');
    
  assert_raises_exception(
    'event_mediator.add_observer(''' || l_event_name ||''', ''' || l_test_observer || ''');',
    -1);
    
  event_mediator.remove_observer(l_event_name, UPPER(l_test_observer));
    
  p('add_observer: ok');
  --------------------------------------------------
  p('testing remove_observer');
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should not yet be registered');
  
  event_mediator.remove_observer(l_event_name, l_test_observer);
  
  assert(
    dbms_transaction.local_transaction_id IS NULL,
    'removing an observer should not have started a transaction');
  
  event_mediator.add_observer(UPPER(l_event_name), UPPER(l_test_observer));
  
  assert_one_row(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should be registered');
  
  event_mediator.remove_observer(l_event_name, l_test_observer);
  
  assert(
    dbms_transaction.local_transaction_id IS NULL,
    'removing an observer should not have started a transaction');
    
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should not yet be registered');
    
  FOR i IN 1 .. 9
  LOOP
    event_mediator.remove_observer(l_event_name, l_test_observer);
  END LOOP;
  
  event_mediator.add_observer(UPPER(l_event_name), UPPER(l_test_observer));
  
  -- start a transaction
  UPDATE logger_flags
  SET    log_user = log_user;
  
  l_transaction_id := dbms_transaction.local_transaction_id;
  
  assert(
    l_transaction_id IS NOT NULL,
    'transaction should not be null');
    
  event_mediator.remove_observer(l_event_name, l_test_observer);
  
  assert(
    l_transaction_id = dbms_transaction.local_transaction_id,
    'remove_observer should not end the transaction');
  
  l_transaction_id := NULL;
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should not yet be registered');
  
  ROLLBACK;
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  event_name = ''' || l_event_name || '''
     AND    observer = ''' || l_test_observer || '''',
    'event should not yet be registered');
    
  p('remove_observer: ok');
  --------------------------------------------------
  p('testing remove_observer');
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  observer = ''' || l_test_observer || '''',
    'observer should not be registered for any events');
  
  event_mediator.remove_observer(l_test_observer);
  
  assert(
    dbms_transaction.local_transaction_id IS NULL,
    'removing an observer should not have started a transaction');
  
  -- start a transaction
  UPDATE logger_flags
  SET    log_user = log_user;
  
  l_transaction_id := dbms_transaction.local_transaction_id;
  
  assert(
    l_transaction_id IS NOT NULL,
    'transaction should not be null');
    
  event_mediator.remove_observer(l_test_observer);
  
  assert(
    l_transaction_id = dbms_transaction.local_transaction_id,
    'remove_observer should not end the transaction');
  
  l_transaction_id := NULL;
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  observer = ''' || l_test_observer || '''',
    'observer should not be registered for any events');
  
  ROLLBACK;
  
  FOR i IN 1 .. 9
  LOOP
    event_mediator.add_observer(l_event_name || i, l_test_observer);
  END LOOP;
  
  SELECT COUNT(*)
  INTO   l_count
  FROM   event_mediator_data
  WHERE  observer = l_test_observer;
  
  assert(
    l_count = 9,
    'observer should be registered for 9 events');
  
  event_mediator.remove_observer(l_test_observer);
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data
     WHERE  observer = ''' || l_test_observer || '''',
    'observer should not be registered for any events');
  
  p('remove_observer2: ok');
  --------------------------------------------------
  p('testing remove_observers');
  
  event_mediator.remove_observers;
  
  assert(
    dbms_transaction.local_transaction_id IS NULL,
    'removing observers should not have started a transaction');
  
  -- start a transaction
  UPDATE logger_flags
  SET    log_user = log_user;
  
  l_transaction_id := dbms_transaction.local_transaction_id;
  
  assert(
    l_transaction_id IS NOT NULL,
    'transaction should not be null');
    
  event_mediator.remove_observers;
  
  assert(
    l_transaction_id = dbms_transaction.local_transaction_id,
    'remove_observers should not end the transaction');
  
  l_transaction_id := NULL;
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data',
    'no observers should be registered for any events');
  
  ROLLBACK;
  
  FOR i IN 1 .. 9
  LOOP
    FOR j IN 1 .. 9
    LOOP
      event_mediator.add_observer(l_event_name || i, l_test_observer || j);
    END LOOP;
  END LOOP;
  
  SELECT COUNT(*)
  INTO   l_count
  FROM   event_mediator_data;
  
  assert(
    l_count = 81,
    '81 events should be registered. found ' || l_count);
    
  event_mediator.remove_observers;
  
  assert_no_rows(
    'SELECT NULL
     FROM   event_mediator_data',
    'no observers should be registered for any events');
  
  p('remove_observers: ok');
  
  p('testing event');
  
  --no observers            done
  --one observer ok/fail    done ok/fail
  --many observers ok/fail  done ok
  
  --fail on error. for all above
  
  -- no observers
  event_mediator.event(l_event_name, 'xxx', TRUE);
  event_mediator.event(l_event_name, 'xxx', FALSE);
  
  -- no observers - fail if no observers
  BEGIN
    event_mediator.event(l_event_name, 'xxx', TRUE, TRUE);
    assertion_failure('Should have raised e_no_observers (1)');
  EXCEPTION 
    WHEN event_mediator.e_no_observers
    THEN 
      NULL;
      
  END;
  
  BEGIN
    event_mediator.event(l_event_name, 'xxx', FALSE, TRUE);
    assertion_failure('Should have raised e_no_observers (2)');
  EXCEPTION 
    WHEN event_mediator.e_no_observers
    THEN 
      NULL;
      
  END;
  
  EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_error_data';
  
  event_mediator.add_observer(l_event_name, l_test_observer);
  
  -- one observer. fail
  assert_raises_exception(
    'event_mediator.event(''' || l_event_name || ''', ''xxx'', TRUE);',
    -06550,
    '%XXX%must be declared');
  
  assert_one_row(
    'SELECT NULL
     FROM   logger_error_data
     WHERE  error_code = -06550
     AND    log_data = ''failed to execute test_observer.xxx''',
    'failed call should have been logged (1)');
    
  EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_error_data';
    
  event_mediator.event(l_event_name, 'xxx', FALSE);
  
  assert_one_row(
    'SELECT NULL
     FROM   logger_error_data
     WHERE  error_code = -06550
     AND    log_data = ''failed to execute test_observer.xxx''',
    'failed call should have been logged (2)');
    
  -- one observer. success
  event_mediator.remove_observers;
  event_mediator.add_observer(l_event_name, l_real_observer);
  
  logger_utils.set_user('userOne');
  
  assert(
    logger_utils.get_user = 'userOne',
    'failed to set user on logger_utils');
  
  FOR i IN 1 .. 18
  LOOP
    event_mediator.event(l_event_name, 'set_user(''userTwo' || i || ''')', i < 10);
    
    assert(
      logger_utils.get_user = 'userTwo' || i,
      'failed to set user on logger_utils via event');
      
  END LOOP;
    
  -- many observers. success
  EXECUTE IMMEDIATE '
    CREATE OR REPLACE PACKAGE ' || l_test_observer || '
    IS
      PROCEDURE set_user(
        p_user IN VARCHAR2);
    END;';
    
  EXECUTE IMMEDIATE '
    CREATE OR REPLACE PACKAGE BODY ' || l_test_observer || '
    IS
      PROCEDURE set_user(
        p_user IN VARCHAR2)
      IS
      BEGIN
        dbms_application_info.set_client_info(p_user);
      END set_user;
    END;';
    
  event_mediator.add_observer(l_event_name, l_test_observer);
  
  FOR i IN 1 .. 18
  LOOP
    event_mediator.event(l_event_name, 'set_user(''userTwo' || i || ''')', i < 10);
    
    assert(
      logger_utils.get_user = 'userTwo' || i,
      'failed to set user on logger_utils via event');
      
    dbms_application_info.read_client_info(t(1));
    
    assert(
      t(1) = 'userTwo' || i,
      'failed to set user on logger_utils via event');
      
  END LOOP;
    
  -- many observers: fail
  EXECUTE IMMEDIATE '
    CREATE OR REPLACE PACKAGE BODY ' || l_test_observer || '
    IS
      PROCEDURE set_user(
        p_user IN VARCHAR2)
      IS
      BEGIN
        raise_application_error(-20209, ''fail message from set_user'');
      END set_user;
    END;';
    
  EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_error_data';
  
  assert_raises_exception(
    'event_mediator.event(''' || l_event_name || ''', ''set_user(NULL)'', TRUE);',
    -20209,
    'fail message from set_user');
    
  assert_one_row(
    'SELECT NULL
     FROM   logger_error_data
     WHERE  error_code = -20209
     AND    error_message LIKE ''%fail message from set_user''',
    'failed call should have been logged (3)');
    
  EXECUTE IMMEDIATE 'TRUNCATE TABLE logger_error_data';
    
  event_mediator.event(l_event_name, 'set_user(NULL)', FALSE);
  
  assert_one_row(
    'SELECT NULL
     FROM   logger_error_data
     WHERE  error_code = -20209
     AND    error_message LIKE ''%fail message from set_user''',
    'failed call should have been logged (4)');
      
  EXECUTE IMMEDIATE 'DROP PACKAGE ' || l_test_observer;
    
  p('event: ok');
  
END;