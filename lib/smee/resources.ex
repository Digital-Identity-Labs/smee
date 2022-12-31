defmodule Smee.Resources do

  def saml_metadata_xml_schema_file do
    Path.join(:code.priv_dir(:smee), "xml_schema/saml-schema-metadata-2.0.xsd")
  end
  
  def default_cert_file do
    Application.get_env(:smee, default_cert_file, nil)
  end

end
