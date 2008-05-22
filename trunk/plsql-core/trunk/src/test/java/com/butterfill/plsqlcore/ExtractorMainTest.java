/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
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
        instance.setOutputDirectoryName("target/");
    }

    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
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

    public void testX() throws Exception {
        System.out.println(
                this.getClass().
                getProtectionDomain().
                getCodeSource().
                getLocation().
                toString().
                substring("file:/".length()));
    }
    
}
