CREATE OR REPLACE PACKAGE logger_stack_utils 
IS
  
  /*
    Provides procedures for the retrieval of call stack information.
    
    The use of this package by non-logger modules is not recommended as
    this package is dedicated to providing functionality to logger modules.
    i.e. The functionality provided by this package may be changed without 
    considering non-logger modules.
    
    For all comments in this package, the term "empty who record" means a who
    record with a level of 0 and null values for owner, name, line and type.
    
    Usage example:
    
      DECLARE
        PROCEDURE a
        IS
          l_who_record logger_stack_utils.who_record_type;
          
        BEGIN
          logger_stack_utils.who_called(logger_stack_utils.g_my_caller, l_who_record);
          -- will return the same as
          logger_stack_utils.who_called_my_caller(l_who_record);
          -- will return the same as
          logger_stack_utils.who_called(6, l_who_record);
          -- show the who record
          DBMS_OUTPUT.PUT_LINE(
            'owner=' || l_who_record.owner ||
            ', name=' || l_who_record.name ||
            ', line=' || l_who_record.line ||
            ', type=' || l_who_record.type ||
            ', level=' || l_who_record.level);
            
        END a;
        
        PROCEDURE b
        IS
        BEGIN
          a;
        END b;
        
      BEGIN
        b; -- this will be the line when we show the who record
        
      END;
      
  */


  -- Constants for the procedure who_called
  g_me CONSTANT POSITIVE := 5;
  g_my_caller CONSTANT POSITIVE := 6;
  g_my_callers_caller CONSTANT POSITIVE := 7;
  g_my_callers_callers_caller CONSTANT POSITIVE := 8;
  
  
  -- Data type to hold call stack info
  TYPE who_record_type IS RECORD(
    owner VARCHAR2(30),
    name VARCHAR2(30),
    line NUMBER,
    type VARCHAR2(200),
    level INTEGER);
  
  
  /*
    Returns details of the caller of this procedure.
    
    This procedure will never return an empty who record.
  */
  PROCEDURE who_am_i(
    p_who_record OUT who_record_type);
  
  
  /*
    Returns details of the caller of the caller of this procedure.
    
    This procedure will return an empty who record if the caller of this 
    procedure has no caller.
  */
  PROCEDURE who_called_me(
    p_who_record OUT who_record_type);
  
  
  /*
    Returns details of the caller of the caller of the caller of this 
    procedure.
    
    This procedure will return an empty who record if the caller of the caller
    of this procedure has no caller.
  */
  PROCEDURE who_called_my_caller(
    p_who_record OUT who_record_type);
  
  
  /*
    Returns details of the caller of the caller of the caller of the
    caller of this procedure.
  */
  PROCEDURE who_called_my_callers_caller(
    p_who_record OUT who_record_type);
  
  
  /*
    Returns details of the specified stack line.
    
    p_stack_line: 
      Must be a potitive integer >= 3 (no upper limit). 
      Values of less than 3 will raise "character to number conversion" errors
      or "numeric or value" errors.
      
      p_stack_line 3 will return the call made by this package,
      p_stack_line 4 will return the same as who_am_i,
      p_stack_line 5 will return the same as who_called_me ...
      
      See also "Constants for the procedure who_called"
    
    This procedure will return an empty who record if the specified stack line
    does not exist. e.g. 
    
    DECLARE
      l_who_record logger_stack_utils.who_record_type;
      
    BEGIN
      -- no-one called me so there are only 4 calls on the stack
      logger_stack_utils.who_called(logger_stack_utils.g_me, l_who_record);
      
      -- l_who_record is empty at this point
      DBMS_OUTPUT.PUT_LINE(
        'owner=' || l_who_record.owner ||
        ', name=' || l_who_record.name ||
        ', line=' || l_who_record.line ||
        ', type=' || l_who_record.type ||
        ', level=' || l_who_record.level);
        
    END;
      
  */
  PROCEDURE who_called(
    p_stack_line IN POSITIVE,
    p_who_record OUT who_record_type);
  
  
END logger_stack_utils;
/
