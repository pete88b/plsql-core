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
