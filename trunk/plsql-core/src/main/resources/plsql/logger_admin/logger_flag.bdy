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
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);
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
      l_message_summary := 'Logger flag ' || l_flag_label || ' not deleted';
      l_message_detail := 'This flag may have been deleted or updated by another session';
    ELSE
      l_message_summary := 'Logger flag ' || l_flag_label || ' deleted';
      -- no point in doing a flag check. removing a flag will not have an effect
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to delete logger flag ' || l_flag_label);

      messages.add_message(
        messages.message_level_error,
        'Failed to delete logger flag ' || l_flag_label,
        SQLERRM);

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

    messages.add_message(
      messages.message_level_info,
      'Logger flag ' || l_flag_label || ' created', NULL);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to create logger flag ' || l_flag_label);

      messages.add_message(
        messages.message_level_error,
        'Failed to create logger flag ' || l_flag_label,
        SQLERRM);

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
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);
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
      l_message_summary := 'Logger flag ' || l_flag_label || ' not updated';
      l_message_detail := 'This flag may have been deleted or updated by another session';
    ELSE
      l_message_summary := 'Logger flag ' || l_flag_label || ' updated';
      -- force a flag check so that this change takes effect now
      logger_utils.check_flags;
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to update logger flag ' || l_flag_label);

      messages.add_message(
        messages.message_level_error,
        'Failed to update logger flag ' || l_flag_label,
        SQLERRM);

    RETURN 'error';

  END upd;

END logger_flag;
/
