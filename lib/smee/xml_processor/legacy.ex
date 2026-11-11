defmodule Smee.XMLProcessor.Legacy do

  use Smee.XMLProcessor.XMLProcessorBackend, id: :legacy, tools: ["xmllint", "xsltproc", "xmlsec1"]

end