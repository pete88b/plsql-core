/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.butterfill.plsqlcore.maven;

import java.io.File;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.apache.maven.plugin.MojoExecutionException;

/**
 *
 * @author Butterp
 */
public class ExtractTest extends TestCase {
    
    public ExtractTest(String testName) {
        super(testName);
    }

    public static Test suite() {
        TestSuite suite = new TestSuite(ExtractTest.class);
        return suite;
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();
    }

    @Override
    protected void tearDown() throws Exception {
        super.tearDown();
    }

    /**
     * Test of execute method, of class Extract.
     */
    public void testExecute() throws Exception {
        System.out.println("execute");
        Extract instance = new Extract();
        String temp = System.getProperty("java.io.tmpdir");
        System.out.println("setting output dir to " + temp);
        instance.setOutputDirectoryName(temp);
        instance.setIncludesFile(new File("target/test-classes/plsq-core-includes-test.txt"));
        instance.execute();
        instance.setIncludesFile(null);
        instance.execute();
        instance.setIncludesFile(new File("does-not-exist"));
        try {
            instance.execute();
            fail();
        } catch (MojoExecutionException ex) {
        }
        
    }

    /**
     * Test of getIncludesFile method, of class Extract.
     */
    public void testGetIncludesFile() {
        System.out.println("getIncludesFile");
        Extract instance = new Extract();
        File expResult = null;
        File result = instance.getIncludesFile();
        assertEquals(expResult, result);
    }

    /**
     * Test of setIncludesFile method, of class Extract.
     */
    public void testSetIncludesFile() {
        System.out.println("setIncludesFile");
        File file = null;
        Extract instance = new Extract();
        instance.setIncludesFile(file);
    }

    /**
     * Test of getOutputDirectoryName method, of class Extract.
     */
    public void testGetOutputDirectoryName() {
        System.out.println("getOutputDirectoryName");
        Extract instance = new Extract();
        String expResult = null;
        String result = instance.getOutputDirectoryName();
        assertEquals(expResult, result);
    }

    /**
     * Test of setOutputDirectoryName method, of class Extract.
     */
    public void testSetOutputDirectoryName() {
        System.out.println("setOutputDirectoryName");
        String name = "";
        Extract instance = new Extract();
        instance.setOutputDirectoryName(name);
    }

}
