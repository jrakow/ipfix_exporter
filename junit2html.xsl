<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="html" indent="yes" encoding="UTF-8" />
  <xsl:template match="/testsuites">

    <html>
      <head>
        <title>VHDL Unit Test Results</title>
        <style>
          table {
          width: 80%;
          border: 1px solid black;
          border-collapse: collapse;
          }
          th {
          height: 50px;
          }
          th, td {
          padding:
          10px;
          text-align: left;
          border-bottom: 1px solid #888;
          }
          .failure
          {
          background: #f77
          }
          .no-failure {
          background: #7f7
          }
          code {
          display: block;
          white-space: pre-wrap;
          width:500px;
          background-color:#F9F9F9;
          border:1px dashed blue;
          padding:20px
          20px;
          }
        </style>
      </head>
      <body>
        <h1> VHDL Unit Test Results </h1>
        <!-- <xsl:call-template name="summary" /> -->
        <xsl:apply-templates select="testsuite">
          <xsl:sort select="name" />
        </xsl:apply-templates>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="testsuite">
    <hr />
    <h2>
      Testsuite
      <xsl:value-of select="@name" />
    </h2>
    <table>
      <col style="width:30%" />
      <col style="width: 5%" />
      <col style="width:15%" />
      <col style="width:50%" />
      <tr>
        <th> Name </th>
        <th> Result </th>
        <th> Message </th>
        <th> Output </th>
      </tr>
      <xsl:apply-templates select="testcase">
        <xsl:sort select="name" />
      </xsl:apply-templates>
    </table>
  </xsl:template>

  <xsl:template match="testcase">
    <tr>
      <td>
        <xsl:value-of select="@name" />
      </td>
      <xsl:choose>
        <xsl:when test="failure">
          <td class="failure">Failure</td>
          <td class="failure">
            <xsl:value-of select="failure/@message" />
          </td>
        </xsl:when>
        <xsl:otherwise>
          <td class="no-failure">Success</td>
          <td class="no-failure"></td>
        </xsl:otherwise>
      </xsl:choose>

      <td>
        <details>
          <summary>Output</summary>
          <h3>System out</h3>
          <xsl:value-of select="system-out" />
          <h3>System error</h3>
          <xsl:value-of select="system-err" />
        </details>
      </td>
    </tr>
  </xsl:template>
</xsl:stylesheet>