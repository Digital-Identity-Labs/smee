defmodule Smee.Resources do

  @moduledoc false

  @spec saml_metadata_xml_schema_file() :: binary()
  def saml_metadata_xml_schema_file do
    Path.join(Application.app_dir(:smee, "priv"), "xml_schema/mdqt_check_schema.xsd")
  end

  @spec default_cert_file() ::binary()
  def default_cert_file do
    Application.get_env(:smee, :default_cert_file, CAStore.file_path())
  end

  @spec default_cert_file_url() :: binary()
  def default_cert_file_url do
    "file:" <> default_cert_file()
  end



  ################################################################################


end
