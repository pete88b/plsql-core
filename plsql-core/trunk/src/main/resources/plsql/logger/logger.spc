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

CREATE OR REPLACE PACKAGE logger 
IS
  
  /*
    This package provides a specification for logging facilities.
    
    The primary target use of this specification is to identify and resolve 
    run-time problems caused by PL/SQL code.
    
    
    When writing PL/SQL code, developers need to consider two situatons;
    
      Problems occur in the production environment.
        PL/SQL code must log enough information for support staff to be 
        able to identify the problem without re-creating the problem.
        i.e. Fist pass diagnostics.
        
        It is expected that the error procedure will be used to log this 
        information. 
        It is also expected that the info and warn procedures will be 
        used to help first pass diagnostics but data logged at these levels
        is not guaranteed to be saved.
        
      Problems occur in the development environment.
        PL/SQL code must log detailed information about what the code is doing
        so that developers can follow code execution.
        The following gives examples of the kind of information that will be 
        logged for this purpose;
          The start and end of a PL/SQL module,
          The values of actual parameters passed to PL/SQL modules,
          The route taken by code branches (IF / SWITCH / etc) ...
          
        It is expected that the fb, fb1 ... fb5, entering and exiting 
        procedures will be used to log this information.
        
        
    All data logged has an associated log level. The log level determines how 
    the logging call is dispatched.
    
      If the log level is greater than or equal to g_error_level, 
      logger_error.log is called.
      This is true regardless of the feedback level.
      
      Otherwise, if the log level is greater than or equal to the value returned
      by get_feedback_level, logger_feedback.log is called.
      i.e. All feedback could be suppressed by setting the feedback level to 
      6000.
      
      
    The implementations of logger_error and logger_feedback determine how data 
    is logged.
    
    
    Every call to any of the logging procedures (e.g. log, fb ... fb5, error) 
    will cause logger_utils.pre_log_process to be called before the logging 
    call is dispatched.
    
    
    Other modules required by this specification:
      logger_utils.pre_log_process
      logger_error.log(p_level IN PLS_INTEGER, p_data IN VARCHAR2)
      logger_feedback.log(p_level IN PLS_INTEGER, p_data IN VARCHAR2)
    
  */
  
  -- The default feedback level
  g_default_feedback_level CONSTANT PLS_INTEGER := 100;
  
  -- The error level.
  -- Unlike the feedback level, this cannot be changed - anything logged with
  -- a level greater than or equal to this level will be saved as an error
  g_error_level CONSTANT PLS_INTEGER := 6000;
  
  -- Log levels for feedback
  g_log_level_feedback1 CONSTANT PLS_INTEGER := 1;
  g_log_level_feedback2 CONSTANT PLS_INTEGER := 2;
  g_log_level_feedback3 CONSTANT PLS_INTEGER := 3;
  g_log_level_feedback4 CONSTANT PLS_INTEGER := 4;
  g_log_level_feedback5 CONSTANT PLS_INTEGER := 5;
  
  -- Log level for the start of a module
  g_log_level_module_start CONSTANT PLS_INTEGER := 98;
  
  -- Log level for the end of a module
  g_log_level_module_end CONSTANT PLS_INTEGER := 99;
  
  -- Log level for info
  g_log_level_info CONSTANT PLS_INTEGER := 200;
  
  -- Log level for warnings
  g_log_level_warn CONSTANT PLS_INTEGER := 500;
  
  -- Log level for errors
  g_log_level_error CONSTANT PLS_INTEGER := 6000;
  
  
  /*
    Sets the feedback level for this Oracle session.
    
    Feedback messages with a level greater than or equal to this level
    will be passed to logger_feedback.log.
    Feedback messages with a level less than this level will not be saved.
    If p_level is null, the default feedback level will be used.
  */
  PROCEDURE set_feedback_level(
    p_level IN PLS_INTEGER);
  
  
  /*
    Returns the feedback level for this Oracle session.
    This will never be null.
  */
  FUNCTION get_feedback_level
  RETURN PLS_INTEGER;
  
  
  /*
    Logs some data at the specified level.
    
    If p_level is null, the default feedback level will be used.
  */
  PROCEDURE log(
    p_level IN PLS_INTEGER,
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_feedback3.
    
    It is expected that most feedback will be logged via this procedure.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_feedback3.
  */
  PROCEDURE fb(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_feedback1.
    
    It is expected that only the most insignificant feedback is logged via this
    procedure.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_feedback1.
  */
  PROCEDURE fb1(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_feedback2.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_feedback2.
  */
  PROCEDURE fb2(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_feedback3.
    
    This procedure is just here for completeness, 
    use fb to save a little typing.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_feedback3.
  */
  PROCEDURE fb3(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_feedback4.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_feedback4.
  */
  PROCEDURE fb4(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_feedback5.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_feedback5.
  */
  PROCEDURE fb5(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_module_start.
    
    Ideally, every function and procedure will start with a call to this 
    procedure. 
    Pass in the module name.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_module_start.
  */
  PROCEDURE entering(
    p_module_name IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_module_end.
    
    This procedure should be used to record completion of a module. 
    Pass in the module name.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_module_end.
  */
  PROCEDURE exiting(
    p_module_name IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_module_end.
    
    This procedure should be used to record completion of a function and the
    result of the function that is about to be returned. 
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_module_end.
  */
  PROCEDURE exiting(
    p_module_name IN VARCHAR2,
    p_result IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_info.
    
    Use this procedure to save useful information about what your application 
    is doing. 
    It is possible to set the feedback level high enough to suppress info data
    but it is expected that production applications will be running with
    the default feedback level.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_info.
  */
  PROCEDURE info(
    p_data IN VARCHAR2);
    
    
  /*
    Logs some data at log level g_log_level_warn.
    
    Use this procedure to save application warnings. 
    i.e. things that should not occur but cannot be treated as errors.
    It is possible to set the feedback level high enough to suppress warn data
    but it is expected that production applications will be running with
    the default feedback level.
    
    This data will be saved if get_feedback_level returns a value that is
    greater than or equal to g_log_level_warn.
  */
  PROCEDURE warn(
    p_data IN VARCHAR2);
  
  
  /*
    Logs some data at log level g_log_level_error.
    
    Use this procedure to save application errors.
    
    This data will always be saved.
  */
  PROCEDURE error(
    p_data IN VARCHAR2);
  
END logger;
/
