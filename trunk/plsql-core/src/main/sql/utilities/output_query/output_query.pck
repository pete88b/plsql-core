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

CREATE OR REPLACE PACKAGE output_query
IS
  
  -- Note: The following are not defined as constants as they may need to be 
  -- changed for different database character sets.

  -- Line feed
  line_feed VARCHAR2(1) := CHR(10); 
  -- Form feed
  form_feed VARCHAR2(1) := CHR(12); 
  -- Carriage return
  cariage_return VARCHAR2(1) := CHR(13); 
  -- A single space
  one_space VARCHAR2(1) := CHR(32); 

  /*
    An output procedure for use on pre-10g databases.
    This calls DBMS_OUTPUT.PUT_LINE passing no more than 255 characters.
  */
  PROCEDURE put_line_pre_10g (
    p_data IN VARCHAR2
  );

  /*
    Send the results of the specified select statement to the 
    specified output procedure.
    
    p_sql 
      Must be a select statment.
    p_output_procedure 
      The procedure called to output a line of data.
      This can be any procedure that takes a single varchar argument.
    p_col_lengths
      A comma separated list of column lengths. 
    p_default_col_length 
      The column length to use if not specified by p_col_lengths.
    p_col_seperator
      The string which should be used to separate columns in the output.
  */
  PROCEDURE to_output (
    p_sql IN VARCHAR2,
    p_output_procedure IN VARCHAR2 := 'DBMS_OUTPUT.PUT_LINE',
    p_col_lengths IN VARCHAR2 := NULL,
    p_default_col_length IN INTEGER := 20,
    p_col_seperator IN VARCHAR2 := one_space
  );
  
END output_query;
/
CREATE OR REPLACE PACKAGE BODY output_query
IS
  
  -- array to hold tokens created by a call to set_tokens
  l_tokens DBMS_SQL.VARCHAR2_TABLE;
  
  /*
    Splits a delimited string and saves the tokens in l_tokens.
    
    p_text
      The string to split.
    p_delim
      The delimiter.
  */
  PROCEDURE set_tokens (
    p_text IN VARCHAR2,
    p_delim IN VARCHAR2
  )
  IS
    -- Set l_text to initially be the text string input
    l_text VARCHAR2(32767) := p_text;
    -- The position of the last char on our token
    l_end_at INTEGER;
    -- The position of the first char that we want to keep in l_text
    l_nibble_from INTEGER;
    -- Set to true when there are no more delimiters
    l_no_more_delims BOOLEAN := FALSE;
    
  BEGIN
    -- Remove everything from the collection of tokens
    l_tokens.DELETE;
    
    WHILE (NOT l_no_more_delims)
    LOOP
      -- Look for the position of the delimiter that indicates the end of the next token
      l_end_at := NVL(INSTR(l_text, p_delim, 1, 1), 0);
      -- If we can't find a delimiter that indicates the end of the token, we could be 
      -- looking at the last token OR we could be looking for tokens that don't exist.
      IF (l_end_at = 0)
      THEN
        -- we have no more delimiters
        l_no_more_delims := TRUE;
        -- If we're looking for tokens that don't exist, l_end_at will be set to 0 
        -- (as l_text will be empty) so the next token will be set to NULL. 
        -- Otherwise we want to set the next token to whatever is left in l_text
        l_end_at := LENGTH(l_text) + 1; 
      END IF;
      -- we want to nibble all text off l_text up to and including the first delim
      l_nibble_from := l_end_at;
      -- Get the token from the string based on the positions found above,
      -- trim white space and add it to the collection of tokens.
      l_tokens(NVL(l_tokens.LAST, 0) + 1) := 
        LTRIM(RTRIM(SUBSTR(l_text, 1, l_end_at - 1)));
      -- Remove the token that we just found from the text that we're parsing
      l_text := LTRIM(SUBSTR(l_text, l_nibble_from + 1));

    END LOOP;

  END set_tokens;
  
  /*
    Returns a token from l_tokens.
    
    p_token_index
      The index of the token to return.
    p_value_when_token_not_found
      The value to return when p_token_index does not exist 
      (rather than raising a no data found exception).
  */
  FUNCTION get_token (
     p_token_index IN INTEGER,
     p_value_when_token_not_found IN VARCHAR2 := NULL
  )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN l_tokens(p_token_index);

  EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      RETURN p_value_when_token_not_found;

  END get_token;
  
  /*
    Outputs at most 255 characters of the specified data via dbms_output.
  */
  PROCEDURE put_line_pre_10g (
    p_data IN VARCHAR2
  )
  IS
  BEGIN
    IF (LENGTH(p_data) > 255)
    THEN
      DBMS_OUTPUT.PUT_LINE(SUBSTR(p_data, 1, 254) || '~');
    ELSE
      DBMS_OUTPUT.PUT_LINE(p_data);
    END IF;
  END put_line_pre_10g;

  /*
    Sends results of the specified select statement to the 
    specified output procedure.
  */
  PROCEDURE to_output (
    p_sql IN VARCHAR2,
    p_output_procedure IN VARCHAR2 := 'DBMS_OUTPUT.PUT_LINE',
    p_col_lengths IN VARCHAR2 := NULL,
    p_default_col_length IN INTEGER := 20,
    p_col_seperator IN VARCHAR2 := one_space
  )
  IS
    -- Holds column descriptions returned by DBMS_SQL.DESCRIBE_COLUMNS
    l_metadata DBMS_SQL.DESC_TAB;
    -- Holds number of columns returned by DBMS_SQL.DESCRIBE_COLUMNS
    l_columns INTEGER;
    -- Collection type who's elements can hold the data of a single column
    TYPE data_table IS TABLE OF VARCHAR2(4000) INDEX BY BINARY_INTEGER;
    -- Holds the data of a single row - one index per column.
    l_data data_table;
    -- Handle to the cursor that we'll use to run p_sql
    l_cur INTEGER := DBMS_SQL.OPEN_CURSOR;
    -- The return value of DBMS_SQL.EXECUTE (which is ignored)
    l_result INTEGER;

    /*
      Wraps column data to col width and writes to output
    */
    PROCEDURE wrap_and_output
    IS
      -- Set to true when there is no more data to output
      l_no_more_data BOOLEAN := FALSE;
      -- The current line of output
      l_line VARCHAR2(2000);
      -- Position at which to break a columns' data
      l_break_pos INTEGER;
      -- holds the current column width
      -- NOTE: The only use of set_tokens / gel_tokens in to_output
      -- should be to set and get column widths
      l_col_width INTEGER;
      
      /*
        Add some data to the current line of output
      */
      PROCEDURE add_to_line (
        p_data IN VARCHAR2
      )
      IS
      BEGIN
        l_line := l_line || p_data || p_col_seperator;
      END add_to_line;

      /*
      */
      PROCEDURE output_line
      IS
      BEGIN
        EXECUTE IMMEDIATE 
          'BEGIN ' || p_output_procedure || '(''' || REPLACE(l_line, '''', '''''') || '''); END;';
        l_line := NULL;
        
      END output_line;
            
    BEGIN
      -- Format l_data and add as rows to t_results
      <<wrap_col_data_loop>>
      LOOP
        EXIT WHEN l_no_more_data;
        -- Indicate that we have no more data. This will be set to FALSE if any
        -- columns need to be wrapped (forcing another iteration)
        l_no_more_data := TRUE;
        
        FOR i IN l_data.FIRST .. l_data.LAST
        LOOP
          -- Get the desired width of this column
          l_col_width := NVL(get_token(i), p_default_col_length);
          -- See if the data in this column is longer than the desired width
          IF (NVL(LENGTH(l_data(i)), 0) > l_col_width)
          THEN
            -- If at least one column needs to be wrapped we have more data
            -- so we need to iterate the wrap_col_data_loop again
            l_no_more_data := FALSE;
            -- Get the position of the last space that is within the first
            -- col_width characters
            l_break_pos := 
              INSTR(l_data(i), one_space, l_col_width - LENGTH(l_data(i)));
              
            IF (l_break_pos = 0)
            THEN
              -- If we can't find a space, we'll break at col_width
              l_break_pos := l_col_width;
              
            END IF;
            
          ELSE
            -- If the column does not need to be wrapped, use the full col width
            l_break_pos := l_col_width;
            
          END IF; -- End of IF (NVL(LENGTH(l_data(i)), 0) > l_col_width)
          
          -- Output this piece of column data (padded to col_width)
          add_to_line(RPAD(SUBSTR(l_data(i), 1, l_break_pos), l_col_width));
          
          -- remove this piece of column data from l_data
          l_data(i) := NVL(SUBSTR(l_data(i), l_break_pos + 1), one_space);
          
        END LOOP;
        
        -- Output the line
        output_line;
                
      END LOOP wrap_col_data_loop;
      
    END wrap_and_output;
    
  BEGIN
    DBMS_OUTPUT.ENABLE(1000000);
    
    -- Accept only SELECT statements
    <<check_statement>>
    DECLARE
      l_sql VARCHAR2(32767);
      
    BEGIN
      l_sql := UPPER(p_sql);
      l_sql := REPLACE(l_sql, line_feed, NULL);
      l_sql := REPLACE(l_sql, form_feed, NULL);
      l_sql := REPLACE(l_sql, cariage_return, NULL);
      l_sql := LTRIM(l_sql);
      
      IF (INSTR(l_sql, 'SELECT') <> 1)
      THEN
        RAISE_APPLICATION_ERROR(-20001, '"SELECT" statements only');
      END IF;
      
    END check_statement;
    
    -- Set the column widths
    set_tokens(p_col_lengths, ',');
    -- Parse p_sql
    DBMS_SQL.PARSE(l_cur, p_sql, DBMS_SQL.NATIVE);
    -- Call DESCRIBE_COLUMNS to get the number of columns returned by the query
    DBMS_SQL.DESCRIBE_COLUMNS(l_cur, l_columns, l_metadata);
    
    -- Define all columns to returned to be of VARCHAR2(4000) data type
    FOR i IN 1 .. l_columns
    LOOP
      -- Put headers into l_data
      -- (1) to initialize every element in l_data that we need for the define
      -- (2) so that we can call wrap_and_output to display headers
      l_data(i) := l_metadata(i).col_name;
      
      DBMS_SQL.DEFINE_COLUMN(l_cur, i, l_data(i), 4000);

    END LOOP;
    -- Write headers to output
    wrap_and_output;
    
    -- Run the query 
    -- Note: the value returned by execute for a select statement is undefined
    -- and should be ignored
    l_result := DBMS_SQL.EXECUTE(l_cur);
    
    <<row_loop>>
    WHILE (DBMS_SQL.FETCH_ROWS(l_cur) > 0)
    LOOP
      -- Put a complete row of data into l_data
      << get_col_data_loop >>
      FOR i IN 1 .. l_columns
      LOOP
        -- Get the data
        DBMS_SQL.COLUMN_VALUE(l_cur, i, l_data(i));
        -- Replace line breaking white space with a non-breaking space
        l_data(i) := REPLACE(l_data(i), cariage_return || line_feed, one_space);
        l_data(i) := REPLACE(l_data(i), line_feed, one_space);
        l_data(i) := REPLACE(l_data(i), cariage_return, one_space);
        l_data(i) := NVL(l_data(i), one_space);
        
      END LOOP get_col_data_loop;
      
      wrap_and_output;
      
    END LOOP row_loop;
    
    DBMS_SQL.CLOSE_CURSOR(l_cur);
    
  END to_output;
  
END output_query;
/
