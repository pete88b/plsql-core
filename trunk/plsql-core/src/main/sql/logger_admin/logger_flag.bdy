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

CREATE OR REPLACE PACKAGE BODY logger_flag
AS
  FUNCTION get_flag_label(
    p_log_level IN INTEGER,
    p_log_user IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '"' || p_log_user || '"';
    
  END get_flag_label;
  
  FUNCTION del(
    p_row_id IN VARCHAR2,
    p_old_log_level IN INTEGER,
    p_old_log_user IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_flag_label VARCHAR2(32767) := get_flag_label(p_old_log_level, p_old_log_user);
    
  BEGIN
    logger.entering('del');

    DELETE FROM logger_flags
     WHERE rowid = p_row_id
       AND (log_level = p_old_log_level OR
           (log_level IS NULL AND p_old_log_level IS NULL))
       AND (log_user = p_old_log_user OR
           (log_user IS NULL AND p_old_log_user IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      user_messages.add_info_message(
        'Logger flag {1} not deleted. It may have been deleted or updated by another session',
        user_messages.add_argument(1, l_flag_label));

    ELSE
      user_messages.add_info_message(
        'Logger flag {1} deleted',
        user_messages.add_argument(1, l_flag_label));
      -- no point in doing a flag check. removing a flag will not have an effect

    END IF;

    COMMIT;

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to delete logger flag ' || l_flag_label);
      
      user_messages.add_error_message(
        'Failed to delete logger flag {1}. {2}',
        user_messages.add_argument(1, l_flag_label,
        user_messages.add_argument(2, SQLERRM)));

    RETURN 'error';

  END del;

  FUNCTION ins(
    p_row_id OUT VARCHAR2,
    p_log_level IN INTEGER,
    p_log_user IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_flag_label VARCHAR2(32767) := get_flag_label(p_log_level, p_log_user);
    
  BEGIN
    logger.entering('ins');

    INSERT INTO logger_flags(
      log_level,
      log_user
    )
    VALUES (
      p_log_level,
      p_log_user
    )
    RETURNING ROWID INTO p_row_id;

    COMMIT;

    -- force a flag check so that this change takes effect now
    logger_utils.check_flags;

    user_messages.add_info_message(
        'Logger flag {1} created',
        user_messages.add_argument(1, l_flag_label));

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to create logger flag ' || l_flag_label);

      user_messages.add_error_message(
        'Failed to create logger flag {1}. {2}',
        user_messages.add_argument(1, l_flag_label,
        user_messages.add_argument(2, SQLERRM)));

    RETURN 'error';

  END ins;

  FUNCTION upd(
    p_row_id IN VARCHAR2,
    p_old_log_level IN INTEGER,
    p_log_level IN INTEGER,
    p_old_log_user IN VARCHAR2,
    p_log_user IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_flag_label VARCHAR2(32767) := get_flag_label(p_old_log_level, p_old_log_user);

  BEGIN
    logger.entering('upd');

    UPDATE logger_flags
       SET log_level = p_log_level,
           log_user = p_log_user
     WHERE rowid = p_row_id
       AND ((log_level = p_old_log_level) OR
           (log_level IS NULL AND p_old_log_level IS NULL))
       AND ((log_user = p_old_log_user) OR
           (log_user IS NULL AND p_old_log_user IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      user_messages.add_info_message(
        'Logger flag {1} not updated. It may have been deleted or updated by another session',
        user_messages.add_argument(1, l_flag_label));

    ELSE
      user_messages.add_info_message(
        'Logger flag {1} not updated',
        user_messages.add_argument(1, l_flag_label));
      -- force a flag check so that this change takes effect now
      logger_utils.check_flags;
    END IF;

    COMMIT;

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to update logger flag ' || l_flag_label);

      user_messages.add_error_message(
        'Failed to update logger flag {1}. {2}',
        user_messages.add_argument(1, l_flag_label,
        user_messages.add_argument(2, SQLERRM)));

    RETURN 'error';

  END upd;

END logger_flag;
/
