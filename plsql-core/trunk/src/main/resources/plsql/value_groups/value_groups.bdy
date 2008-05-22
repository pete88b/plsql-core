CREATE OR REPLACE PACKAGE BODY value_groups
AS
  

  FUNCTION get_filtered(
    p_description IN VARCHAR2,
    p_group_name IN VARCHAR2
  )
  RETURN SYS_REFCURSOR
  IS
    l_result SYS_REFCURSOR;

  BEGIN
    logger.ms('get_filtered');

    OPEN l_result FOR 
    SELECT *
    FROM   value_groups_data a
    WHERE  (UPPER(description) LIKE '%' || UPPER(p_description) || '%' OR (description IS NULL AND p_description IS NULL)) AND
           (UPPER(group_name) LIKE '%' || UPPER(p_group_name) || '%' OR (group_name IS NULL AND p_group_name IS NULL))
    ORDER BY group_name;

    RETURN l_result;

  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('Failed to get filtered value group');
      
      RAISE;

  END get_filtered;

END value_groups;
/
