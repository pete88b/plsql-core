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
  l_array DBMS_SQL.VARCHAR2_TABLE;
  l_result varchar_table_type;
  
  l_array_num DBMS_SQL.NUMBER_TABLE;
  l_result_num number_table_type;
  
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(s);
  END;
  
  PROCEDURE p(
    b IN BOOLEAN
  )
  IS
  BEGIN
    IF (b)
    THEN
      DBMS_OUTPUT.PUT_LINE('true');
    ELSIF (NOT b)
    THEN
      DBMS_OUTPUT.PUT_LINE('false');
    ELSE
      DBMS_OUTPUT.PUT_LINE('null');
    END IF;
    
  END;
  
BEGIN
  -- varchar
  p('VARCHAR');
  p(l_result IS NULL);
  l_result := collections.convert(l_array);
  p(l_result IS NULL);
  p('l_result.FIRST=' || l_result.FIRST);

  l_array(3) := 'three';
  l_array(9) := 'nine';
  l_result := collections.convert(l_array);
  p(l_result IS NULL);
  p('l_result.FIRST=' || l_result.FIRST);
  p('l_result.LAST=' || l_result.LAST);
  
  p('l_array.FIRST=' || l_array.FIRST);
  
  -- number
  p('NUMBER');
  p(l_result_num IS NULL);
  l_result_num := collections.convert(l_array_num);
  p(l_result_num IS NULL);
  p('l_result_num.FIRST=' || l_result_num.FIRST);

  l_array_num(3) := 3;
  l_array_num(9) := 9;
  l_result_num := collections.convert(l_array_num);
  p(l_result_num IS NULL);
  p('l_result_num.FIRST=' || l_result_num.FIRST);
  p('l_result_num.LAST=' || l_result_num.LAST);
  
  p('l_array_num.FIRST=' || l_array_num.FIRST);
  
END;