<xsl:stylesheet version="1.0"
            xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
            xmlns:msxsl="urn:schemas-microsoft-com:xslt"
            exclude-result-prefixes="msxsl"
            xmlns:wix="http://schemas.microsoft.com/wix/2006/wi"
            xmlns:my="my:my">

	<!-- set output options -->
    <xsl:output method="xml" indent="yes" />

    <xsl:strip-space elements="*"/>

	<!-- copy all to output -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
  
    <!--Exclude *.xml-->
    <xsl:key name="xml-search" match="wix:Component[(contains(wix:File/@Source, '.xml') or contains(wix:File/@Source, '.XML')) and not(contains(wix:File/@Source, '_DynamoCustomization.xml') or contains(wix:File/@Source, '.Migrations.xml'))]" use="@Id"/>
    <xsl:template match="wix:Component[key('xml-search', @Id)]" />
  
    <!--Exclude *.pdb-->
    <xsl:key name="pdb-search" match="wix:Component[contains(wix:File/@Source, '.pdb')]" use="@Id"/>
    <xsl:template match="wix:Component[key('pdb-search', @Id)]" />

    <!--Exclude Test*.dll/exe-->
    <xsl:key name="testdll-search" match="wix:Component[contains(wix:File/@Source, 'Test') and (contains(wix:File/@Source, '.dll') or contains(wix:File/@Source, '.exe') or contains(wix:File/@Source, '.xml'))]" use="@Id"/>
    <xsl:template match="wix:Component[key('testdll-search', @Id)]" />

    <!--Exclude 'int' folders-->
    <xsl:template match="wix:Directory[@Name = 'int']" />
    <xsl:key name="int-search" match="wix:Component[contains(wix:File/@Source, '\int\')]" use="@Id"/>
    <xsl:template match="wix:Component[key('int-search', @Id)]" />

</xsl:stylesheet>