CREATE OR REPLACE PACKAGE xml_helper 
IS

  /*
    Record to hold details of an XML element.
  */
  TYPE xml_element IS RECORD(
    start_tag VARCHAR2(2000),
    end_tag VARCHAR2(2000),
    content_start_pos INTEGER NOT NULL := 1,
    content_end_pos INTEGER NOT NULL := 1,
    content VARCHAR2(32767)
  );

  /*
    Returns a text representation of the specified XML element.
  */
  FUNCTION to_varchar(
    p_xml_element IN xml_element
  )
  RETURN VARCHAR2;

  /*
    Returns a new XML element record having set the start_tag and end_tag.
    
    p_cdata  p_tag_name  start_tag     end_tag
    -------  ----------  ------------  -------
    FALSE    a           <a>           </a>
    TRUE     a           <a><![CDATA[  ]]></a>
  */
  FUNCTION new_xml_element(
    p_tag_name IN VARCHAR2,
    p_cdata IN BOOLEAN := FALSE
  )
  RETURN xml_element;
  
  /*
    Resets the offset fields of the specified record.
    
    Note: The find procedures use the offset fields.
    
    The offset fields are content_start_pos and content_end_pos and are
    both set to 1.
  */
  PROCEDURE reset_offset(
    p_xml_element IN OUT xml_element
  );
  
  /*
    Tries to find the specified element in the specified XML source.
    
    If the element cannot be found, p_xml_element.content_start_pos
    will be set to 0 and content_start_pos.content will be NULL.
  */
  PROCEDURE find(
    p_xml IN CLOB,
    p_xml_element IN OUT xml_element,
    p_use_offset IN BOOLEAN := TRUE,
    p_un_escape_entities IN BOOLEAN := FALSE
  );

  /*
    Tries to find the specified element in the specified XML source.
    
    If the element cannot be found, p_xml_element.content_start_pos
    will be set to 0 and content_start_pos.content will be NULL.
  */
  PROCEDURE find(
    p_xml IN VARCHAR2,
    p_xml_element IN OUT xml_element,
    p_use_offset IN BOOLEAN := TRUE,
    p_un_escape_entities IN BOOLEAN := FALSE
  );
  
  /*
    Un-escapes XML predefined entities.
    
    Entity  Un-escaped value
    ------  ----------------
    &quot;  "
    &amp;   &
    &apos;  '
    &lt;    <
    &gt;    >
  */
  PROCEDURE un_escape_entities(
    p_xml_element IN OUT xml_element
  );
  
  /*
    XML does not allow nested comments
  */
  PROCEDURE remove_comments(
    p_xml IN OUT CLOB
  );
  
  PROCEDURE remove_comments(
    p_xml IN OUT VARCHAR2
  );
  
END xml_helper;
/
CREATE OR REPLACE PACKAGE BODY xml_helper 
IS
  
  /*
    Returns a text representation of the specified BOOLEAN value.
  */
  FUNCTION to_varchar(
    p_boolean IN BOOLEAN
  )
  RETURN VARCHAR2
  IS
  BEGIN
    IF (p_boolean)
    THEN
      RETURN 'TRUE';
    ELSIF(NOT p_boolean)
    THEN
      RETURN 'FALSE';
    ELSE
      RETURN NULL;
    END IF;
  END;
  
  /*
    Returns a text representation of the specified XML element.
  */
  FUNCTION to_varchar(
    p_xml_element IN xml_element
  )
  RETURN VARCHAR2
  IS
  BEGIN
    logger.entering('to_varchar');
    
    RETURN
      'xml_element [' || CHR(10) ||
      '  start_tag=' || p_xml_element.start_tag || CHR(10) || 
      '  end_tag=' || p_xml_element.end_tag || CHR(10) ||
      '  content_start_pos=' || p_xml_element.content_start_pos || CHR(10) ||
      '  content_end_pos=' || p_xml_element.content_end_pos || CHR(10) ||
      '  content=' || p_xml_element.content || CHR(10) ||
      ']';
      
  END;
  
  /*
    Returns a new XML element
  */
  FUNCTION new_xml_element(
    p_tag_name IN VARCHAR2,
    p_cdata IN BOOLEAN := FALSE
  )
  RETURN xml_element
  IS
    l_result xml_element;
    
  BEGIN
    logger.entering('new_xml_element');
    
    logger.fb(
      'p_tag_name=' || p_tag_name ||
      ', p_cdata=' || to_varchar(p_cdata));
    
    l_result.start_tag := '<' || p_tag_name || '>';
    l_result.end_tag := '</' || p_tag_name || '>';
    
    IF (p_cdata)
    THEN
      l_result.start_tag := l_result.start_tag || '<![CDATA[';
      l_result.end_tag := ']]>' || l_result.end_tag;
      
    END IF;
    
    RETURN l_result;
    
  END new_xml_element;
  
  /*
    Resets the offset fields of the specified record.
  */
  PROCEDURE reset_offset(
    p_xml_element IN OUT xml_element
  )
  IS
  BEGIN
    logger.entering('reset_offset');
    
    p_xml_element.content_start_pos := 1;
    p_xml_element.content_end_pos := 1;
    
  END;
  
  /*
    Tries to find the specified element in the specified XML source.
    
    If the element cannot be found, p_xml_element.content_start_pos
    will be set to 0 and content_start_pos.content will be NULL.
  */
  PROCEDURE find(
    p_xml IN CLOB,
    p_xml_element IN OUT xml_element,
    p_use_offset IN BOOLEAN := TRUE,
    p_un_escape_entities IN BOOLEAN := FALSE
  )
  IS
    l_offset INTEGER := 1;
    
  BEGIN
    logger.entering('find(CLOB)');
    
    IF (logger.g_log_level_feedback3 >= logger.get_feedback_level)
    THEN
      logger.fb('p_xml_element=' || to_varchar(p_xml_element));
      logger.fb('p_use_offset=' || to_varchar(p_use_offset));
    END IF;
    
    -- clear the content. If we can't find the element this must be null
    p_xml_element.content := NULL;
    
    IF (p_use_offset)
    THEN
      -- if we're using current element position for offset, set it now.
      -- otherwise we'll search from the start of the XML source
      l_offset := p_xml_element.content_end_pos;
      
    END IF;
    
    -- get the start position of the thing we're looking for
    p_xml_element.content_start_pos := 
      NVL(DBMS_LOB.INSTR(p_xml, p_xml_element.start_tag, l_offset), 0);
      
    IF (p_xml_element.content_start_pos != 0)
    THEN
      -- if we found the thing we're looking for, adjust the start position
      -- to be the end of the thing we just found
      p_xml_element.content_start_pos := 
        p_xml_element.content_start_pos + LENGTH(p_xml_element.start_tag);
      
      -- get the end position
      p_xml_element.content_end_pos :=
        NVL(DBMS_LOB.INSTR(
            p_xml, p_xml_element.end_tag, p_xml_element.content_start_pos), 0);
      
      -- set the content to be the data between the start and end positions
      p_xml_element.content :=
        DBMS_LOB.SUBSTR(
            p_xml, 
            p_xml_element.content_end_pos - p_xml_element.content_start_pos, 
            p_xml_element.content_start_pos);
      
    END IF;
    
    IF (p_un_escape_entities)
    THEN
      un_escape_entities(p_xml_element);
    END IF;
    
    IF (logger.g_log_level_feedback3 >= logger.get_feedback_level)
    THEN
      logger.fb('EXITING: p_xml_element=' || to_varchar(p_xml_element));
    END IF;
    
  END find;
 
  /*
    Tries to find the specified element in the specified XML source.
    
    If the element cannot be found, p_xml_element.content_start_pos
    will be set to 0 and content_start_pos.content will be NULL.
  */
  PROCEDURE find(
    p_xml IN VARCHAR2,
    p_xml_element IN OUT xml_element,
    p_use_offset IN BOOLEAN := TRUE,
    p_un_escape_entities IN BOOLEAN := FALSE
  )
  IS
    l_offset INTEGER := 1;
    
  BEGIN
    logger.entering('find(VARCHAR2)');
    
    IF (logger.g_log_level_feedback3 >= logger.get_feedback_level)
    THEN
      logger.fb('p_xml=' || p_xml);
      logger.fb('p_xml_element=' || to_varchar(p_xml_element));
      logger.fb('p_use_offset=' || to_varchar(p_use_offset));
    END IF;
    
    -- clear the content. If we can't find the element this must be null
    p_xml_element.content := NULL;
    
    IF (p_use_offset)
    THEN
      -- if we're using current element position for offset, set it now.
      -- otherwise we'll search from the start of the XML source
      l_offset := p_xml_element.content_end_pos;
    END IF;
    
    -- get the start position of the thing we're looking for
    p_xml_element.content_start_pos := 
      NVL(INSTR(p_xml, p_xml_element.start_tag, l_offset), 0);
      
    IF (p_xml_element.content_start_pos != 0)
    THEN
      -- if we found the thing we're looking for, adjust the start position
      -- to be the end of the thing we just found
      p_xml_element.content_start_pos := 
        p_xml_element.content_start_pos + LENGTH(p_xml_element.start_tag);
        
      -- get the end position
      p_xml_element.content_end_pos :=
        NVL(INSTR(
            p_xml, p_xml_element.end_tag, p_xml_element.content_start_pos), 0);
      
      -- set the content to be the data between the start and end positions
      p_xml_element.content :=
        SUBSTR(
            p_xml, 
            p_xml_element.content_start_pos,
            p_xml_element.content_end_pos - p_xml_element.content_start_pos);
      
    END IF;
    
    IF (p_un_escape_entities)
    THEN
      un_escape_entities(p_xml_element);
    END IF;
    
    IF (logger.g_log_level_feedback3 >= logger.get_feedback_level)
    THEN
      logger.fb('EXITING: p_xml_element=' || to_varchar(p_xml_element));
    END IF;
    
  END find;
  
  PROCEDURE un_escape_entities(
    p_xml_element IN OUT xml_element
  )
  IS
  BEGIN
    logger.entering('un_escape_entities');
    
    p_xml_element.content := REPLACE(p_xml_element.content, '&quot;', '"');
    p_xml_element.content := REPLACE(p_xml_element.content, '&amp;', '&');
    p_xml_element.content := REPLACE(p_xml_element.content, '&apos;', '''');
    p_xml_element.content := REPLACE(p_xml_element.content, '&lt;', '<');
    p_xml_element.content := REPLACE(p_xml_element.content, '&gt;', '>');
    
  END un_escape_entities;
  
  PROCEDURE remove_comments(
    p_xml IN OUT CLOB
  )
  IS
    l_comment_start_pos INTEGER;
    l_comment_end_pos INTEGER;
    l_length INTEGER;
    l_amount INTEGER;
    
  BEGIN
    logger.entering('remove_comments(CLOB');
    
    LOOP
      l_comment_start_pos := NVL(DBMS_LOB.INSTR(p_xml, '<!--', 1), 0);
      logger.fb5('l_comment_start_pos=' || l_comment_start_pos);
      
      -- if we can't find the start of a comment, we're done
      EXIT WHEN (l_comment_start_pos = 0);
      
      -- look for the end of the comment
      l_comment_end_pos := NVL(DBMS_LOB.INSTR(p_xml, '-->', l_comment_start_pos), 0);
      logger.fb5('l_comment_end_pos=' || l_comment_end_pos);
      
      IF (l_comment_end_pos > l_comment_start_pos)
      THEN
        -- if we found the end of the comment, we'll remove it now
        l_length := DBMS_LOB.GETLENGTH(p_xml);
        logger.fb5('l_length=' || l_length);
      
        l_amount := l_length - l_comment_end_pos - 2;
        logger.fb5('l_amount=' || l_amount);
        
        -- removing the comment is a 2 step process:
        --   COPY : move everything that follows the comment to where the comment starts
        --   TRIM : remove as many characters as there were in the comment from the end 
        -- e.g.
        --   p_xml: <b><!--B--></b>
        --   COPY : <b></b>B--></b> 
        --   TRIM : <b></b>
        
        -- l_amount will be zero when p_xml ends with a comment. 
        -- If that is the case, all we need to do is trim
        IF (l_amount > 0)
        THEN
          DBMS_LOB.COPY(
            p_xml, 
            p_xml,
            l_amount,
            l_comment_start_pos,
            l_comment_end_pos + 3);
            
        END IF;
        
        DBMS_LOB.TRIM(
          p_xml,
          l_length - (l_comment_end_pos - l_comment_start_pos) - 3);
        
      ELSE
        -- if we couldn't find the end of the comment, the XML passed in is invalid
        RAISE_APPLICATION_ERROR(
          -20000, 
          'Failed to remove comments: un-closed comment starting at ' || 
          l_comment_start_pos);
          
      END IF;
      
    END LOOP;
    
  END remove_comments;
  
  PROCEDURE remove_comments(
    p_xml IN OUT VARCHAR2
  )
  IS
    l_comment_start_pos INTEGER;
    
  BEGIN
    logger.entering('remove_comments(VARCHAR2)');
    
    logger.fb('p_xml=' || p_xml);
    
    p_xml := REGEXP_REPLACE(p_xml, '<!--.*?-->', NULL);
    
    l_comment_start_pos := NVL(INSTR(p_xml, '<!--'), 0);
    
    IF (l_comment_start_pos != 0)
    THEN
      RAISE_APPLICATION_ERROR(
        -20000, 
        'Failed to remove comments: un-closed comment starting at ' || 
        l_comment_start_pos);
        
    END IF;
    
    logger.fb5('p_xml=' || p_xml);
    
  END remove_comments;


END xml_helper;
/
