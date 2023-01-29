defmodule Smee.Resources do

  def saml_metadata_xml_schema_file do
    Path.join(Application.app_dir(:smee, "priv"), "xml_schema/mdqt_check_schema.xsd")
  end

  def default_cert_file do
    Application.get_env(:smee, :default_cert_file, nil)
  end

end
