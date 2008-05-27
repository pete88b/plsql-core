package com.butterfill.plsqlcore;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Provides methods to extract the contents of this project (jar).
 * <br/>
 * This class can also be used to extract the contents of similarly structured projects.
 * 
 * @author peter
 */
public class ExtractorMain {

    /**
     * Any class that exists in the jar file that we will extract from.
     */
    private final Class classFromJar;
    
    /**
     * The location in which files will be created.
     */
    private String outputDirectoryName = "";

    /**
     * The size of buffer to use when doing buffered IO (reading zip entries in this case).
     */
    private static final int IO_BUFFER_SIZE = 1024;
    
    /**
     * Creates a new instance of ExtractorMain to extract the contents of this project.
     */
    public ExtractorMain() {
        this.classFromJar = ExtractorMain.class;
    }
    
    /**
     * Creates a new instance of ExtractorMain to extract the contents of the project
     * which contains the specified class.
     * 
     * @param classFromJar 
     *   Any class that exists in the jar file that we will extract from.
     * @throws NullPointerException
     *   If classFromJar is null.
     */
    public ExtractorMain(final Class classFromJar) throws NullPointerException {
        if (classFromJar == null) {
            throw new NullPointerException("classFromJar should not be null");
        }
        this.classFromJar = classFromJar;
    }
    
    /**
     * Returns the location into which files will be extracted.
     * @return The name of the directory to which SQL should be written.
     */
    public String getOutputDirectoryName() {
        return outputDirectoryName;
    }

    /**
     * Sets the name of the directory to which SQL should be written.
     * If the specified name does not end with a name separator, one will be appended.
     * 
     * @param name
     *   Name of the output directory. 
     *   Can be absolute or relative.
     *   Optionally include a trailing name separator.
     */
    public void setOutputDirectoryName(final String name) {
        this.outputDirectoryName = (name == null) ? "" : name;
        if (this.outputDirectoryName.length() > 0 && 
                !this.outputDirectoryName.endsWith(File.separator)) {
            this.outputDirectoryName += File.separator;
        }
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
     *   If something that is not a directory exists with the specified name or we fail to 
     *   create the directory.
     */
    private void mkDir(final String name) throws Exception {
        File dir = new File(outputDirectoryName + name);
        
        if (dir.exists()) {
            if (dir.isDirectory()) {
                System.out.println("directory exists: " + dir.getCanonicalPath());

            } else {
                throw new RuntimeException(
                        dir.getCanonicalPath() + " is not a directory");
                
            }

        } else {
            if (dir.mkdirs()) {
                System.out.println("directory created: " + dir.getCanonicalPath());

            } else {
                throw new RuntimeException(
                        "failed to create directory: " + dir.getCanonicalPath());

            }
            
        }
        
    }
    
    /**
     * Creates a file for the specified zip entry.
     * 
     * @param jar
     *   The jar (as an input stream) to read the entry from.
     * @param entry
     *   The zip entry.
     * @throws java.lang.Exception
     *   If we fail to create a file for the specified zip entry.
     */
    private void mkFile(final ZipInputStream jar, final ZipEntry entry) throws Exception {
        System.out.println("extracting: " + entry.getName());

        BufferedOutputStream out = new BufferedOutputStream(
                new FileOutputStream(
                outputDirectoryName + "plsql-core" + File.separator + entry.getName()));

        byte[] data = new byte[IO_BUFFER_SIZE];

        for (int i = jar.read(data, 0, data.length); i != -1; i = jar.read(data, 0, data.length)) {
            out.write(data, 0, i);
        }

        out.flush();
        out.close();

    }
    
    /**
     * Extracts the contents of this jar using the specified zip entry filter.
     * 
     * @param filter
     *   Only entries that are included by this filter will be extracted.
     * @throws java.lang.Exception
     *   If the extract fails.
     */
    private void extract(final ZipEntryFilter filter) throws Exception {
        mkDir("plsql-core");

        // get the URI for the jar that classFromJar is in
        URI jarUri = classFromJar.getProtectionDomain().
                    getCodeSource().
                    getLocation().
                    toURI();
        
        ZipInputStream jar = new ZipInputStream(
                new BufferedInputStream(
                new FileInputStream(
                new File(jarUri))));
        
        for (ZipEntry entry = jar.getNextEntry(); entry != null; entry = jar.getNextEntry()) {
            if (!filter.include(entry)) {
                continue;
            }
            
            if (entry.isDirectory()) {
                mkDir("plsql-core" + File.separator + entry.getName());

            } else {
                mkFile(jar, entry);

            }
            
        }
        
        jar.close();
        
    }

    /**
     * Extracts all SQL from this jar.
     * 
     * @throws java.lang.Exception
     *   If the extract fails.
     */
    public void extract() throws Exception {
        extract(new ZipEntryFilter() {
            public boolean include(final ZipEntry entry) {
                return entry.getName().startsWith("plsql");
            }
        });
    }
    
    /**
     * Extracts all SQL from this jar if the SQL project name can be found in the specified list.
     * 
     * @param includes
     *   A list of SQL project names to extract.
     * @throws java.lang.Exception
     *   If the extract fails.
     */
    public void extract(final List<String> includes) throws Exception {
        extract(new ZipEntryFilter() {
            public boolean include(final ZipEntry entry) {
                String name = entry.getName();
                if (!name.startsWith("plsql")) {
                    return false;
                }
                // 6 = "plsql/".length()
                int secondForwardSlash = name.indexOf("/", 6);
                if (secondForwardSlash < 0) {
                    return false;
                }
                return includes.contains(
                        name.substring(6, name.indexOf("/", 6)));
            }
        });
    }
    
    /**
     * Extracts all SQL from this jar if the SQL project name can be found in the specified array.
     * 
     * @param includes
     *   A list of SQL project names to extract.
     * @throws java.lang.Exception
     *   If the extract fails.
     */
    public void extract(final String[] includes) throws Exception {
        extract(Arrays.asList(includes));
    }
    
    /**
     * Extracts all SQL from this jar if the SQL project name can be found in the specified file.
     * The file can contain any number of lines with one SQL project name on each line.
     * 
     * @param includes
     *   A file containing a list of SQL project names to extract.
     * @throws java.lang.Exception
     *   If the extract fails.
     */
    public void extract(final File includes) throws Exception {
        List<String> includeList = new ArrayList<String>();
        BufferedReader reader = new BufferedReader(new FileReader(includes));
        for (String line = reader.readLine(); line != null; line = reader.readLine()) {
            includeList.add(line);
        }
        reader.close();
        extract(includeList);
    }
    
    /**
     * Extracts SQL from this jar to the location specified by the system property 
     * plsql-core.baseDir. A null value for this property means the working directory.
     * <br/>
     * If command line arguments are specified, we call extract(String[]).
     * i.e. We use includes specified on the command line.
     * <br/>
     * Otherwise, if plsql-core-include.txt can be found in the current directory, 
     * we call extract(File).
     * i.e. We use includes specified in plsql-core-include.txt.
     * <br/>
     * Otherwise, we call extract().
     * i.e. We do not use includes and everything is extracted.
     * 
     * @param args 
     *   A space separated set of SQL project names (optional).
     * @throws java.lang.Exception
     *   If the extract fails.
     */
    public static void main(final String[] args) throws Exception {
        
        if (System.getProperty("plsql-core.gui") != null) {
            throw new RuntimeException("can't do GUI yet");
        }
        
        ExtractorMain app = new ExtractorMain();
        
        if (System.getProperty("plsql-core.baseDir") != null) {
            app.setOutputDirectoryName(System.getProperty("plsql-core.baseDir"));
        }
        
        if (args != null && args.length != 0) {
            System.out.println("using includes specified on command line");
            app.extract(args);
            
        } else {
            File includeFile = new File("plsql-core-include.txt");
            if (includeFile.isFile()) {
                System.out.println("using includes from " + includeFile.getCanonicalPath());
                app.extract(includeFile);
                
            } else {
                System.out.println("include all");
                app.extract();
                
            }
            
        }
        
    }

    /**
     * Specifies behaviour of classes that can filter zip entries.
     */
    private static interface ZipEntryFilter {
        
        /**
         * Return true if the specified zip entry should be included, false otherwise.
         * 
         * @param entry
         *   A zip entry that may or may not be included.
         * @return
         *   true if the specified zip entry should be included.
         */
        boolean include(ZipEntry entry);
        
    } // End of interface ZipEntryFilter
    
} // End of class ExtractorMain
