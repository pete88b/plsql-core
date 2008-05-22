
package com.butterfill.plsqlcore.maven;

import com.butterfill.plsqlcore.ExtractorMain;
import java.io.File;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.project.MavenProject;

/**
 *
 * @goal Extract
 */
public class Extract extends AbstractMojo {
    
    /**
     * This populates the maven project.
     * 
     * @parameter expression="${project}"
     */
    private MavenProject project;
    
    /**
     * 
     * @parameter expression="${includesFile}"
     */
    private File includesFile;
    
    /**
     * 
     * @parameter expression="${outputDirectoryName}"
     */
    private String outputDirectoryName;
    
    /** 
     * Creates a new instance of Extract.
     */
    public Extract() {
    }

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

    public MavenProject getProject() {
        return project;
    }

    public void setProject(MavenProject project) {
        this.project = project;
    }

    public File getIncludesFile() {
        return includesFile;
    }

    public void setIncludesFile(File includesFile) {
        this.includesFile = includesFile;
    }

    public String getBaseDirName() {
        return outputDirectoryName;
    }

    public void setBaseDirName(String baseDirName) {
        this.outputDirectoryName = baseDirName;
    }

} // End of class Extract