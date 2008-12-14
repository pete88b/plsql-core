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

CREATE OR REPLACE PACKAGE messages 
IS
  
  /*
    This package defines a standard interface for sending application messages.

    This package also provides a "default" implementation that sends messages
    to the event mediator. 
    Using this implementation, anyone interested in receiving messages can just 
    register as an observer of the 'message' event.
  */

  /*
    Type used to indicate that a message contains debug information.
  */
  message_level_debug CONSTANT VARCHAR2(5) := 'DEBUG';
  
  /*
    Type used to indicate that a message contains error information.
  */
  message_level_error CONSTANT VARCHAR2(5) := 'ERROR';
  
  /*
    Type used to indicate that a message contains fatal error information.
  */
  message_level_fatal CONSTANT VARCHAR2(5) := 'FATAL';
  
  /*
    Type used to indicate that a message contains some information.
  */
  message_level_info CONSTANT VARCHAR2(4) := 'INFO';
  
  /*
    Type used to indicate that a message contains warning information.
  */
  message_level_warning CONSTANT VARCHAR2(7) := 'WARN';
  
  
  /*
    Sends a "message" event via the event_mediator.
    
    The event name is 'message' and the event will be add_message with 3
    VARCHAR2 arguments. e.g.
      add_message('INFO', 'a summary', 'some detail')
    
    Parameter p_level 
      The level of the message. Use one of the message_level constants.
    Parameter p_summary 
      The message summary.
    Parameter p_detail 
      The message detail.
  */
  PROCEDURE add_message(
    p_level IN VARCHAR2,
    p_summary IN VARCHAR2,
    p_detail IN VARCHAR2
  );
  
  /*
    Raises an exception if the specified level is not one of the levels defined
    by the message_level constants in this package.
  */
  PROCEDURE check_message_level(
    p_level IN VARCHAR2
  );
  
END messages;
/
CREATE OR REPLACE PACKAGE BODY messages 
IS
  
  /*
    Sends a "message" event via the event_mediator.
  */
  PROCEDURE add_message(
    p_level IN VARCHAR2,
    p_summary IN VARCHAR2,
    p_detail IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('add_message');
    
    logger.fb(
      'p_level=' || p_level ||
      ', p_summary=' || p_summary ||
      ', p_detail=' || p_detail);
      
    check_message_level(p_level);
      
    event_mediator.event(
      'message',
      'add_message(''' || p_level || ''', ''' || 
        REPLACE(p_summary, '''', '''''') || ''', ''' || 
        REPLACE(p_detail, '''', '''''') || ''')');
    
  END add_message;
  
  /*
    Check that the specified level is valid, raising an exception if not.
  */
  PROCEDURE check_message_level(
    p_level IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('check_message_level');
    
    IF (p_level IS NULL)
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 'NULL is not a valid message level');
        
    END IF;

    IF (p_level NOT IN (message_level_debug,
                        message_level_error,
                        message_level_fatal,
                        message_level_info,
                        message_level_warning))
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, '"' || p_level || '" is not a valid message level');
        
    END IF;
    
  END check_message_level;
    
END messages;
/
