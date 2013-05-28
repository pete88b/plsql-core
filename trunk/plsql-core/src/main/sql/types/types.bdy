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

CREATE OR REPLACE PACKAGE BODY types 
IS

  /*
    Returns a new varchar_table.
  */
  FUNCTION new_varchar_table
  RETURN varchar_table
  IS
    l_result varchar_table;

  BEGIN
    RETURN l_result;

  END;

  /*
    Returns a new number_table.
  */
  FUNCTION new_number_table
  RETURN number_table
  IS
    l_result number_table;

  BEGIN
    RETURN l_result;

  END;

  /*
    Returns a new integer_table.
  */
  FUNCTION new_integer_table
  RETURN integer_table
  IS
    l_result integer_table;

  BEGIN
    RETURN l_result;

  END;
  
END types;
/
