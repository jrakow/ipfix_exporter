<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">
  <xsl:output method="html" indent="yes" encoding="UTF-8" />

  <xsl:template match="/testsuites">
    <xsl:value-of select="substring(concat('Name',     '                                        '), 1, 40)" />
    <xsl:value-of select="substring(concat('Successes','          '                              ), 1, 10)" />
    <xsl:value-of select="substring(concat('Failures' ,'         '                               ), 1,  9)" />
    <xsl:value-of select="substring(concat('Total'    ,'     '                                   ), 1,  5)" />
    <xsl:text>&#xa;</xsl:text>

    <xsl:apply-templates select="testsuite"/>
  </xsl:template>

  <xsl:template match="testsuite">
        <xsl:value-of select="substring(concat(@name                                    ,'                                        '), 1, 40)" />
        <xsl:value-of select="substring(concat(count(testcase) - count(testcase/failure),'          '                              ), 1, 10)" />
        <xsl:value-of select="substring(concat(count(testcase/failure)                  ,'         '                               ), 1,  9)" />
        <xsl:value-of select="substring(concat(count(testcase)                          ,'     '                                   ), 1,  5)" />
    <xsl:text>&#xa;</xsl:text>
  </xsl:template>
</xsl:stylesheet>