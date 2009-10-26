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

CREATE OR REPLACE PACKAGE BODY logger_utils
IS

  -- The name of the user who is logging
  g_user VARCHAR2(32767) := USER;
  
  -- The time when flags were last checked by pre_log_process
  g_flags_last_checked DATE;
  
  
  /*
    Set the user of this Oracle session.
    If the specified user is the same as the current user, this is a no-op.
    Otherwise, we need to re-initialize the state of this package for the new user.
  */
  PROCEDURE set_user(
    p_user IN VARCHAR2
  )
  IS
  BEGIN
    -- If the user for this session has changed, set the feedback level to it's
    -- default value. This is important when connections are shared by may users
    IF (NVL(g_user, '~ x ~') != NVL(p_user, '~ x ~'))
    THEN
      -- set the feedback level
      logger.set_feedback_level(logger.g_default_feedback_level);
      
      -- save the user name
      g_user := p_user;
      
      -- re-initialise the flags last checked time
      g_flags_last_checked := NULL;
      
    END IF; -- End of IF (NVL(g_user, '~ x ~') != NVL(p_user, '~ x ~'))
    
    -- Otherwise, do nothing
    
  END set_user;
  
  
  /*
    Return the current user.
  */
  FUNCTION get_user
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN g_user;
  END get_user;
  
  
  /*
    Check the logger_flags table once a minute (at most)
  */
  PROCEDURE pre_log_process
  IS
  BEGIN
    -- check flags if this is the first call for this user or
    -- if the flags have not been checked in the last minute
    IF (g_flags_last_checked IS NULL OR 
        SYSDATE > (g_flags_last_checked + (1/24/60)))
    THEN
      check_flags;
      
      -- save the time we last checked the flags
      g_flags_last_checked := SYSDATE;
    
    END IF; -- End of IF (pre_log_process_call_count > 9)
    
  END pre_log_process;
  
  /*
    Check the logger_flags table.
  */
  PROCEDURE check_flags
  IS
    l_log_level logger_flags.log_level%TYPE;
  
  BEGIN
    -- log_user is the primary key for this table
    SELECT log_level
      INTO l_log_level
      FROM logger_flags
     WHERE log_user = g_user;
         
    -- If we found a row for this user set the feedback level ...
    logger.set_feedback_level(l_log_level);
        
    -- NOTE: Any action taken here should be un-done when set_user is called
        
  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      <<get_logger_flags_for_all_users>>
      BEGIN
        SELECT log_level
          INTO l_log_level
          FROM logger_flags
         WHERE log_user = 'PUBLIC';
             
        -- If we found a row for this user set the feedback level ...
        logger.set_feedback_level(l_log_level);
            
        -- NOTE: Any action taken here should be un-done when set_user is called
            
      EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
          NULL;
              
      END get_logger_flags_for_all_users;
          
  END check_flags;
  
END logger_utils;
/
