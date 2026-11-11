defmodule Smee.XMLProcessor.LibXMLTools do

  use Smee.XMLProcessor.XMLProcessorBackend, id: :libxml_tools, tools: ["xmllint", "xsltproc", "xmlsec1"]

end