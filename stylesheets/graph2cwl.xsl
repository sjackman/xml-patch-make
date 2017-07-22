<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:x="http://exslt.org/dates-and-times"
	version="1.0"
	>
<!-- convert a xml-make to CWL https://github.com/common-workflow-language -->
<xsl:output method="text"/>
<xsl:param name="shellpath">~/src/xml-patch-make/tmp/graph2cwl.bash</xsl:param>
<xsl:key name="tt" match="target" use="@id" />

<!-- pour memoire  : /home/lindenb/.local/bin/cwl-runner -->

<xsl:template match="/">
<xsl:apply-templates select="make"/>
</xsl:template>

<xsl:template match="make">
<xsl:variable name="top" select="target[position() = last()]"/>


<xsl:text>#!/usr/bin/env cwl-runner
cwlVersion: v1.0
$graph:
</xsl:text>


<xsl:apply-templates select="target" mode="tool"/>


- id: main
  class: Workflow
  inputs: []
  outputs:
    outfile:
      type: File
      outputSource: step<xsl:value-of select="$top/@id"/>/output
  steps:
<xsl:for-each select="target">
    <xsl:sort select="position()" data-type="number"/>
        <xsl:apply-templates select="." mode="step"/>
</xsl:for-each>

<xsl:text>
</xsl:text>
<xsl:apply-templates select="." mode="shell"/> 
</xsl:template>   

<!--==== TOOL ===================================================== -->
<xsl:template match="target" mode="tool">
<xsl:variable name="this" select="."/>

- id: tool<xsl:value-of select="@id"/>
  class: CommandLineTool
  label: "<xsl:value-of select="@name"/>"
  doc: "<xsl:value-of select="@description"/>"
  inputs:
    <xsl:value-of select="@id"/>_target:
      label: "<xsl:value-of select="@name"/>"
      doc: "<xsl:value-of select="@description"/>"
      type: string<xsl:for-each select="prerequisites/prerequisite">
    <xsl:value-of select="$this/@id"/>_dep<xsl:value-of select="@ref"/>
      label: "<xsl:value-of select="@name"/>"
      type: File</xsl:for-each>
  outputs:
    output:
      type: File
      outputBinding:
          glob: "ok<xsl:value-of select="@id"/>.txt"
  baseCommand: "<xsl:value-of select="$shellpath"/>"
  arguments:
     - "<xsl:value-of select="@id"/>"

</xsl:template>


<!--==== TARGET STEP ===================================================== -->
<xsl:template match="target" mode="step">
<xsl:variable name="this" select="."/>
    step<xsl:value-of select="@id"/>:
      in:
        <xsl:value-of select="$this/@id"/>_target:
          default: <xsl:apply-templates select="." mode="flag"/>
      <xsl:for-each select="prerequisites/prerequisite"><xsl:text>&#xa;</xsl:text>
      <xsl:text>        </xsl:text><xsl:value-of select="$this/@id"/>_dep<xsl:value-of select="@ref"/>:
          source: step<xsl:value-of select="@ref"/>/output</xsl:for-each>
      out: [ output ]
      run: "#tool<xsl:value-of select="@id"/>"
</xsl:template>

<!--==== MAKE SHELL ===================================================== -->
<xsl:template match="make" mode="shell">
<xsl:document href="{$shellpath}" method="text">#!/bin/bash
function die () {
    echo 1&gt;&amp;2 "ERROR: $0 : $@"
    exit 1
}
if [ "$#" -ne 1 ]; then
    die "Illegal number of parameters"
fi

oldpwd=${PWD}

<xsl:apply-templates select="target" mode="shell"/>


case "$1" in<xsl:for-each select="target"><xsl:text>
        </xsl:text><xsl:value-of select="@id"/>)
    run<xsl:value-of select="@id"/>
    ;;</xsl:for-each>
	*)
	die "Undefined target id=$1"
	;;
esac

</xsl:document>
</xsl:template>

<!--==== TARGET SHELL ===================================================== -->

<xsl:template match="target" mode="shell">


function run<xsl:value-of select="@id"/>() {<xsl:if test="/make/@pwd">
	cd '<xsl:value-of select="/make/@pwd"/>'
	</xsl:if>
	<xsl:for-each select="prerequisites/prerequisite"><xsl:if test="key('tt',@ref)/@phony = 0">
	if [ ! -f "<xsl:value-of select="@name"/>" ]; then
		die "File <xsl:value-of select="@name"/> missing"
	fi
	</xsl:if></xsl:for-each>
	
	<xsl:for-each select="statements/statement"><xsl:text>
		</xsl:text>
	<xsl:value-of select="text()"/>
	</xsl:for-each>
	
	##touch <xsl:if test="@phony = 0"> -c </xsl:if> <xsl:apply-templates select="." mode="phony-name"/>"
	cd "${oldpwd}"
	touch "ok<xsl:value-of select="@id"/>.txt"
	}

</xsl:template>

<!--==== TARGET SHELL ===================================================== -->

<xsl:template match="target" mode="phony-name">
<xsl:text>"</xsl:text>
<xsl:choose>
   <xsl:when test="@phony='1'"><xsl:value-of select="concat('__',@id,'_phony.flag')"/></xsl:when>
   <xsl:otherwise><xsl:value-of select="@name"/></xsl:otherwise>
</xsl:choose>
<xsl:text>"</xsl:text>
</xsl:template>


<xsl:template match="target" mode="flag">
<xsl:value-of select="concat('__',@id,'.ok.flag')"/>
</xsl:template>

 
</xsl:stylesheet>
