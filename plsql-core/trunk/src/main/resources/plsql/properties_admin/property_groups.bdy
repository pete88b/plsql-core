CREATE OR REPLACE PACKAGE BODY property_groups 
IS

  FUNCTION get_property_groups(
    p_group_name IN VARCHAR2,
    p_single_value_per_key IN VARCHAR2,
    p_locked IN VARCHAR2,
    p_group_description IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS 
    l_result SYS_REFCURSOR;
    
  BEGIN
    logger.entering('get_property_groups');
    
    logger.fb(
      'p_group_name=' || p_group_name ||
      ', p_single_value_per_key=' || p_single_value_per_key ||
      ', p_locked=' || p_locked ||
      ', p_group_description=' || p_group_description);
    
    OPEN l_result FOR
    SELECT ROWIDTOCHAR(ROWID) AS row_id, 
           property_groups_data.*
      FROM property_groups_data
     WHERE (UPPER(group_name) LIKE '%' || UPPER(p_group_name) || '%' OR
           (group_name IS NULL AND p_group_name IS NULL)) AND
           (UPPER(single_value_per_key) LIKE '%' || UPPER(p_single_value_per_key) || '%' OR
           (single_value_per_key IS NULL AND p_single_value_per_key IS NULL)) AND
           (UPPER(locked) LIKE '%' || UPPER(p_locked) || '%' OR
           (locked IS NULL AND p_locked IS NULL)) AND
           (UPPER(group_description) LIKE '%' || UPPER(p_group_description) || '%' OR
           (group_description IS NULL AND p_group_description IS NULL))
     ORDER BY group_name;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error(
        'Failed to get property groups. p_group_name=' || p_group_name ||
        ', p_single_value_per_key=' || p_single_value_per_key ||
        ', p_locked=' || p_locked ||
        ', p_group_description=' || p_group_description);
      RAISE;
    
  END get_property_groups;
  
END property_groups;
/
