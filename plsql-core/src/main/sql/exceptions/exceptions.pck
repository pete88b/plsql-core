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

CREATE OR REPLACE PACKAGE exceptions 
IS
  
  /*
    Defines exceptions to help when catching exceptions and provides 
    procedures to help when raising exceptions.
  */

  /*
    Use this to catch the exception thrown by Oracle
    when a check constraint has been violated.
  */
  check_constraint_violated EXCEPTION;
  PRAGMA EXCEPTION_INIT(check_constraint_violated, -02290);
  
  /*
    Use this to catch the exception thrown by Oracle when an integrity 
    constraint has been violated due to a missing parent key.
  */
  parent_key_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(parent_key_not_found, -02291);
  
  /*
    Use this to catch the exception thrown by Oracle when an integrity 
    constraint has been violated as child records have been found.
  */
  child_record_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(child_record_found, -02292);
  
  /*
    Use this to catch the exception thrown by Oracle
    when you try to insert null into a column that does not
    allow null values.
  */
  cannot_insert_null EXCEPTION;
  PRAGMA EXCEPTION_INIT(cannot_insert_null, -01400);
  
  /*
    Use this to catch the exception thrown by Oracle
    when you try to use a name that is already in use.
  */
  name_already_used EXCEPTION;
  PRAGMA EXCEPTION_INIT(name_already_used, -00955);
  
  /*
    Use this to catch the exception thrown by Oracle
    when you try to use a table or view that does not exist.
  */
  table_or_view_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(table_or_view_not_found, -00942);
  
  /*
    Use this to catch the exception thrown by Oracle
    when you try to use a sequence that does not exist.
  */
  sequence_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(sequence_not_found, -02289);
  
  /*
    Use this to catch the exception thrown by Oracle
    when try to use an object that does not exist.
  */
  object_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(object_not_found, -04043);
  
  /*
    Use this to catch the exception thrown by Oracle
    when try to use a trigger that does not exist.
  */
  trigger_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(trigger_not_found, -04080);

  /*
    Use this to catch the exception thrown by Oracle
    when an object compiles but has compilation errors.
  */
  success_with_compilation_err EXCEPTION;
  PRAGMA EXCEPTION_INIT(success_with_compilation_err, -24344);


  /*
    The error code to use to indicate a problem with the application.
  */
  application_problem_code CONSTANT INTEGER := -20000;
  
  /*
    The exception to use to indicate a problem with the application.
  */
  application_problem EXCEPTION;
  PRAGMA EXCEPTION_INIT(application_problem, -20000);
  
  /*
    Raises an exception with the specified message with an error
    code of application_problem_code.
    
    Details of the exception to be thrown are logged at INFO level.
    
    If p_rollback is true, this procedure issues a ROLLBACK before
    doing anything else.
  */
  PROCEDURE throw_problem(
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE);
  
  
  /*
    The error code to use to indicate an error in the application.
  */
  application_error_code CONSTANT INTEGER := -20999;

  /*
    The exception to use to indicate an error in the application.
  */
  application_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(application_error, -20999);
  
  /*
    Raises an exception with the specified message with an error
    code of application_error_code.
    
    Details of the exception to be thrown are logged at INFO level.
    
    If p_rollback is true, this procedure issues a ROLLBACK before
    doing anything else.
  */
  PROCEDURE throw_error(
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE);
  
  
  /*
    The error code to use to indicate a NULL value was found where
    a NULL value is not allowed.
  */
  cannot_be_null_code CONSTANT INTEGER := -20001;
  
  /*
    The exception to use to indicate a NULL value was found where
    a NULL value is not allowed.
  */
  cannot_be_null EXCEPTION;
  PRAGMA EXCEPTION_INIT(cannot_be_null, -20001);
  
  /*
    Raises an exception with an error code of cannot_be_null_code 
    if the specified value is NULL.

    Details of the exception to be thrown are logged at INFO level.
    
    If p_rollback is true, this procedure issues a ROLLBACK before
    doing anything else.
    
    Parameters:
      p_value
        The value to test for NULL.
        
      p_name
        The name of the value being tested. 
        It is expected that this will be a parameter name.
        
      p_rollback
        Pass TRUE to ROLLBACK the current transaction.
  */
  PROCEDURE throw_if_null(
    p_value IN VARCHAR2,
    p_name IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE);
  
  
  /*
    The error code to use to indicate an expected condition was not TRUE.
  */
  condition_not_true_code CONSTANT INTEGER := -20002;
  
  /*
    The exception to use to indicate an expected condition was not TRUE.
  */
  condition_not_true EXCEPTION;
  PRAGMA EXCEPTION_INIT(condition_not_true, -20002);
  
  /*
    Raises an exception with an error code of condition_not_true_code 
    if the specified condition is not TRUE.

    Details of the exception to be thrown are logged at INFO level.
    
    If p_rollback is true, this procedure issues a ROLLBACK before
    doing anything else.
    
    Parameters:
      p_condition
        The condition to test.
        If this is FALSE or NULL, an exception will be raised.
        
      p_message
        The error message to use.
        
      p_rollback
        Pass TRUE to ROLLBACK the current transaction.
  */
  PROCEDURE throw_if_not_true(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE);
  
  
  /*
    Raises an exception with the specified error code and message.
    If possible, use one of the more specific throw procedures.
    
    Details of the exception to be thrown are logged at INFO level.
    
    If p_rollback is true, this procedure issues a ROLLBACK before
    doing anything else.
    
    Parameters:
      p_code
        The error code to use.
        
      p_message
        The error message to use.
        
      p_rollback
        Pass TRUE to ROLLBACK the current transaction.
  */
  PROCEDURE throw(
    p_code IN INTEGER,
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE);
  
END exceptions;
/
CREATE OR REPLACE PACKAGE BODY exceptions 
IS

  /*
    Used by all the public throw procedures.
    
    This procedure will:
      ROLLBACK if p_rollback is true.
      
      log details of the exception to be thrown.
      
      raise an exception with the specified code and message.
    
    
    This procedure uses the logger_stack_utils package.
    While this is not recommended, as there is a risk that logger_stack_utils
    will be changed, the benefits of knowing who called the public procedure 
    that led to this call make it a risk worth taking.
  */
  PROCEDURE private_throw(
    p_code IN INTEGER,
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE
  )
  IS
    -- holds details of the caller of the public procedure of this package
    l_who_record logger_stack_utils.who_record_type;
    -- holds the text that we will log before raising the exception
    l_info VARCHAR2(32767);
    
  BEGIN
    -- rollback only if required
    IF (p_rollback)
    THEN
      ROLLBACK;
      
    END IF;
    
    -- find out who called the public procedure of this package 
    -- i.e. who called throw_problem, throw_error, ...
    logger_stack_utils.who_called_my_caller(l_who_record);
    
    IF (l_who_record.owner IS NULL)
    THEN
      -- if the owner is null, the caller was an anonymous block
      l_info := l_who_record.type;
      
    ELSE
      -- otherwise, we can say which object called the public procedure
      l_info := l_who_record.owner || '.' || l_who_record.name;
      
    END IF;
    
    -- we will always know the line that called the public procedure so we can 
    -- add the line number and details of the exception that will be thrown
    l_info := l_info ||
      ' (' || l_who_record.line || ') Raising ' || p_code || ': ' || p_message;
      
    -- if SQLCODE is 0, this procedure was not called from an exception section
    -- if SQLCODE is not 0, SQLERRM tells us what error was trapped in the
    -- exception section from which this procedure was called
    IF (SQLCODE != 0)
    THEN
      l_info := l_info || '. Cause: ' || SQLERRM;
        
    END IF;
    
    -- log the info we've built up
    logger.info(l_info);
    
    -- raise the exception
    RAISE_APPLICATION_ERROR(p_code, p_message);
    
  END private_throw;
  
  
  /*
    Raises an exception with the specified message with an error
    code of application_problem_code.
  */
  PROCEDURE throw_problem(
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE
  )
  IS
  BEGIN
    private_throw(application_problem_code, p_message, p_rollback);
    
  END throw_problem;
  
  
  /*
    Raises an exception with the specified message with an error
    code of application_error_code.
  */
  PROCEDURE throw_error(
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE
  )
  IS
  BEGIN
    private_throw(application_error_code, p_message, p_rollback);
    
  END throw_error;
  
  
  /*
    Raises an exception with an error code of cannot_be_null_code 
    if the specified value is NULL.
  */
  PROCEDURE throw_if_null(
    p_value IN VARCHAR2,
    p_name IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE
  )
  IS
  BEGIN
    IF (p_value IS NULL)
    THEN
      private_throw(
        cannot_be_null_code, 
        p_name || ' cannot be null', 
        p_rollback);
      
    END IF;
    
  END throw_if_null;
  
  
  /*
    Raises an exception with an error code of condition_not_true_code 
    if the specified condition is not TRUE.
  */
  PROCEDURE throw_if_not_true(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE
  )
  IS
  BEGIN
    IF (NOT p_condition OR p_condition IS NULL)
    THEN
      private_throw(condition_not_true_code, p_message, p_rollback);
      
    END IF;
    
  END throw_if_not_true;
  
  
  /*
    Raises an exception with the specified error code and message.
  */
  PROCEDURE throw(
    p_code IN INTEGER,
    p_message IN VARCHAR2,
    p_rollback IN BOOLEAN := TRUE
  )
  IS
  BEGIN
    private_throw(p_code, p_message, p_rollback);
    
  END throw;
  
END exceptions;
/
