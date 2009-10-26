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

SET DEFINE OFF

DECLARE

  l_xml varchar2(32767) := 
  '<root>
    <row>
      <FREE_TEXT><![CDATA[free text one]]></FREE_TEXT>
      <other_text>other text one</other_text>
      <NESTED_ROWSET>
        <nested_item>
          <a>nested item one</a>
          <B></B>
          <c/>
        </nested_item>
        <nested_item><a>nested item one/two</a><B>b1.2</B><c>c1.2</c></nested_item>
        <nested_item>
          <a>nested item one/three</a>
          <B>b1.3</B>
          <c/>
        </nested_item>
      </NESTED_ROWSET>
      <number>1</number>
    </row>
    
    <row>
      <FREE_TEXT><![CDATA[free text two]]></FREE_TEXT>
      <other_text>other text two</other_text>
      
      <NESTED_ROWSET>
        <nested_item>
          <a>nested item two</a>
          <B>b2.1</B>
          <c>c2.1</c>
        </nested_item>
      </NESTED_ROWSET>
      <number>2</number>
    </row>
  </root>';
  
  l_xml_clob CLOB;
  l_xml_element xml_helper.xml_element;
  l_xml_element2 xml_helper.xml_element;
  l_expected VARCHAR2(32767);
  
  PROCEDURE p(
    s IN VARCHAR2
  )
  IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(s);
  END p;

  PROCEDURE assert(
    p_condition IN BOOLEAN,
    p_message IN VARCHAR2
  )
  IS
  BEGIN
    IF (NOT p_condition OR p_condition IS NULL)
    THEN
      p('ASSERT FAIL');
      p('');
      p(p_message);
      raise_application_error(
        -20000, p_message);
    END IF;
  END;
  
  PROCEDURE assert_equal(
    p_xml_element IN xml_helper.xml_element,
    p_xml_element2 IN xml_helper.xml_element
  )
  IS
    PROCEDURE compare_part(
      p_a IN VARCHAR2,
      p_b IN VARCHAR2,
      p_what IN VARCHAR2
    )
    IS
    BEGIN
      assert(
        p_a = p_b OR (p_a IS NULL AND p_b IS NULL),
        'mismatch of ' || p_what ||
        ' expected="' || xml_helper.to_varchar(p_xml_element) || 
        '" result="' || xml_helper.to_varchar(p_xml_element2) || '"');
    END;
  BEGIN
    compare_part(p_xml_element.start_tag, p_xml_element2.start_tag, 'start_tag');
    compare_part(p_xml_element.end_tag, p_xml_element2.end_tag, 'end_tag');
    compare_part(p_xml_element.content_start_pos, p_xml_element2.content_start_pos, 'start_pos');
    compare_part(p_xml_element.content_end_pos, p_xml_element2.content_end_pos, 'end_pos');
    compare_part(p_xml_element.content, p_xml_element2.content, 'content');
    
  END;
  
BEGIN
  l_expected := 
    'xml_element [' || CHR(10) ||
    '  start_tag=' || CHR(10) || 
    '  end_tag=' || CHR(10) ||
    '  content_start_pos=1' || CHR(10) ||
    '  content_end_pos=1' || CHR(10) ||
    '  content=' || CHR(10) ||
    ']';
  
  assert(
    l_expected = xml_helper.to_varchar(l_xml_element),
    'expected="' || l_expected || '" result="' || xml_helper.to_varchar(l_xml_element) || '"');
  
  l_xml_element.start_tag := 'a';
  l_xml_element.end_tag := 'b';
  l_xml_element.content := 'c';
  
  l_expected := 
    'xml_element [' || CHR(10) ||
    '  start_tag=a' || CHR(10) || 
    '  end_tag=b' || CHR(10) ||
    '  content_start_pos=1' || CHR(10) ||
    '  content_end_pos=1' || CHR(10) ||
    '  content=c' || CHR(10) ||
    ']';
  
  assert(
    l_expected = xml_helper.to_varchar(l_xml_element),
    'expected="' || l_expected || '" result="' || xml_helper.to_varchar(l_xml_element) || '"');
  
  l_xml_element := xml_helper.new_xml_element('a');
  
  l_xml_element2.start_tag := '<a>';
  l_xml_element2.end_tag := '</a>';
  
  assert_equal(l_xml_element2, l_xml_element);
  
  l_xml_element := xml_helper.new_xml_element('a', TRUE);
  
  l_xml_element2.start_tag := '<a><![CDATA[';
  l_xml_element2.end_tag := ']]></a>';
  
  assert_equal(l_xml_element2, l_xml_element);
  
  l_xml_element.content_start_pos := 9;
  l_xml_element.content_end_pos := 9;
  l_xml_element.content := 'anything';
  
  l_xml_element2.content_start_pos := 9;
  l_xml_element2.content_end_pos := 9;
  l_xml_element2.content := 'anything';
  
  assert_equal(l_xml_element2, l_xml_element);
  
  xml_helper.reset_offset(l_xml_element);
  
  l_xml_element2.content_start_pos := 1;
  l_xml_element2.content_end_pos := 1;
  
  assert_equal(l_xml_element2, l_xml_element);
  
  -- START OF find section CLOB
  
  dbms_lob.createtemporary(l_xml_clob, true);
  dbms_lob.write(l_xml_clob, length(l_xml), 1, l_xml);
  
  l_xml_element := xml_helper.new_xml_element('root');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  
  l_expected := SUBSTR(l_xml, 7, LENGTH(l_xml) - 13);
  
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  
  l_xml_element := xml_helper.new_xml_element('FREE_TEXT', TRUE);
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'free text one';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  for i in 1 .. 9
  loop
    xml_helper.find(l_xml_clob, l_xml_element, FALSE);
    assert(
      l_expected = l_xml_element.content,
      'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  end loop;
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'free text two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  
  l_xml_element := xml_helper.new_xml_element('a');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'nested item one';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'nested item one/two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml_clob, l_xml_element, FALSE);
  l_expected := 'nested item one';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'nested item one/two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'nested item one/three';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'nested item two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  assert(
    l_xml_element.content IS NULL,
    'expected=NULL result="' || l_xml_element.content || '"');
  
  
  l_xml_element := xml_helper.new_xml_element('B');
  
  xml_helper.find(l_xml_clob, l_xml_element);
  xml_helper.find(l_xml_clob, l_xml_element);
  xml_helper.find(l_xml_clob, l_xml_element);
  l_expected := 'b1.3';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  

  -- START OF find section VARCHAR
  
  l_xml_element := xml_helper.new_xml_element('root');
  
  xml_helper.find(l_xml, l_xml_element);
  
  l_expected := SUBSTR(l_xml, 7, LENGTH(l_xml) - 13);
  
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  
  l_xml_element := xml_helper.new_xml_element('FREE_TEXT', TRUE);
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'free text one';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  for i in 1 .. 9
  loop
    xml_helper.find(l_xml, l_xml_element, FALSE);
    assert(
      l_expected = l_xml_element.content,
      'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  end loop;
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'free text two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  
  l_xml_element := xml_helper.new_xml_element('a');
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'nested item one';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'nested item one/two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml, l_xml_element, FALSE);
  l_expected := 'nested item one';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'nested item one/two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'nested item one/three';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'nested item two';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');
  
  xml_helper.find(l_xml, l_xml_element);
  assert(
    l_xml_element.content IS NULL,
    'expected=NULL result="' || l_xml_element.content || '"');
  
  
  l_xml_element := xml_helper.new_xml_element('B');
  
  xml_helper.find(l_xml, l_xml_element);
  xml_helper.find(l_xml, l_xml_element);
  xml_helper.find(l_xml, l_xml_element);
  l_expected := 'b1.3';
  assert(
    l_expected = l_xml_element.content,
    'expected="' || l_expected || '" result="' || l_xml_element.content || '"');


  -- test remove comments

  l_xml := '<b><!--B--></b>';
  
  dbms_lob.createtemporary(l_xml_clob, true);
  dbms_lob.write(l_xml_clob, length(l_xml), 1, l_xml);
  xml_helper.remove_comments(l_xml_clob);
  l_expected := dbms_lob.substr(l_xml_clob);
  xml_helper.remove_comments(l_xml);
  assert(
    l_expected = l_xml,
    'expected="' || l_expected || '" result="' || l_xml || '"');
  

  l_xml := '
    <!--start comment-->
    <a><b><!--B--></b><c><!--<d></d>--></c><!--text in a--></a>
    <a><!---->
      <b><!--B--></b>
      <c><!--<d></d>--></c>
      <!--text in a-->
    </a>
    <!--end comment-->';

  dbms_lob.createtemporary(l_xml_clob, true);
  dbms_lob.write(l_xml_clob, length(l_xml), 1, l_xml);
  xml_helper.remove_comments(l_xml_clob);
  l_expected := dbms_lob.substr(l_xml_clob);
  xml_helper.remove_comments(l_xml);
  assert(
    l_expected = l_xml,
    'expected="' || l_expected || '" result="' || l_xml || '"');
    
  
  l_xml := '<b><!--B-></b>';
  BEGIN
    xml_helper.remove_comments(l_xml);
    RAISE_APPLICATION_ERROR(-20000, 'should have failed. un-closed');
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;-- un-closed comment
  END;
  
  dbms_lob.createtemporary(l_xml_clob, true);
  dbms_lob.write(l_xml_clob, length(l_xml), 1, l_xml);
  BEGIN
    xml_helper.remove_comments(l_xml_clob);
    RAISE_APPLICATION_ERROR(-20000, 'should have failed. un-closed');
  EXCEPTION
    WHEN OTHERS
    THEN
      NULL;-- un-closed comment
  END;
  
  
  -- test un-escape entities
  
  l_xml_element := xml_helper.new_xml_element('a');
  l_xml_element2 := xml_helper.new_xml_element('a');
  
  l_xml_element.content := '&quot;&amp;&apos;&lt;&gt;&quot;&amp;&apos;&lt;&gt;';
  l_xml_element2.content := '"&''<>"&''<>';
  
  xml_helper.un_escape_entities(l_xml_element);
  
  assert_equal(l_xml_element2, l_xml_element);
  
END;
/

SET DEFINE ON
