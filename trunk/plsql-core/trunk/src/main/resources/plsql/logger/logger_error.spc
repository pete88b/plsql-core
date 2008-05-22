CREATE OR REPLACE PACKAGE logger_error
IS
  
  /*
    Provides procedures for logging errors.
  */
  
  /*
    Logs an error as required by the logger package specification.
  */
  PROCEDURE log (
    p_level IN PLS_INTEGER,
    p_data IN VARCHAR2);
    
END logger_error;
/
