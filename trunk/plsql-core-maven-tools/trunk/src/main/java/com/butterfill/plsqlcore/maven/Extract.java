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

package com.butterfill.plsqlcore.maven;

import com.butterfill.plsqlcore.maven.xml.PlsqlCoreIncludes;
import com.butterfill.plsqlcore.maven.xml.PlsqlCoreModule;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.Unmarshaller;
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
     * setOutputDirectory(String) will not set this to null.
     * 
     * @parameter expression="${outputDirectory}"
     */
    private String outputDirectory = "";
    
    /**
     * The JAXB un-marshaller - used when reading xml input.
     */
    private final Unmarshaller jaxbUnmarshaller;
    
    
    /** 
     * Creates a new instance of Extract setting-up the JAXB un-marshaller 
     * used by this instance.
     * 
     * @throws Exception
     *   If we fail to set-up the JAXB un-marshaller used by this instance.
     */
    public Extract() throws Exception {
        jaxbUnmarshaller = JAXBContext.newInstance(
                PlsqlCoreIncludes.class, PlsqlCoreModule.class)
                .createUnmarshaller();
        
    }

    /**
     * Creates a directory with the specified name.
     * <br/>
     * There are 4 possible scenarios:
     * <ul>
     * <li>The directory exists. This is ok. No action needed,</li>
     * <li>Something that is not a directory exists with the specified name. This is an error,</li>
     * <li>The directory exists and we can create it or</li>
     * <li>The directory exists but we can't create it. This is an error.</li>
     * </ul>
     * 
     * @param name 
     *   The name of the directory to create.
     * @throws java.lang.Exception
     *   If something that is not a directory exists with the specified name
     *   or we fail to create the directory.
     */
    private void mkDir(final String name) throws Exception {
        final File dir = new File(outputDirectory + name);
        
        if (dir.exists()) {
            if (dir.isDirectory()) {
                getLog().info("directory exists: " + dir.getCanonicalPath());

            } else {
                throw new MojoExecutionException(
                        dir.getCanonicalPath() + " is not a directory");
                
            }

        } else {
            if (dir.mkdirs()) {
                getLog().info("directory created: " + dir.getCanonicalPath());

            } else {
                throw new MojoExecutionException(
                        "failed to create directory: " + dir.getCanonicalPath());

            }
            
        }
        
    }
    
    /**
     * Returns the specified location in a standard format.
     * Leading and trailing white-space will be removed and a forward slash is
     * appended if the specified location does not already end with a forward 
     * slash.
     * 
     * @param location
     *   The location to format.
     * @return
     *   The specified location in a standard format.
     */
    private String formatLocation(String location) {
        location = location.trim();
        if (!location.endsWith("/")) {
            location += "/";
        }
        return location;
    }
    
    /**
     * Returns the module name taken from the specified module location.
     * Module locations always end with the module name.
     * <br/>
     * e.g.
     * constants is the module name for the location
     * http://plsql-core.googlecode.com/svn/trunk/plsql-core/trunk/src/main/resources/plsql/constants/
     * @param moduleLocation
     *   The module location.
     * @return
     *   The name of the module taken from the specified module location.
     */
    private String getModuleName(String moduleLocation) {
        String[] bits = moduleLocation.split("/");
        return bits[bits.length - 1];
    }
    
    /**
     * Adds the PlsqlCoreModule identified by moduleLocation 
     * (and all of it's dependencies) to moduleMap.
     * If moduleMap already has an entry keyed by moduleLocation, this is a no-op.
     * 
     * @param moduleLocation
     *   The location of the module to add.
     * @param moduleMap
     *   The map to which the module should be added.
     * @throws java.lang.Exception
     *   If we fail to add the module. 
     *   This could be because we can't read the plsql-core-module.xml file 
     *   (which should be in the specified location).
     */
    private void addModule(final String moduleLocation, 
            final Map<String, PlsqlCoreModule> moduleMap) 
            throws Exception {
        
        getLog().debug("addModule() moduleLocation: " + moduleLocation);
        
        if (moduleMap.containsKey(moduleLocation)) {
            getLog().debug(
                    "not adding duplicate module location: " + moduleLocation);
            return;
        }
        
        URL baseUrl = new URL(moduleLocation);
        
        URLConnection urlConnection = 
                new URL(baseUrl, "plsql-core-module.xml").openConnection();
        
        urlConnection.setUseCaches(false);

        PlsqlCoreModule plsqlCoreModule = (PlsqlCoreModule)
                jaxbUnmarshaller.unmarshal(urlConnection.getInputStream());
        
        moduleMap.put(moduleLocation, plsqlCoreModule);
        
        if (plsqlCoreModule.getDependencies() == null) {
            getLog().debug("module has no dependencies");
            return;
        }
        
        List<PlsqlCoreModule.Dependencies.Dependency> dependencies =
                plsqlCoreModule.getDependencies().getDependency();
        
        for (PlsqlCoreModule.Dependencies.Dependency dependency : dependencies) {
            String dependencyLocation = formatLocation(dependency.getLocation());
            if (!moduleMap.containsKey(dependencyLocation)) {
                addModule(dependencyLocation, moduleMap);
                
            }
            
        }
        
    }
    
    /**
     * Calls ExtractorMain#extract having set the output directory name, 
     * passing in the includes file if it has been provided.
     * 
     * @see #setIncludesFile(java.io.File)
     * @see #setOutputDirectory(java.io.File) 
     * @throws org.apache.maven.plugin.MojoExecutionException
     *   If the extract fails.
     * @throws org.apache.maven.plugin.MojoFailureException
     *   If the extract fails.
     */
    public void execute() throws MojoExecutionException, MojoFailureException {
        try {
            // set-up a map to hold all modules that we'll extract.
            // each module will be keyed by it's location - so we can avoid adding duplicates
            Map<String, PlsqlCoreModule> moduleMap = new HashMap<String, PlsqlCoreModule>();
            
            // read the includes file via JAXB
            PlsqlCoreIncludes plsqlCoreIncludes = (PlsqlCoreIncludes) 
                    jaxbUnmarshaller.unmarshal(includesFile);
            
            // add each location to be included to the module map.
            // add module should take care of adding depencies
            for (String location : plsqlCoreIncludes.getPlsqlCoreModuleLocation()) {
                addModule(formatLocation(location), moduleMap);
                
            }
            
            // extract each module in the module map
            for (Map.Entry<String, PlsqlCoreModule> entry : moduleMap.entrySet()) {
                // get the location from the PlsqlCoreModule
                String location = formatLocation(entry.getValue().getLocation());
                
                // make sure the location from the PlsqlCoreModule matches the
                // loaction given in the includes file
                if (!entry.getKey().equals(location)) {
                    throw new MojoExecutionException(
                            "[Location Mismatch] " + 
                            includesFile.getName() + ":\"" + entry.getKey() + 
                            " \"plsql-core-module.xml:\"" + location + "\"");
                }
                
                // get the name of the module
                String moduleName = getModuleName(location);
                
                // setup output dir for this module
                mkDir(moduleName);
                
                // extract each file listed in the modules file set
                for (String fileName : entry.getValue().getFileSet().getFile()) {
                    getLog().info("Extracting: " + location + fileName);
                    
                    URL baseUrl = new URL(location);
                    
                    URLConnection urlConnection = new URL(baseUrl, fileName).openConnection();
                    
                    urlConnection.setUseCaches(false);
                    
                    BufferedReader reader = new BufferedReader(new InputStreamReader(
                            urlConnection.getInputStream()));
                    
                    BufferedWriter writer = new BufferedWriter(new FileWriter(
                            outputDirectory + 
                            File.separator + moduleName + 
                            File.separator + fileName));
                    
                    for (String line = reader.readLine(); line != null; line = reader.readLine()) {
                        writer.write(line);
                        writer.newLine();
                        
                    }
                    
                    writer.close();
                    reader.close();
                    
                }
                
            }
            
        } catch (Exception ex) {
            // log a warning if the extract failed
            getLog().warn("extract failed", ex);
            // log the output dir
            getLog().info("outputDirectory: " + outputDirectory);
            // the name of the includes file
            try {
                getLog().info("includesFile: " + includesFile.getCanonicalPath());
            } catch (Exception nonCriticalException) {
                getLog().debug("failed to log name of includes file", nonCriticalException);
            }
            // and throw an exception so that the user knows something went wrong
            throw new MojoExecutionException("extract failed", ex);
            
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
    public String getOutputDirectory() {
        return outputDirectory;
    }

    /**
     * Sets the output directory name to use when extracting.
     * 
     * @param name
     *   The output directory name to use when extracting.
     */
    public void setOutputDirectory(final String name) {
        this.outputDirectory = (name == null) ? "" : name;
        
        if (this.outputDirectory.length() > 0 && 
                !this.outputDirectory.endsWith(File.separator) &&
                !this.outputDirectory.endsWith("/")) {
            this.outputDirectory += File.separator;
            
        }
        
    }

} // End of class Extract