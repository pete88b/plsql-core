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

package com.butterfill.plsqlcore;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

/**
 *
 * @author Butterp
 */
public class ExtractorMainTest extends TestCase {
    
    private ExtractorMain instance;
    
    public ExtractorMainTest(String testName) {
        super(testName);
    }

    public static Test suite() {
        TestSuite suite = new TestSuite(ExtractorMainTest.class);
        return suite;
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        instance = new ExtractorMain();
        instance.setOutputDirectoryName("target");
    }

    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
    }

    public void testConstrucors() throws Exception {
        try {
            new ExtractorMain(null);
            fail();
        } catch (NullPointerException ex) {
        }
        new ExtractorMain(String.class);
    }
            
    
    /**
     * Test of extract method, of class ExtractorMain.
     */
    public void testExtract_0args() throws Exception {
        System.out.println("extract");
        
        try {
            instance.extract();
            fail();
        } catch (FileNotFoundException ex) {
        }
        
    }

    /**
     * Test of extract method, of class ExtractorMain.
     */
    public void testExtract_List() throws Exception {
        System.out.println("extract");
        
        try {
            instance.extract(new ArrayList<String>());
            fail();
        } catch (FileNotFoundException ex) {
        }
        
    }

    /**
     * Test of extract method, of class ExtractorMain.
     */
    public void testExtract_StringArr() throws Exception {
        System.out.println("extract");
        String[] include = null;
        
        try {
            instance.extract(include);
            fail();
        } catch (NullPointerException ex) {
            
        }
        
        include = new String[]{};
        try {
            instance.extract(include);
            fail();
        } catch (FileNotFoundException ex) {
        }
        
    }

    /**
     * Test of extract method, of class ExtractorMain.
     */
    public void testExtract_File() throws Exception {
        System.out.println("extract");
        File includeFile = null;
        
        try {
            instance.extract(includeFile);
            fail();
        } catch (NullPointerException ex) {
            
        }
        
        includeFile = new File("target/test-classes/com/butterfill/plsqlcore/test-include-file.txt");
        try {
            instance.extract(includeFile);
            fail();
        } catch (FileNotFoundException ex) {
        }
        
    }

    /**
     * Test of main method, of class ExtractorMain.
     */
    public void testMain() throws Exception {
        System.out.println("main");
        
        System.setProperty("plsql-core.baseDir", "target/");
        
        String[] args = null;
        try {
            ExtractorMain.main(args);
            fail();
        } catch (FileNotFoundException ex) {
        }
        
        System.setProperty("plsql-core.baseDir", "target");
        args = new String[]{};
        try {
            ExtractorMain.main(args);
            fail();
        } catch (FileNotFoundException ex) {
        }
        
    }

    /**
     * Test of getOutputDirectoryName method, of class ExtractorMain.
     */
    public void testGetOutputDirectoryName() {
        System.out.println("getOutputDirectoryName");
        assertEquals("", new ExtractorMain().getOutputDirectoryName());
    }

    /**
     * Test of setOutputDirectoryName method, of class ExtractorMain.
     */
    public void testSetOutputDirectoryName() {
        System.out.println("setOutputDirectoryName");
        assertEquals("target"+File.separator, instance.getOutputDirectoryName());
        instance.setOutputDirectoryName(null);
        assertEquals("", instance.getOutputDirectoryName());
        instance.setOutputDirectoryName("x");
        assertEquals("x"+File.separator, instance.getOutputDirectoryName());
        instance.setOutputDirectoryName("x"+File.separator);
        assertEquals("x"+File.separator, instance.getOutputDirectoryName());
        
    }
    
    
}
