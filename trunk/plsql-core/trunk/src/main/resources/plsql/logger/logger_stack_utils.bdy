CREATE OR REPLACE PACKAGE BODY logger_stack_utils
IS
  
  /*
    Parses the specified call stack returning details of the specified line.
    
    Call stack lines are terminated by CHR(10).
    
    This call is on line 3
    who am i is on line 4
    who called me is on line 5
  */
  PROCEDURE parse_stack(
    p_stack IN VARCHAR2,
    p_stack_line IN POSITIVE,
    p_who_record OUT who_record_type
  )
  IS
    -- define a constant for the character that identifies the end of a line
    l_eol CONSTANT VARCHAR2(1) := CHR(10);
    
    -- define a constant for a single space
    l_a_space CONSTANT VARCHAR2(1) := CHR(32);
    
    -- define a constant for 2 spaces
    l_two_spaces CONSTANT VARCHAR2(2) := CHR(32) || CHR(32);
    
    -- start position of the row we're interested in (in the stack)
    l_call_start_position INTEGER;
    
    -- end position of the row we're interested in (in the stack)
    l_call_end_position INTEGER;
    
    -- the row that we're interested in from the call stack
    l_call VARCHAR2(32767);
    
  BEGIN
    -- set the initial call level to 0
    p_who_record.level := 0;
    
    -- find the start position of the row we're interested in (in the stack)
    l_call_start_position := INSTR(
                               p_stack, 
                               l_eol, 
                               1, 
                               p_stack_line) + 1;
    
    -- find the end position of the row we're interested in (in the stack)
    l_call_end_position := INSTR(
                             p_stack, 
                             l_eol, 
                             1, 
                             1 + p_stack_line);
    
    -- Get the row that we're interested in from the call stack
    l_call := LOWER(
                LTRIM(
                  SUBSTR(
                    p_stack,
                    l_call_start_position,
                    l_call_end_position - l_call_start_position)));
    
    -- if l_call is null, the requested stack line does not exist
    IF (l_call IS NOT NULL)
    THEN
      -- Replace multiple consecutive spaces with a single space
      LOOP
        EXIT WHEN(INSTR(l_call, l_two_spaces) = 0);
        l_call := REPLACE(l_call, l_two_spaces, l_a_space);
        
      END LOOP;
      
      -- Remove the object handle
      l_call := SUBSTR(l_call, INSTR(l_call, l_a_space) + 1);
      
      -- The line number is now at the start of l_call
      p_who_record.line := SUBSTR(l_call, 1, INSTR(l_call, l_a_space) - 1);
      
      -- Remove the line number
      l_call := SUBSTR(l_call, INSTR(l_call, l_a_space) + 1);
      
      -- the object type is now at the start of l_call
      -- Get the object type and remove it from l_call
      IF (l_call LIKE 'package body%') THEN
        p_who_record.type := 'package body';
        l_call := SUBSTR(l_call, 14);
      
      ELSIF (l_call LIKE 'package%') THEN
        p_who_record.type := 'package';
        l_call := SUBSTR(l_call, 9);
      
      ELSIF (l_call LIKE 'procedure%') THEN
        p_who_record.type := 'procedure';
        l_call := SUBSTR(l_call, 11);
      
      ELSIF (l_call LIKE 'function%') THEN
        p_who_record.type := 'function';
        l_call := SUBSTR(l_call, 10);
      
      ELSIF (l_call LIKE 'anonymous block%') THEN
        p_who_record.type := 'anonymous block';
        l_call := SUBSTR(l_call, 17);
      
      ELSE
        p_who_record.type := 'trigger';
        -- NOTE: 'trigger' does not need to be removed from l_call
      
      END IF;
      
      -- Having removed the object type, the only thing left in l_call 
      -- is the qualified name
      p_who_record.owner := SUBSTR(l_call, 1, INSTR(l_call, '.') - 1);
      p_who_record.name := SUBSTR(l_call, INSTR(l_call, '.') + 1);
      
      -- the call level is the number of calls in the stack below the call that
      -- we're interested in plus one. (We get the plus one as the call stack 
      -- always ends with an empty line).
      -- e.g. if there are no calls below the call that we're interested in the
      -- call level is one.
      <<get_call_level_loop>>
      WHILE (INSTR(
               p_stack, 
               l_eol, 
               l_call_end_position, 
               p_who_record.level + 1) != 0)
      LOOP
        p_who_record.level := p_who_record.level + 1;
        
      END LOOP get_call_level_loop;
      
    END IF; -- End of IF (l_call IS NOT NULL)
    
  END parse_stack;
  
  
  /*
    Return details of stack line 4.
  */
  PROCEDURE who_am_i(
    p_who_record OUT who_record_type
  )
  IS
  BEGIN
    parse_stack(DBMS_UTILITY.FORMAT_CALL_STACK, 4, p_who_record);
      
  END who_am_i;
  
  
  /*
    Return details of stack line 5.
  */
  PROCEDURE who_called_me(
    p_who_record OUT who_record_type
  )
  IS
  BEGIN
    parse_stack(DBMS_UTILITY.FORMAT_CALL_STACK, 5, p_who_record);
      
  END who_called_me;
  
  
  /*
    Return details of stack line 6.
  */
  PROCEDURE who_called_my_caller(
    p_who_record OUT who_record_type
  )
  IS
  BEGIN
    parse_stack(DBMS_UTILITY.FORMAT_CALL_STACK, 6, p_who_record);
      
  END who_called_my_caller;
  
  
  /*
    Return details of stack line 7.
  */
  PROCEDURE who_called_my_callers_caller(
    p_who_record OUT who_record_type
  )
  IS
  BEGIN
    parse_stack(DBMS_UTILITY.FORMAT_CALL_STACK, 7, p_who_record);
      
  END who_called_my_callers_caller;
  
  
  /*
    Return details of the specified stack line.
  */
  PROCEDURE who_called(
    p_stack_line IN POSITIVE,
    p_who_record OUT who_record_type
  )
  IS
  BEGIN
    parse_stack(DBMS_UTILITY.FORMAT_CALL_STACK, p_stack_line, p_who_record);
      
  END who_called;
  
  
END logger_stack_utils;
/
