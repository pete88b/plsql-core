/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.butterfill.plsqlcore.maven;

import java.io.File;
import java.net.URL;
import java.net.URLConnection;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.apache.maven.plugin.MojoExecutionException;

/**
 *
 * @author Butterp
 */
public class ExtractTest extends TestCase {
    
    private boolean networkOk;
    
    final String EXTRACT_DIR_NAME = 
            System.getProperty("java.io.tmpdir") +
            File.separator + "ExtractTest";
    
    private void deleteDirectory(File dir) {
        if (!dir.isDirectory()) {
            return;
        }
        
        File[] files = dir.listFiles();
        if (files != null) {
            for (File file : files) {
                if (file.isDirectory()) {
                    deleteDirectory(file);

                } else {
                    if (!file.delete()) {
                        throw new RuntimeException("failed to delete: " + file.getAbsolutePath());
                    }

                }

            }
            
        } // End of if (files != null)
        
        if (!dir.delete()) {
            throw new RuntimeException("failed to delete: " + dir.getAbsolutePath());
            
        } else {
            System.out.println("Deleted: " + dir.getAbsolutePath());
            
        }
        
    }

    
    public ExtractTest(String testName) {
        super(testName);
        
        try {
            URLConnection urlConnection = new URL("http://www.sun.com").openConnection();
            urlConnection.setUseCaches(false);
            urlConnection.getInputStream();
            networkOk = true;
            
        } catch (Exception ex) {
            networkOk = false;

        }
        
        deleteDirectory(new File(EXTRACT_DIR_NAME));
        
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
        
        System.out.println("setting output dir to " + EXTRACT_DIR_NAME);
        instance.setOutputDirectory(EXTRACT_DIR_NAME);
        instance.setIncludesFile(new File("target/test-classes/plsq-core-includes-test.xml"));
        instance.execute();
        instance.setIncludesFile(new File("target/test-classes/plsq-core-includes-test-empty.xml"));
        instance.execute();
        instance.setIncludesFile(null);
        try {
            instance.execute();
            if (networkOk) {
                fail();
            }
        } catch (MojoExecutionException ex) {
            if (!networkOk) {
                fail();
            }
        }
        instance.setIncludesFile(new File("does-not-exist"));
        try {
            instance.execute();
            if (networkOk) {
                fail();
            }
        } catch (MojoExecutionException ex) {
            if (!networkOk) {
                fail();
            }
        }
        
        instance.setExecute(false);
        instance.execute();
        
        instance.setExecute(true);
        instance.setIncludesFile(new File("target/test-classes/plsq-core-includes-test.xml"));
        instance.setExecuteIfNoNetwork(true);
        try {
            instance.execute();
            if (!networkOk) {
                fail();
            }
        } catch (MojoExecutionException ex) {
            if (networkOk) {
                fail();
            }
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

    public void testIsExecute() throws Exception {
        System.out.println("isExecute()");
        assertTrue(new Extract().isExecute());
    }
    
    public void testIsExecuteIfNoNetwork() throws Exception {
        System.out.println("isExecuteIfNoNetwork()");
        assertFalse(new Extract().isExecuteIfNoNetwork());
    }
    
}
