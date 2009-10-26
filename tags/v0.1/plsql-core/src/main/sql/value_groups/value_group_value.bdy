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

CREATE OR REPLACE PACKAGE BODY value_group_value
AS
  
  FUNCTION del(
    p_old_group_name IN VARCHAR2,
    p_old_value IN VARCHAR2,
    p_old_label IN VARCHAR2,
    p_old_description IN VARCHAR2,
    p_old_enabled IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);

  BEGIN
    logger.ms('del');
    
    DELETE FROM value_group_values_data
    WHERE  group_name = p_old_group_name
    AND    value = p_old_value
    AND    (label = p_old_label OR (label IS NULL AND p_old_label IS NULL))
    AND    (description = p_old_description OR (description IS NULL AND p_old_description IS NULL))
    AND    (enabled = p_old_enabled OR (enabled IS NULL AND p_old_enabled IS NULL));
    
    IF (SQL%ROWCOUNT = 0)
    THEN
      l_message_summary := 'Value ''' || p_old_value || ''' not deleted for group ''' || p_old_group_name || '''';
      l_message_detail := 'This value may not exist for this group or it may have been deleted or updated by another session';
    ELSE
      l_message_summary := 'Value ''' || p_old_value || ''' deleted for group ''' || p_old_group_name || '''';
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to delete value_group_value');

      RAISE;

  END del;

  
  FUNCTION ins(
    p_group_name IN VARCHAR2,
    p_value IN VARCHAR2,
    p_label IN VARCHAR2,
    p_description IN VARCHAR2,
    p_enabled IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
  BEGIN
    logger.ms('ins');

    INSERT INTO value_group_values_data(
      group_name, value, label, description, enabled
    )
    VALUES (
      p_group_name, p_value, p_label, p_description, p_enabled
    );

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      'Value ''' || p_value || ''' created for group ''' || p_group_name || '''', 
      NULL);

    RETURN NULL;

  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
    THEN
      ROLLBACK;
      
      messages.add_message(
        messages.message_level_warning,
        'Value ''' || p_value || ''' not created for group ''' || p_group_name || '''', 
        'This value already exists for this group');
      
      RETURN 'error';
      
    WHEN OTHERS
    THEN
      logger.error('Failed to insert value_group_value');
      
      RAISE;
      
  END ins;

  FUNCTION upd(
    p_old_group_name IN VARCHAR2,
    p_old_value IN VARCHAR2,
    p_old_label IN VARCHAR2,
    p_label IN VARCHAR2,
    p_old_description IN VARCHAR2,
    p_description IN VARCHAR2,
    p_old_enabled IN VARCHAR2,
    p_enabled IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);

  BEGIN
    logger.ms('upd');

    UPDATE value_group_values_data
    SET    label = p_label,
           description = p_description,
           enabled = p_enabled
    WHERE  group_name = p_old_group_name
    AND    (value = p_old_value OR (value IS NULL AND p_old_value IS NULL))
    AND    (label = p_old_label OR (label IS NULL AND p_old_label IS NULL))
    AND    (description = p_old_description OR (description IS NULL AND p_old_description IS NULL))
    AND    (enabled = p_old_enabled OR (enabled IS NULL AND p_old_enabled IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      l_message_summary := 'Value ''' || p_old_value || ''' not updated for group ''' || p_old_group_name || '''';
      l_message_detail := 'This value may not exist for this group or it may have been deleted or updated by another session';
    ELSE
      l_message_summary := 'Value ''' || p_old_value || ''' updated for group ''' || p_old_group_name || '''';
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to update value_group_value');
      
      RAISE;
      
  END upd;

END value_group_value;
/
