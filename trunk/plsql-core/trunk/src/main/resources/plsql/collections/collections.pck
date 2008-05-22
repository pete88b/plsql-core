CREATE OR REPLACE PACKAGE collections 
IS
  
  FUNCTION convert(
    p_from IN DBMS_SQL.VARCHAR2_TABLE
  )
  RETURN varchar_table;

  FUNCTION convert(
    p_from IN DBMS_SQL.NUMBER_TABLE
  )
  RETURN number_table;
  
END collections;
/
CREATE OR REPLACE PACKAGE BODY collections 
IS
  FUNCTION convert(
    p_from IN DBMS_SQL.VARCHAR2_TABLE
  )
  RETURN varchar_table
  IS
    l_result varchar_table;
    l_from_index INTEGER := p_from.FIRST;
    l_to_index INTEGER := 0;
  BEGIN
    logger.ms('convert(DBMS_SQL.VARCHAR2_TABLE)');
    
    -- never return an uninitialised collection
    l_result := varchar_table();
    
    IF (l_from_index IS NULL)
    THEN
      logger.fb('p_from is empty. returning empty collection');
      RETURN l_result;
      
    END IF;
    
    logger.fb('found first index ' || l_from_index);
    
    LOOP
      logger.fb1('copying value for index ' || l_from_index);
      
      l_result.EXTEND(1);
      l_to_index := l_to_index + 1;
      l_result(l_to_index) := p_from(l_from_index);
      
      l_from_index := p_from.NEXT(l_from_index);
      
      EXIT WHEN l_from_index IS NULL;
      
    END LOOP;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('failed to convert DBMS_SQL.VARCHAR2_TABLE');
      RAISE;
    
  END;
  
  FUNCTION convert(
    p_from IN DBMS_SQL.NUMBER_TABLE
  )
  RETURN number_table
  IS
    l_result number_table;
    l_from_index INTEGER := p_from.FIRST;
    l_to_index INTEGER := 0;
  BEGIN
    logger.ms('convert(DBMS_SQL.NUMBER_TABLE)');
    
    -- never return an uninitialised collection
    l_result := number_table();
    
    IF (l_from_index IS NULL)
    THEN
      logger.fb('p_from is empty. returning empty collection');
      RETURN l_result;
      
    END IF;
    
    logger.fb('found first index ' || l_from_index);
    
    LOOP
      logger.fb1('copying value for index ' || l_from_index);
      
      l_result.EXTEND(1);
      l_to_index := l_to_index + 1;
      l_result(l_to_index) := p_from(l_from_index);
      
      l_from_index := p_from.NEXT(l_from_index);
      
      EXIT WHEN l_from_index IS NULL;
      
    END LOOP;
    
    RETURN l_result;
    
  EXCEPTION
    WHEN OTHERS
    THEN
      logger.error('failed to convert DBMS_SQL.NUMBER_TABLE');
      RAISE;
    
  END;
  
END collections;
/
