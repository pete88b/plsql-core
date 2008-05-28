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

CREATE OR REPLACE PACKAGE event_mediator 
IS
  /*
    This package enables PL/SQL code to publish and receive events
    in a loosley coupled manner.
    
    
    To receive notification of an event, register as an observer. e.g.
    
      BEGIN
        event_mediator.add_observer('task_complete', 'task_monitor');
      END;
      
      This would register the PL/SQL package task_monitor as an observer
      of the task_complete event.
    
    
    To notify observers of an event (i.e. publish an event), call event. e.g.
    
      PROCEDURE complete_admin_task(
        p_task_id IN INTEGER)
      
        ... code to complete the task ...
        
        event_mediator.event(
          'task_complete', 
          'task_complete(''admin'', ' || p_task_id || ')');
        
      END;
    
      PROCEDURE complete_other_task(
        p_task_id IN INTEGER)
      
        ... code to complete the task ...
        
        event_mediator.event(
          'task_complete', 
          'task_complete(''other'', ' || p_task_id || ')');
        
      END;
    
      Calling the complete_admin_task procedure (above) with a p_task_id of 2, 
      would cause event_mediator to call task_complete('admin', 2) on all 
      registered observers. 
      With task_monitor registered as an observer of the task_complete event, 
      this would mean executing BEGIN task_monitor.task_complete('admin', 2); END;.
      With no observers registered (as observers of the task_complete event)
      this would mean doing nothing.
      
    
    To remove an obsever, call one of the remove_observer procedures. e.g.
    
      BEGIN
        event_mediator.remove_observer('task_complete', 'task_monitor');
      END;
      
      This will remove task_monitor as an observer of the task_complete
      event.
    
    
    Notes:
      Event names and observer names are converted to lower case for both
      storage and comparison.
      
      Observers must have publicly declared procedures that match the 
      signature of the event being published.
    
      Any number of observers can be registered to receive an event.
      
      Any piece of PL/SQL code can publish an event.
      
      Any number of events can be published under the same event name.
  */
  
  
  /*
    Raised to indicate an event has no observers when at least one observer 
    is expected.
    
    See event.
  */
  e_no_observers EXCEPTION;
  
  
  /*
    Registers an observer of an event.
    
    Parameter p_event_name
      The name of the event.

    Parameter p_observer
      The name of the observer. 
      A PL/SQL package name which may be fully qualified.
      
    Exception
      Unique constraint if the specified observer has already been registered.
      
    Commits: No
  */
  PROCEDURE add_observer(
    p_event_name IN VARCHAR2,
    p_observer IN VARCHAR2
  );
    
    
  /*
    Removes an observer of an event.
    
    If an observer of p_event_name with name p_observer is registered, 
    it will be removed. Otherwise this procedure does nothing.
    
    Commits: No
  */
  PROCEDURE remove_observer(
    p_event_name IN VARCHAR2,
    p_observer IN VARCHAR2
  );
  
  
  /*
    Removes an observer.
    
    If an observer with name p_observer is registered, the registration as
    an observer of any/all events will be removed. 
    Otherwise this procedure does nothing.
    
    Commits: No
  */
  PROCEDURE remove_observer(
    p_observer IN VARCHAR2
  );
    
    
  /*
    Removes all observers.
    
    If an observers have been registered, the registration of all observers
    of any/all events will be removed. 
    Otherwise this procedure does nothing.
    
    Commits: No
  */
  PROCEDURE remove_observers;
  
  
  /*
    Notifies all registered observers of the specified event. The order in
    which observers are notified is not defined.
    
    Parameter p_event_name
      The name of the event.
      
    Parameter p_event
      The event as a PL/SQL procedure call (with arguments).
      Note: p_event does not need to end with a semi-colon.
      
    Parameter p_fail_on_error
      If false, failure to notify an observer will be logged but no exception
      will be raised.
      If true, failure to notify an observer will cause an exception to be
      raised. The exception will be raised as soon as a notification fails,
      so some observers may not receive notification.
      
    Parameter p_fail_if_no_observers
      If true and no observers have registered for the specified event,
      e_no_observers will be raised. Otherwise, e_no_observers will not be raised.
      
    Commits: Depends on action taken by the observers.
  */
  PROCEDURE event(
    p_event_name IN VARCHAR2,
    p_event IN VARCHAR2,
    p_fail_on_error IN BOOLEAN := TRUE,
    p_fail_if_no_observers IN BOOLEAN := FALSE
  );
  
  
END event_mediator;
/
CREATE OR REPLACE PACKAGE BODY event_mediator 
IS

  /*
    Returns a text representation of a BOOLEAN.
      TRUE -> 'TRUE'
      FALSE -> 'FALSE'
      NULL -> 'NULL'
  */
  FUNCTION to_char(
    b IN BOOLEAN
  )
  RETURN VARCHAR2
  IS
  BEGIN
    IF (b)
    THEN
      RETURN 'TRUE';
      
    ELSIF (NOT b)
    THEN
      RETURN 'FALSE';
      
    ELSE
      RETURN 'NULL';
      
    END IF;
    
  END to_char;
  
  
  /*
  */
  PROCEDURE add_observer(
    p_event_name IN VARCHAR2,
    p_observer IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('add_observer');
    
    INSERT INTO event_mediator_data(
      event_name, observer)
    VALUES(
      LOWER(p_event_name), LOWER(p_observer));
      
    COMMIT;
    
  END add_observer;
  
  
  /*
  */ 
  PROCEDURE remove_observer(
    p_event_name IN VARCHAR2,
    p_observer IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('remove_observer 1');
    
    logger.fb(
      'p_event_name=' || p_event_name ||
      ', p_observer=' || p_observer);
    
    DELETE FROM event_mediator_data
    WHERE  event_name = LOWER(p_event_name)
    AND    observer = LOWER(p_observer);
      
    logger.fb(SQL%ROWCOUNT || ' rows deleted');
      
    COMMIT;
    
  END remove_observer;
  
  
  /*
  */
  PROCEDURE remove_observer(
    p_observer IN VARCHAR2
  )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('remove_observer 2');
    
    logger.fb(
      'p_observer=' || p_observer);
    
    DELETE FROM event_mediator_data
    WHERE  observer = LOWER(p_observer);
      
    logger.fb(SQL%ROWCOUNT || ' rows deleted');
      
    COMMIT;
    
  END remove_observer;
  
  
  /*
  */
  PROCEDURE remove_observers
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    
  BEGIN
    logger.entering('remove_observers');
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE event_mediator_data';
      
    logger.fb('event_mediator_data truncated');
      
  END remove_observers;
  
  
  /*
  */
  PROCEDURE event(
    p_event_name IN VARCHAR2,
    p_event IN VARCHAR2,
    p_fail_on_error IN BOOLEAN := TRUE,
    p_fail_if_no_observers IN BOOLEAN := FALSE
  )
  IS
    l_event VARCHAR2(32767);
    l_no_observers BOOLEAN := TRUE;
    l_call VARCHAR2(32767);
    
  BEGIN
    logger.entering('event');
    
    logger.fb(
      'p_event_name=' || p_event_name ||
      ', p_event=' || p_event ||
      ', p_fail_on_error=' || to_char(p_fail_on_error) ||
      ', p_fail_if_no_observers=' || to_char(p_fail_if_no_observers));
    
    -- remove leading and trailing blank spaces from the event
    l_event := TRIM(p_event);
    
    logger.fb('after trim. l_event=' || l_event);
    
    -- if event ends with a semi-colon, remove it
    IF (SUBSTR(l_event, -1, 1) = ';')
    THEN
      l_event := SUBSTR(l_event, 1, LENGTH(l_event) - 1);
      logger.fb('after removing ";". l_event=' || l_event);
      
    END IF;
    
    FOR i IN (SELECT *
              FROM   event_mediator_data
              WHERE  event_name = LOWER(p_event_name))
    LOOP
      l_no_observers := FALSE;
      
      l_call := i.observer || '.' || l_event;
      
      <<try_call>>
      BEGIN
        logger.fb('executing ' || l_call);
        EXECUTE IMMEDIATE 'BEGIN ' || l_call || '; END;';
        
      EXCEPTION
        WHEN OTHERS
        THEN
          -- Any failure to execute an event on an observer should be logged
          logger.error('failed to execute ' || l_call);
          
          IF (p_fail_on_error)
          THEN
            logger.fb('re-raising exception');
            RAISE;
            
          END IF;
        
      END try_call;
      
    END LOOP;
    
    IF (p_fail_if_no_observers AND l_no_observers)
    THEN
      RAISE e_no_observers;
      
    END IF;
    
  END event;
  
  
END event_mediator;
/
