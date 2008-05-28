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
  */
  PROCEDURE add_message(
    p_level IN VARCHAR2,
    p_summary IN VARCHAR2,
    p_detail IN VARCHAR2
  );
  
  /*
    Calls assert.is_true to check that the specified level is one of the
    message levels defined by this package.
  */
  PROCEDURE check_message_level(
    p_level IN VARCHAR2
  );
  
END messages;
/
CREATE OR REPLACE PACKAGE BODY messages 
IS
  /*
  */
  PROCEDURE assert_is_true(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2  := NULL
  )
  IS
  BEGIN
    IF (p_condition IS NULL OR NOT p_condition)
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, p_message);
        
    END IF;
         
  END assert_is_true;
  
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
  
  PROCEDURE check_message_level(
    p_level IN VARCHAR2
  )
  IS
  BEGIN
    logger.entering('check_message_level');
    
    assert_is_true(
      p_level IN (
        message_level_debug,
        message_level_error,
        message_level_fatal,
        message_level_info,
        message_level_warning),
      '"' || p_level || '" is not a valid message level');
    
  END check_message_level;
    
END messages;
/
