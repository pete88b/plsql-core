/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package com.butterfill.plsqlcore.maven;

import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;

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
        instance.setBaseDirName("C:/TMP/temp/");
        instance.execute();
    }

}
