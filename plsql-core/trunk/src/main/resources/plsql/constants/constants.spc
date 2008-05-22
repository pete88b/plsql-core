CREATE OR REPLACE PACKAGE constants
IS

  /*
    Defines constants that can be used by any PL/SQL code.
  */

  yes CONSTANT VARCHAR2(1) := 'Y';
  no CONSTANT VARCHAR2(1) := 'N';
  invalid CONSTANT VARCHAR2(1) := 'I';
  unknown CONSTANT VARCHAR2(1) := '?';
  
  true_value CONSTANT VARCHAR2(1) := 'Y';
  false_value CONSTANT VARCHAR2(1) := 'N';
  
END constants;
/
