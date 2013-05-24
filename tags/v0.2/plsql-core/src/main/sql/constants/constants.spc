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
