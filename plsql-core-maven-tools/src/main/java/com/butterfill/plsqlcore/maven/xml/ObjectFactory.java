//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.0.2-b01-fcs 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2008.12.14 at 08:15:31 PM GMT 
//


package com.butterfill.plsqlcore.maven.xml;

import javax.xml.bind.annotation.XmlRegistry;


/**
 * This object contains factory methods for each 
 * Java content interface and Java element interface 
 * generated in the com.butterfill.plsqlcore.maven.xml package. 
 * <p>An ObjectFactory allows you to programatically 
 * construct new instances of the Java representation 
 * for XML content. The Java representation of XML 
 * content can consist of schema derived interfaces 
 * and classes representing the binding of schema 
 * type definitions, element declarations and model 
 * groups.  Factory methods for each of these are 
 * provided in this class.
 * 
 */
@XmlRegistry
public class ObjectFactory {


    /**
     * Create a new ObjectFactory that can be used to create new instances of schema derived classes for package: com.butterfill.plsqlcore.maven.xml
     * 
     */
    public ObjectFactory() {
    }

    /**
     * Create an instance of {@link PlsqlCoreIncludes }
     * 
     */
    public PlsqlCoreIncludes createPlsqlCoreIncludes() {
        return new PlsqlCoreIncludes();
    }

    /**
     * Create an instance of {@link PlsqlCoreModule.Dependencies.Dependency }
     * 
     */
    public PlsqlCoreModule.Dependencies.Dependency createPlsqlCoreModuleDependenciesDependency() {
        return new PlsqlCoreModule.Dependencies.Dependency();
    }

    /**
     * Create an instance of {@link PlsqlCoreModule.Dependencies }
     * 
     */
    public PlsqlCoreModule.Dependencies createPlsqlCoreModuleDependencies() {
        return new PlsqlCoreModule.Dependencies();
    }

    /**
     * Create an instance of {@link PlsqlCoreModule }
     * 
     */
    public PlsqlCoreModule createPlsqlCoreModule() {
        return new PlsqlCoreModule();
    }

    /**
     * Create an instance of {@link PlsqlCoreModule.FileSet }
     * 
     */
    public PlsqlCoreModule.FileSet createPlsqlCoreModuleFileSet() {
        return new PlsqlCoreModule.FileSet();
    }

}
