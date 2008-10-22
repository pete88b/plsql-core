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

CREATE OR REPLACE PACKAGE auditer 
IS
  
  /*
    The auditer package help record changes made to table data.
    
    To enable auditing for a table run the script create_audit_trigger.sql.
    
    It is expected that application code will call the set_user procedure,
    (to tell auditer who's making chanages) and set_reason (to tell
    auditer why a change is being made).
    
    It is expected that application code will not make use of new_event
    or new change directly - these will be called by the audit (a$) 
    triggers created by the create_audit_trigger.sql script.
  */

  /*
    Sets the name of the current user.
    
    This is the name that will be associated with events created by this session.
    
    Until this procedure is called the current user is assumed to be USER.
  */
  PROCEDURE set_user(
    p_user IN VARCHAR2
  );

  /*
    Returns the name of the current user.
  */
  FUNCTION get_user
  RETURN VARCHAR2;
  
  /*
    Sets the reason for all events that follow this call until the
    current transaction ends (i.e with a ROLLBACK or COMMIT).
  */
  PROCEDURE set_reason(
    p_reason IN VARCHAR2
  );

  /*
    Returns the reason for events that follow a previous set_reason call.
  */
  FUNCTION get_reason
  RETURN VARCHAR2;
  
  /*
    Records a new event (i.e. an INSERT, UPDATE or DELETE).
    
    It is expected that this procedure will be called by the a$ triggers
    created by the create_audit_trigger.sql script.
    
    Parameters:
      p_event_id 
        Returns the ID of the event.
        
      p_event_type_id
        The type of event.
        Valid values for p_event_type_id are:
          1 for DELETE,
          2 for INSERT or
          3 for UPDATE.
          
      p_table_owner
        The owner of the table upon which the event occured.
        This should be an audit_name_id from the table audit_names_data.
        
      p_table_name
        The name of the table upon which the event occured.
        This should be an audit_name_id from the table audit_names_data.
        
      p_row_id
        The ID of the row upon which the event occured.
  */
  PROCEDURE new_event(
    p_event_id OUT audit_events_data.event_id%TYPE,
    p_event_type_id IN audit_events_data.event_type_id%TYPE,
    p_table_owner IN audit_events_data.table_owner%TYPE,
    p_table_name IN audit_events_data.table_name%TYPE,
    p_row_id IN audit_events_data.row_id%TYPE
  );
  
  /*
    Records a new change (that is part of an event).
    
    It is expected that this procedure will be called by the a$ triggers
    created by the create_audit_trigger.sql script.
    
    Calling this procedure will record a change even if old and new 
    values are the same. 
    It is up to the caller of this procedure to determine if there has 
    been a change or not.
    
    Parameters:
      p_event_id 
        The ID of the event as returned by new_event.
        
      p_column_name
        The name of the column who's value has changed.
        This should be an audit_name_id from the table audit_names_data.
        
      p_old_value
        The old value.
        
      p_new_value
        The new value.
  */
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
  PROCEDURE set_reason(
    p_reason IN VARCHAR2)
  IS
  BEGIN
    logger.entering('set_reason');
    
    DELETE FROM audit_reason_data;
    
    INSERT INTO audit_reason_data(
      reason)
    VALUES(
      p_reason
    );
    
  END set_reason;

  /*
  */
  FUNCTION get_reason
  RETURN VARCHAR2
  IS
    l_reason audit_reason_data.reason%TYPE;
    
  BEGIN
    logger.entering('get_reason');
    
    SELECT 
      reason
    INTO 
      l_reason
    FROM 
      audit_reason_data;
      
    RETURN l_reason;
    
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      RETURN NULL;
      
    WHEN TOO_MANY_ROWS
    THEN
      logger.error('Found more than one row in audit_reason_data');
      RETURN NULL;
      
  END get_reason;
  
  /*
  */
  PROCEDURE new_event(
    p_event_id OUT audit_events_data.event_id%TYPE,
    p_event_type_id IN audit_events_data.event_type_id%TYPE,
    p_table_owner IN audit_events_data.table_owner%TYPE,
    p_table_name IN audit_events_data.table_name%TYPE,
    p_row_id IN audit_events_data.row_id%TYPE
  )
  IS
  BEGIN
    logger.entering('new_event');
    
    INSERT INTO audit_events_data(
      event_id, event_type_id, 
      event_user, event_date,
      table_owner, table_name, 
      row_id, reason,
      transaction_id)
    VALUES (
      audit_event_id.NEXTVAL, p_event_type_id,
      get_user, SYSDATE,
      p_table_owner, p_table_name, 
      p_row_id, get_reason,
      DBMS_TRANSACTION.LOCAL_TRANSACTION_ID)
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
    logger.entering('new_change (VARCHAR2)');
    
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
