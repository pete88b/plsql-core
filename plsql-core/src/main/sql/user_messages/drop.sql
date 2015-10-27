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

/*
  Drop script for messages.
*/

PROMPT ___ Start of messages drop.sql ___

DECLARE
  PROCEDURE p(
    p_data IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(p_data);

  END p;

  PROCEDURE drop_object(
    p_type_and_name IN VARCHAR2
  )
  IS
  BEGIN
    p('Dropping ' || p_type_and_name);
    EXECUTE IMMEDIATE 'DROP ' || p_type_and_name;
    p(p_type_and_name || ' dropped');
    p('-');

  EXCEPTION
    WHEN OTHERS
    THEN
      p(p_type_and_name || ' not found');
      p('-');

  END drop_object;

BEGIN
  drop_object('PACKAGE user_messages');
  drop_object('TABLE user_message_temp');
  drop_object('SEQUENCE user_message_id');
  
END;
/

PROMPT ___ End of messages drop.sql ___