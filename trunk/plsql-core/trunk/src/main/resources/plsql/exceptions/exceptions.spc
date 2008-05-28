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
  
  application_problem_code CONSTANT INTEGER := -20000;
  
  application_problem EXCEPTION;
  PRAGMA EXCEPTION_INIT(application_problem, -20000);
  
  application_error_code CONSTANT INTEGER := -20999;
  
  application_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(application_error, -20999);
  
  check_constraint_violated EXCEPTION;
  PRAGMA EXCEPTION_INIT(check_constraint_violated, -02290);
  
  integrity_constraint_violated EXCEPTION;
  PRAGMA EXCEPTION_INIT(integrity_constraint_violated, -02292);
  
  cannot_insert_null EXCEPTION;
  PRAGMA EXCEPTION_INIT(cannot_insert_null, -01400);
  
  name_already_used EXCEPTION;
  PRAGMA EXCEPTION_INIT(name_already_used, -00955);
  
  table_or_view_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(table_or_view_not_found, -00942);
  
  sequence_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(sequence_not_found, -02289);
  
  object_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(object_not_found, -04043);
  
  trigger_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(trigger_not_found, -04080);

  success_with_compilation_err EXCEPTION;
  PRAGMA EXCEPTION_INIT(success_with_compilation_err, -24344);
  
END EXCEPTIONS;
/
