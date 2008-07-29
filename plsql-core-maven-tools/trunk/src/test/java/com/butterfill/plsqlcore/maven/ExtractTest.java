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
        temp += File.separator;
        temp += "ExtractTest";
        System.out.println("setting output dir to " + temp);
        instance.setOutputDirectory(temp);
        instance.setIncludesFile(new File("target/test-classes/plsq-core-includes-test.xml"));
        instance.execute();
        instance.setIncludesFile(new File("target/test-classes/plsq-core-includes-test-empty.xml"));
        instance.execute();
        instance.setIncludesFile(null);
        try {
            instance.execute();
            fail();
        } catch (MojoExecutionException ex) {
        }
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
    public void testGetIncludesFile() throws Exception  {
        System.out.println("getIncludesFile");
        Extract instance = new Extract();
        File expResult = null;
        File result = instance.getIncludesFile();
        assertEquals(expResult, result);
    }

    /**
     * Test of setIncludesFile method, of class Extract.
     */
    public void testSetIncludesFile() throws Exception  {
        System.out.println("setIncludesFile");
        File file = null;
        Extract instance = new Extract();
        instance.setIncludesFile(file);
    }

    /**
     * Test of getOutputDirectory method, of class Extract.
     */
    public void testGetOutputDirectory() throws Exception {
        System.out.println("getOutputDirectory");
        Extract instance = new Extract();
        assertEquals("", instance.getOutputDirectory());
        
    }

    /**
     * Test of setOutputDirectory method, of class Extract.
     */
    public void testSetOutputDirectory() throws Exception {
        System.out.println("setOutputDirectory");
        Extract instance = new Extract();
        
        instance.setOutputDirectory(null);
        assertEquals("", instance.getOutputDirectory());
        
        instance.setOutputDirectory("");
        assertEquals("", instance.getOutputDirectory());
        
        instance.setOutputDirectory("a");
        assertEquals("a" + File.separator, instance.getOutputDirectory());
        
        instance.setOutputDirectory("a/");
        assertEquals("a/", instance.getOutputDirectory());
        
        instance.setOutputDirectory("a" + File.separator);
        assertEquals("a" + File.separator, instance.getOutputDirectory());
    }


}
