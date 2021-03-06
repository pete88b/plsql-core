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

CREATE OR REPLACE PACKAGE types 
IS

  TYPE varchar_table IS TABLE OF VARCHAR2(32767)
  INDEX BY BINARY_INTEGER;
  
  TYPE number_table IS TABLE OF NUMBER
  INDEX BY BINARY_INTEGER;
  
  TYPE integer_table IS TABLE OF INTEGER
  INDEX BY BINARY_INTEGER;

  /*
    Returns a new varchar_table.
    It is expected that the main use of this function is to provide default values for paramters.
  */
  FUNCTION new_varchar_table
  RETURN varchar_table;

  /*
    Returns a new number_table.
    It is expected that the main use of this function is to provide default values for paramters.
  */
  FUNCTION new_number_table
  RETURN number_table;

  /*
    Returns a new integer_table.
    It is expected that the main use of this function is to provide default values for paramters.
  */
  FUNCTION new_integer_table
  RETURN integer_table;
  
END types;
/
