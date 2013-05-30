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

DECLARE
  PROCEDURE fail(
    p_message IN VARCHAR2 := NULL
  )
  IS
  BEGIN
    RAISE_APPLICATION_ERROR(-2000, p_message);
  END;

  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    IF (NOT p_condition OR p_condition IS NULL)
    THEN
      raise_application_error(
        -20000, p_message);
    END IF;
  END;

BEGIN
  messages.check_message_level(messages.message_level_debug);
  messages.check_message_level(messages.message_level_error);
  messages.check_message_level(messages.message_level_fatal);
  messages.check_message_level(messages.message_level_info);
  messages.check_message_level(messages.message_level_warning);

  messages.check_message_level('DEBUG');
  messages.check_message_level('ERROR');
  messages.check_message_level('FATAL');
  messages.check_message_level('INFO');
  messages.check_message_level('WARN');

  BEGIN
    messages.check_message_level(NULL);
    fail;
  EXCEPTION
    WHEN OTHERS
    THEN
      assert(
        INSTR(SQLERRM, 'NULL is not a valid message level') > 0,
        'expected "NULL is not a valid message level". Got ' || sqlerrm);
  END;

  BEGIN
    messages.check_message_level('x');
    fail;
  EXCEPTION
    WHEN OTHERS
    THEN
      assert(
        INSTR(SQLERRM, '"x" is not a valid message level') > 0,
        'expected "NULL is not a valid message level". Got ' || sqlerrm);
  END;

  -- TODO: check data saved in user_message_temp
  messages.add_message(messages.message_level_debug, 'summary', 'detail');
  messages.add_message(messages.message_level_error, 'summary', 'detail');
  messages.add_message(messages.message_level_fatal, 'summary', 'detail');
  messages.add_message(messages.message_level_info, 'summary', 'detail');
  messages.add_message(messages.message_level_warning, 'summary', 'detail');

  BEGIN
    messages.add_message('x', 'summary', 'detail');
    fail;
  EXCEPTION
    WHEN OTHERS
    THEN
      assert(
        INSTR(SQLERRM, '"x" is not a valid message level') > 0,
        'expected "NULL is not a valid message level". Got ' || sqlerrm);
  END;

END;
