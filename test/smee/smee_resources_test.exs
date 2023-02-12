defmodule SmeeResourcesTest do
  use ExUnit.Case

  alias Smee.Resources

  describe "saml_metadata_xml_schema_file/0" do

    test "returns the path to the metadata schema file" do
      path = Resources.saml_metadata_xml_schema_file()
      assert String.ends_with?(path, "mdqt_check_schema.xsd")
      assert File.exists?(path)
    end

    test "returns the path an existing file" do
      assert File.exists?(Resources.saml_metadata_xml_schema_file())
    end

  end

  describe "default_cert_file/0" do

    test "returns the path to the default certificate file" do
      path = Resources.default_cert_file()
      assert String.ends_with?(path, "cacerts.pem")
    end

    test "returns the path an existing file" do
      assert File.exists?(Resources.default_cert_file())
    end

  end

  describe "default_cert_file_url/0" do

    test "returns the same path as default_cert_file/0, but as a URL" do
      path = Resources.default_cert_file()
      url_path = "file:" <> path
      assert url_path = Resources.default_cert_file_url()
    end

  end

end

