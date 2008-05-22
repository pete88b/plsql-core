CREATE OR REPLACE PACKAGE auditer 
IS

  /*
  */
  PROCEDURE set_user(
    p_user IN VARCHAR2
  );

  /*
  */
  FUNCTION get_user
  RETURN VARCHAR2;
  
  /*
  */
  PROCEDURE new_event(
    p_event_id OUT audit_events_data.event_id%TYPE,
    p_event_type_id IN audit_events_data.event_type_id%TYPE,
    p_table_owner IN audit_events_data.table_owner%TYPE,
    p_table_name IN audit_events_data.table_name%TYPE,
    p_row_id audit_events_data.row_id%TYPE
  );
  
  PROCEDURE new_change(
    p_event_id IN audit_changes_data.event_id%TYPE,
    p_column_name IN audit_changes_data.column_name%TYPE,
    p_old_value IN VARCHAR2,
    p_new_value IN VARCHAR2
  );
  
END auditer;
/
CREATE OR REPLACE PACKAGE BODY auditer 
IS

  -- The name of the current user
  g_user VARCHAR2(32767) := USER;


  /*
  */
  PROCEDURE set_user(
    p_user IN VARCHAR2)
  IS
  BEGIN
    g_user := p_user;
  END set_user;


  /*
  */
  FUNCTION get_user
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_user;
  END get_user;
  
  /*
  */
  PROCEDURE new_event(
    p_event_id OUT audit_events_data.event_id%TYPE,
    p_event_type_id IN audit_events_data.event_type_id%TYPE,
    p_table_owner IN audit_events_data.table_owner%TYPE,
    p_table_name IN audit_events_data.table_name%TYPE,
    p_row_id audit_events_data.row_id%TYPE
  )
  IS
  BEGIN
    logger.ms('new_event');
    
    INSERT INTO audit_events_data(
      event_id, event_type_id, 
      event_user, event_date,
      table_owner, table_name, row_id)
    VALUES (
      audit_event_id.NEXTVAL, p_event_type_id,
      get_user, SYSDATE,
      p_table_owner, p_table_name, p_row_id)
    RETURNING event_id INTO p_event_id;
  
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('failed to save new event');
      RAISE;
        
  END new_event;
  
  /*
  */
  PROCEDURE new_change(
    p_event_id IN audit_changes_data.event_id%TYPE,
    p_column_name IN audit_changes_data.column_name%TYPE,
    p_old_value IN VARCHAR2,
    p_new_value IN VARCHAR2
  )
  IS
  BEGIN
    logger.ms('new_change (VARCHAR2)');
    
    INSERT INTO audit_changes_data(
      event_id, column_name, old_value, new_value)
    VALUES(
      p_event_id, p_column_name, p_old_value, p_new_value);
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('failed to save new change (VARCHAR2)');
      RAISE;
     
  END new_change;
  
END auditer;
/
