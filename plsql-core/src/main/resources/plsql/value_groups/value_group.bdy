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

CREATE OR REPLACE PACKAGE BODY value_group
AS
  
  FUNCTION del(
    p_old_description IN VARCHAR2,
    p_old_group_name IN VARCHAR2,
    p_old_values_sql IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);

  BEGIN
    logger.ms('del');
    
    logger.fb('p_old_group_name=' || p_old_group_name);
    
    DELETE FROM value_groups_data
     WHERE group_name = p_old_group_name
       AND (description = p_old_description OR (description IS NULL AND p_old_description IS NULL))
       AND (values_sql = p_old_values_sql OR (values_sql IS NULL AND p_old_values_sql IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      l_message_summary := 'Value group ''' || p_old_group_name || ''' not deleted';
      l_message_detail := 'This Value group may have been deleted or updated by another session';
    ELSE
      l_message_summary := 'Value group ''' || p_old_group_name || ''' deleted';
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN exceptions.integrity_constraint_violated
    THEN
      ROLLBACK;
      
      l_message_summary := 'Value group ''' || p_old_group_name || ''' not deleted';
      l_message_detail := 'All values of a group must be deleted before a group can be deleted';
      
      messages.add_message(
        messages.message_level_warning,
        l_message_summary, l_message_detail);
      
      RETURN 'error';
      
    WHEN OTHERS
    THEN
      logger.error('Failed to delete value_group');

      RAISE;

  END del;

  
  FUNCTION ins(
    p_description IN VARCHAR2,
    p_group_name IN VARCHAR2,
    p_values_sql IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_default_sql value_groups_data.values_sql%TYPE;
    
  BEGIN
    logger.ms('ins');

    logger.fb('p_group_name=' || p_group_name);

    l_default_sql := 
      'SELECT *' || CHR(10) ||
      '  FROM value_group_values_data' || CHR(10) ||
      ' WHERE group_name = ''<group_name>''' || CHR(10) ||
      ' ORDER BY NVL(value, CHR(1))';

    INSERT INTO value_groups_data(
      description, group_name, values_sql
    )
    VALUES (
      p_description, p_group_name, NVL(p_values_sql, l_default_sql)
    );

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      'Value group ''' || p_group_name || ''' created', 
      NULL);

    RETURN NULL;

  EXCEPTION
    WHEN exceptions.cannot_insert_null
    THEN
      ROLLBACK;
      
      messages.add_message(
        messages.message_level_warning,
        'Value group not created', 
        'Name field must not be null');
      
      RETURN 'error';
      
    WHEN DUP_VAL_ON_INDEX
    THEN 
      ROLLBACK;
      
      messages.add_message(
        messages.message_level_warning,
        'Value group ''' || p_group_name || ''' not created', 
        'A Value group with this name already exists');
      
      RETURN 'error';
      
    WHEN OTHERS
    THEN
      logger.error('Failed to insert value_group');
      
      RAISE;
      
  END ins;

  FUNCTION update_details(
    p_group_name IN VARCHAR2,
    p_old_description IN VARCHAR2,
    p_description IN VARCHAR2,
    p_old_values_sql IN VARCHAR2,
    p_values_sql IN VARCHAR2
  )
  RETURN VARCHAR2
  IS
    l_message_summary VARCHAR2(32767);
    l_message_detail VARCHAR2(32767);

  BEGIN
    logger.ms('update_details');

    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_old_description=' || p_old_description ||
      ', p_description=' || p_description ||
      ', ' || CHR(10) || 'p_old_values_sql=' || p_old_values_sql ||
      ', ' || CHR(10) || 'p_values_sql=' || p_values_sql);

    UPDATE value_groups_data
       SET description = p_description,
           values_sql = p_values_sql
     WHERE group_name = p_group_name
       AND (description = p_old_description OR (description IS NULL AND p_old_description IS NULL))
       AND (values_sql = p_old_values_sql OR (values_sql IS NULL AND p_old_values_sql IS NULL));

    IF (SQL%ROWCOUNT = 0)
    THEN
      l_message_summary := 'Value group ''' || p_group_name || ''' not updated';
      l_message_detail := 'This Value group may have been deleted or updated by another session';
    ELSE
      l_message_summary := 'Value group ''' || p_group_name || ''' updated';
    END IF;

    COMMIT;

    messages.add_message(
      messages.message_level_info,
      l_message_summary, l_message_detail);

    RETURN NULL;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to update value group description');
      
      RAISE;
      
  END update_details;

  FUNCTION get_values(
    p_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_sql value_groups_data.values_sql%TYPE;
    l_result SYS_REFCURSOR;

  BEGIN
    logger.ms('get_values');
    
    logger.fb('p_group_name=' || p_group_name);
    
    SELECT TRIM(values_sql)
      INTO l_sql
      FROM value_groups_data
     WHERE group_name = p_group_name;
    
    l_sql := REPLACE(l_sql, '<group_name>', p_group_name);
    
    l_sql := 
      'SELECT ''' || p_group_name || ''' AS group_name, value, label, description, ' ||
      '  DECODE(UPPER(enabled), ''Y'', ''Y'', ''N'') AS enabled, ' ||
      '  group_name AS source_group_name ' || CHR(10) ||
      'FROM (' || l_sql || ')'; 
    
    logger.fb('l_sql=' || l_sql);

    OPEN l_result FOR l_sql;
    
    RETURN l_result;

  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      logger.error('Atempt to get values of non-existent value group ' || p_group_name);
      messages.add_message(
        messages.message_level_warning,
        'Failed to get values for group ' || p_group_name, 'Group does not exist');
      
      RETURN util.dummy_cursor;
      
    WHEN OTHERS
    THEN
      logger.error('Failed to get values. l_sql=' || l_sql);
      messages.add_message(
        messages.message_level_warning,
        'Failed to get values for group ' || p_group_name, NULL);

      RETURN util.dummy_cursor;
      
  END get_values;

END value_group;
/
