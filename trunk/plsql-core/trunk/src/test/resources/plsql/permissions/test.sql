DECLARE
  
  PROCEDURE c(
    s IN VARCHAR2
  )
  IS
  BEGIN
    permission.create_permission(s, 'desc of ' || s, 0);
  
  END;
    
BEGIN
  DELETE FROM permission_sets;
  DELETE FROM permissions_data;
  
  COMMIT;
  
  permission.delete_permission('admin'); -- permission not found
  
  c('admin');
  
  c('admin'); -- permission already exists. message
  
  permission.delete_permission('admin');
  c('admin');
  
  c('super admin');
  c('dvm users');
  
  c('create query');
  c('send query');
  c('update query');
  
  c('delete query');
  
  c('delete project');
  
  permission.allow('super admin', 'delete project');
  
  permission.set_permission_status('admin', permission.status_no_allow);
  BEGIN
    permission.allow('super admin', 'admin');
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.allow('admin', 'dvm users');
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.deny('admin', 'dvm users');
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  permission.set_permission_status('admin', permission.status_no_change);
  
  permission.allow('super admin', 'admin');
  
  BEGIN
    permission.allow('admin', 'dvm users');
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.deny('admin', 'dvm users');
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  permission.set_permission_status('admin', permission.status_no_delete);
  
  permission.delete_permission('admin');
  
  permission.set_permission_status('admin', permission.status_no_restrictions);
  
  permission.allow('admin', 'dvm users');
  
  permission.set_permission_status('admin', permission.status_no_deny);
  BEGIN
    permission.deny('admin', 'dvm users');
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  permission.set_permission_status('admin', permission.status_no_restrictions);
  
  permission.allow('admin', 'delete query');
  
  permission.allow('dvm users', 'create query');
  permission.allow('dvm users', 'send query');
  permission.allow('dvm users', 'update query');
  
  assert.is_true(
    permission.is_allowed('super admin', 'send query') = constants.yes,
    'super admin should be allowed to send query');
  
  assert.is_true(
    permission.is_allowed('admin', 'send query') = constants.yes,
    'admin should be allowed to send query');
    
  assert.is_true(
    permission.is_allowed('admin', 'dvm users') = constants.yes,
    'admin should be allowed to do what dvm users do');
  
  assert.is_true(
    permission.is_allowed('admin', 'admin') = constants.yes,
    'admin should be allowed to do what admin do');
  
  assert.is_true(
    permission.is_allowed('admin', 'super admin') = constants.no,
    'admin should be not allowed to do what super admin do');
  
  assert.is_true(
    permission.is_allowed('admin', 'super duper admin') = constants.no, -- super duper admin is not a permission
    'super duper admin is not a permission');
  
  assert.is_true(
    permission.is_allowed('super duper admin', 'send query') = constants.no,
    'send query is not a set');
  
  assert.is_true(
    permission.is_allowed('dvm users', 'admin') = constants.no,
    'dvm users should be allowed to do what admin do');
  
  assert.is_true(
    permission.is_allowed('dvm users', 'create query') = constants.yes,
    'dvm users should be allowed to create query');
  
  BEGIN
    permission.set_permission_status('x', 8); -- invalid permission name
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.set_permission_status('dvm users', 8); -- invalid status
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.allow('admin', 'admin'); -- set_cant_allow_self
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  
  -- create a simple recursive set
  c('a');
  c('b');
  c('c');
  
  permission.allow('a', 'b');
  
  BEGIN
    permission.allow('a', 'b'); -- duplicate allow
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.allow('b', 'a'); -- permission loop
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  permission.allow('b', 'c'); 
  
  BEGIN
    permission.allow('c', 'a'); -- permission loop
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  BEGIN
    permission.allow('c', 'b'); -- permission loop
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  permission.deny('b', 'c');
  permission.allow('c', 'a'); 

  BEGIN
    permission.allow('b', 'c'); -- permission loop
    RAISE NOT_LOGGED_ON;
  EXCEPTION
    WHEN NOT_LOGGED_ON THEN RAISE;
    WHEN OTHERS THEN NULL;
  END;
  
  FOR I IN 1 .. 0--9
  LOOP
    c('d-' || i);
  END LOOP;
  
END;