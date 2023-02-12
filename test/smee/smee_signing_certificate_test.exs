defmodule SmeeSigningCertificateTest do
  use ExUnit.Case

  alias Smee.SigningCertificate
  alias Smee.Source
  alias Smee.Metadata

  @local_cert "test/support/static/ukfederation.pem"
  @remote_cert "http://metadata.ukfederation.org.uk/ukfederation.pem"
  @local_cert_fp "AD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
  @not_local_cert_fp "AC:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:67"

  @source_with_remote_cert Source.new(
                             "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                             cert_url: @remote_cert
                           )

  @source_with_local_cert Source.new(
                            "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                            cert_url: "file:#{@local_cert}"
                          )

  @source_with_no_cert Source.new(
                         "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
                       )

  @source_missing_remote_cert Source.new(
                                "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                cert_url: "http://example.com/missing.pem",
                                retries: 0
                              )

  @source_missing_local_cert Source.new(
                               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                               cert_url: "file:missing_cert.pem"
                             )

  describe "prepare_file!/2" do

    test "When passed a Source struct using a cert file URL, return the local path to it" do
      path = SigningCertificate.prepare_file!(@source_with_local_cert)
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
      assert @local_cert = path
    end

    test "When passed a Source struct using a cert remote URL, download it and then return the local path to it" do
      path = SigningCertificate.prepare_file!(@source_with_remote_cert)
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
    end

    test "When passed a Source struct with no cert URL, select the default certificate and return the local path to it" do
      path = SigningCertificate.prepare_file!(@source_with_no_cert)
      assert String.ends_with?(path, "cacerts.pem")
      assert File.exists?(path)
    end

    test "When passed a Metadata struct using a cert file URL, return the local path to it" do
      path = SigningCertificate.prepare_file!(Smee.fetch!(@source_with_local_cert))
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
      assert @local_cert = path
    end

    test "When passed a Metadata struct using a cert remote URL, download it and then return the local path to it" do
      path = SigningCertificate.prepare_file!(Smee.fetch!(@source_with_remote_cert))
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
    end

    test "When passed a Metadata struct with no cert URL, select the default certificate and return the local path to it" do
      path = SigningCertificate.prepare_file!(Smee.fetch!(@source_with_no_cert))
      assert String.ends_with?(path, "cacerts.pem")
      assert File.exists?(path)
    end

    test "raise an exception if the local file is missing" do
      assert_raise RuntimeError,
                   fn ->
                     SigningCertificate.prepare_file!(@source_missing_local_cert)
                   end
    end

    test "raise an exception if the remote file is missing" do
      assert_raise RuntimeError,
                   fn ->
                     SigningCertificate.prepare_file!(@source_missing_remote_cert)
                   end
    end

  end

  describe "prepare_file/2" do

    test "When passed a Source struct using a cert file URL, return the local path to it in an :ok tuple" do
      response = SigningCertificate.prepare_file(@source_with_local_cert)
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
      assert @local_cert = path
    end

    test "When passed a Source struct using a cert remote URL, download it and then return the local path to it in an :ok tuple" do
      response = SigningCertificate.prepare_file(@source_with_remote_cert)
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
    end

    test "When passed a Source struct with no cert URL, select the default certificate and return the local path to it in an :ok tuple" do
      response = SigningCertificate.prepare_file(@source_with_no_cert)
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, "cacerts.pem")
      assert File.exists?(path)
    end

    test "When passed a Metadata struct using a cert file URL, return the local path to it in an :ok tuple" do
      response = SigningCertificate.prepare_file(Smee.fetch!(@source_with_local_cert))
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
      assert @local_cert = path
    end

    test "When passed a Metadata struct using a cert remote URL, download it and then return the local path to it in an :ok tuple" do
      response = SigningCertificate.prepare_file(Smee.fetch!(@source_with_remote_cert))
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
    end

    test "When passed a Metadata struct with no cert URL, select the default certificate and return the local path to it in an :ok tuple" do
      response = SigningCertificate.prepare_file(Smee.fetch!(@source_with_no_cert))
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, "cacerts.pem")
      assert File.exists?(path)
    end

    test "return an error tuple if a local file is missing" do
      response = SigningCertificate.prepare_file(@source_missing_local_cert)
      assert {:error, msg} = response
    end

    test "return an error tuple if a remote file is missing" do
      response = SigningCertificate.prepare_file(Smee.fetch!(@source_missing_remote_cert))
      assert {:error, msg} = response
    end

  end

  describe "prepare_file_url/2" do

    test "When passed a file URL, return the local path to it" do
      response = SigningCertificate.prepare_file_url("file:#{@local_cert}")
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
      assert @local_cert = path
    end

    test "When passed a remote URL, download it and then return the local path to it" do
      response = SigningCertificate.prepare_file_url(@remote_cert)
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
    end

    test "When also passed a matching fingerprint, return the local path to it" do
      response = SigningCertificate.prepare_file_url("file:#{@local_cert}", @local_cert_fp)
      assert {:ok, path} = response
      {:ok, path} = response
      assert String.ends_with?(path, ".pem")
      assert File.exists?(path)
      assert @local_cert = path
    end

    test "When also passed a mismatched fingerprint, return an error" do
      response = SigningCertificate.prepare_file_url("file:#{@local_cert}", @not_local_cert_fp)
      assert {:error, msg} = response
    end

  end

end

