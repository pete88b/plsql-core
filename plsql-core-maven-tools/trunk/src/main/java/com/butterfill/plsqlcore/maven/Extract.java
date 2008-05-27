
package com.butterfill.plsqlcore.maven;

import com.butterfill.plsqlcore.ExtractorMain;
import java.io.File;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;

/**
 * Provides access to the extract functionality of plsql-core.
 * 
 * @goal Extract
 */
public class Extract extends AbstractMojo {
    
    /**
     * The plsql-core includes file which can be null.
     * 
     * @parameter expression="${includesFile}"
     */
    private File includesFile;
    
    /**
     * The name of the output directory.
     * 
     * @parameter expression="${outputDirectoryName}"
     */
    private String outputDirectoryName;
    
    /** 
     * Creates a new instance of Extract.
     */
    public Extract() {
    }

    /**
     * Calls ExtractorMain#extract having set the output directory name, 
     * passing in the includes file if it has been provided.
     * 
     * @see #setIncludesFile(java.io.File)
     * @see #setOutputDirectoryName(java.lang.String)
     * @throws org.apache.maven.plugin.MojoExecutionException
     *   If the extract fails.
     * @throws org.apache.maven.plugin.MojoFailureException
     *   If the extract fails.
     */
    public void execute() throws MojoExecutionException, MojoFailureException {
        ExtractorMain app = new ExtractorMain();
        
        app.setOutputDirectoryName(outputDirectoryName);
        
        try {
            if (includesFile == null) {
                app.extract();

            } else {
                app.extract(includesFile);

            }
            
        } catch (Exception ex) {
            throw new MojoExecutionException(ex.getMessage(), ex);
            
        }
        
    }

    /**
     * Returns the includes file to use when extracting.
     * 
     * @return The includes file to use when extracting.
     */
    public File getIncludesFile() {
        return includesFile;
    }

    /**
     * Sets the includes file to use when extracting.
     * 
     * @param file
     *   The includes file to use when extracting.
     */     
    public void setIncludesFile(final File file) {
        this.includesFile = file;
    }

    /**
     * Returns the output directory name to use when extracting.
     * 
     * @return The output directory name to use when extracting.
     */
    public String getOutputDirectoryName() {
        return outputDirectoryName;
    }

    /**
     * Sets the output directory name to use when extracting.
     * 
     * @param name
     *   The output directory name to use when extracting.
     */
    public void setOutputDirectoryName(final String name) {
        this.outputDirectoryName = name;
    }

} // End of class Extract