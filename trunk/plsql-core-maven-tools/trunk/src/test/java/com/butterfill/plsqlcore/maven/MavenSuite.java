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
public class MavenSuite extends TestCase {
    
    public MavenSuite(String testName) {
        super(testName);
    }            

    public static Test suite() {
        TestSuite suite = new TestSuite("MavenSuite");
        suite.addTest(new TestSuite(com.butterfill.plsqlcore.maven.ExtractTest.class));
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

}
