CREATE OR REPLACE PACKAGE logger_feedback
IS

  /*
    Provides procedures for logging feedback.
  */

  /*
    Logs some feedback as required by the logger package specification.
  */
  PROCEDURE log (
    p_level IN PLS_INTEGER,
    p_data IN VARCHAR2);

END logger_feedback;
/
