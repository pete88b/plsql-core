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

CREATE OR REPLACE PACKAGE BODY logger 
IS
  -- Current level for feedback
  g_feedback_level PLS_INTEGER := g_default_feedback_level;
  
  
  /*
    Sets the current feedback level.
    If p_level is null, the default feedback level will be used.
  */
  PROCEDURE set_feedback_level(
    p_level IN PLS_INTEGER)
  IS
  BEGIN
    g_feedback_level := NVL(p_level, g_default_feedback_level);
    
  END set_feedback_level;
  
  
  /*
    Returns the current feedback level. This should never be null. 
    Make sure set_feedback_level does not allow this to be null.
  */
  FUNCTION get_feedback_level
  RETURN PLS_INTEGER
  IS
  BEGIN
    RETURN g_feedback_level;
    
  END get_feedback_level;
  
  
  /*
    Dispatches logging messages to the logger_error or logger_feedback 
    packages as appropriate.
    For feedback messages with a level below the current feedback level
    for this session, this is a no-op.
    The purpose of this procedure (rather than putting this code in log) 
    is to keep the call stack depth consistent for logger_error.log and
    logger_feedback.log.
    If p_level is null, the default feedback level will be used.
  */
  PROCEDURE log_internal(
    p_level IN PLS_INTEGER,
    p_data IN VARCHAR2)
  IS
  BEGIN
    -- Run the pre-log process
    logger_utils.pre_log_process;
    
    -- Logged data is 'consumed' by one of the following logger_???.log procedures.
    -- i.e. If the data is logged as an error it will not be logged as feedback.
    
    -- If we're logging an error, delegate to logger_error.log
    IF (p_level >= g_error_level)
    THEN
      logger_error.log(p_level, p_data);
    
    -- Otherwise, we're logging some feedback. If g_feedback_level has been set
    -- to a value that is lower than p_level, delegate to logger_feedback.log
    ELSIF (NVL(p_level, g_default_feedback_level) >= g_feedback_level)
    THEN
      logger_feedback.log(p_level, p_data);
      
    END IF; -- End of IF (p_level >= ...
    
  END log_internal;
  
  
  /*
    Make log_internal call, passing specified values.
  */
  PROCEDURE log(
    p_level IN PLS_INTEGER,
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(p_level, p_data);
      
  END log;
  
  /*
    Make log_internal call, passing fb 3 level and specified p_data value.
  */  
  PROCEDURE fb(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_feedback3, p_data);
      
  END fb;
  
  /*
    Make log_internal call, passing fb 1 level and specified p_data value.
  */  
  PROCEDURE fb1(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_feedback1, p_data);
      
  END fb1;
    
    
  /*
    Make log_internal call, passing fb 2 level and specified p_data value.
  */  
  PROCEDURE fb2(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_feedback2, p_data);
      
  END fb2;
  
  
  /*
    Make log_internal call, passing fb 3 level and specified p_data value.
  */  
  PROCEDURE fb3(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_feedback3, p_data);
      
  END fb3;
  
  
  /*
    Make log_internal call, passing fb 4 level and specified p_data value.
  */  
  PROCEDURE fb4(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_feedback4, p_data);
      
  END fb4;
  
  
  /*
    Make log_internal call, passing fb 5 level and specified p_data value.
  */  
  PROCEDURE fb5(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_feedback5, p_data);
      
  END fb5;
  
  
  /*
    Make log_internal call, passing module start level and specified 
    p_module_name value.
  */  
  PROCEDURE entering(
    p_module_name IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_module_start, p_module_name);
      
  END entering;
  
  
  /*
    Make log_internal call, passing module end level and specified 
    p_module_name value.
  */
  PROCEDURE exiting(
    p_module_name IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_module_end, p_module_name);
      
  END exiting;
  
  /*
    Make log_internal call, passing module end level and log data made up of
    the specified module name and result.
  */
  PROCEDURE exiting(
    p_module_name IN VARCHAR2,
    p_result IN VARCHAR2)
  IS
  BEGIN
    log_internal(
      g_log_level_module_end, 
      p_module_name || ' RETURN=' || p_result);
      
  END exiting;
  
  
  /*
    Make log_internal call, passing info level and specified p_data value.
  */
  PROCEDURE info(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_info, p_data);
      
  END info;
  
  
  /*
    Make log_internal call, passing warn level and specified p_data value.
  */
  PROCEDURE warn(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_warn, p_data);
      
  END warn;
  
  
  /*
    Make log_internal call, passing error level and specified p_data value.
  */
  PROCEDURE error(
    p_data IN VARCHAR2)
  IS
  BEGIN
    log_internal(g_log_level_error, p_data);
      
  END error;
  
  
END logger;
/
