defmodule SmeeSecurityTest do
  use ExUnit.Case

  alias Smee.Security
  alias Smee.Metadata
  alias Smee.Source

  @invalid_metadata_file "test/support/static/bad.xml"
  @valid_metadata_file "test/support/static/aggregate.xml"
  @valid_single_metadata_file "test/support/static/indiid.xml"
  @valid_metadata_xml File.read! @valid_metadata_file
  @invalid_metadata_xml File.read! @invalid_metadata_file
  @valid_single_metadata_xml File.read! @valid_single_metadata_file


  describe "verify!/1" do

    test "returns a verified metadata record if passed a signed metadata struct, with certificate" do
      assert %Metadata{verified: true} = Source.new(
                                           "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                           cert_url: "test/support/static/ukfederation.pem",
                                         )
                                         |> Smee.fetch!()
                                         |> Security.verify!()
    end

    test "will check a certificate against an sha1 fingerprint if also passed a fingerprint" do
      assert %Metadata{verified: true} = Source.new(
                                           "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                           cert_url: "test/support/static/ukfederation.pem",
                                           cert_fingerprint: "AD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
                                         )
                                         |> Smee.fetch!()
                                         |> Security.verify!()

    end

    test "will raise an exception if the certificate does not match the fingerprint, if one is passed" do
      assert_raise RuntimeError,
                   fn ->
                     Source.new(
                       "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                       cert_url: "test/support/static/ukfederation.pem",
                       cert_fingerprint: "BD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
                     )
                     |> Smee.fetch!()
                     |> Security.verify!()
                   end
    end

    test "will use a local certificate if one is specified in the source" do
      assert %Metadata{verified: true} = Source.new(
                                           "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                           cert_url: "test/support/static/ukfederation.pem",
                                         )
                                         |> Smee.fetch!()
                                         |> Security.verify!()
    end

    test "will use a remote certificate if one is specified in the source" do
      assert %Metadata{verified: true} = Source.new(
                                           "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                           cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem",
                                         )
                                         |> Smee.fetch!()
                                         |> Security.verify!()
    end

    test "will raise an exception if the metadata verification fails" do
      assert_raise RuntimeError,
                   fn ->
                     Source.new(
                       "test/support/static/tampered.xml",
                       cert_url: "test/support/static/ukfederation.pem",
                     )
                     |> Smee.fetch!()
                     |> Security.verify!()
                   end
    end

  end

  describe "verify/1" do

    test "returns a verified metadata record in an :ok tuple if passed a signed metadata struct, with certificate" do
      assert {:ok, %Metadata{verified: true}} = Source.new(
                                                  "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                                  cert_url: "test/support/static/ukfederation.pem",
                                                )
                                                |> Smee.fetch!()
                                                |> Security.verify()
    end

    test "will check a certificate against an sha1 fingerprint if also passed a fingerprint" do
      assert{:ok, %Metadata{verified: true}} = Source.new(
                                                 "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                                 cert_url: "test/support/static/ukfederation.pem",
                                                 cert_fingerprint: "AD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
                                               )
                                               |> Smee.fetch!()
                                               |> Security.verify()

    end

    test "will return an :error tuple if the certificate does not match the fingerprint, if one is passed" do
      assert {:error, _message} = Source.new(
                                    "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                    cert_url: "test/support/static/ukfederation.pem",
                                    cert_fingerprint: "BD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
                                  )
                                  |> Smee.fetch!()
                                  |> Security.verify()

    end

    test "will use a local certificate if one is specified in the source" do
      assert {:ok, %Metadata{verified: true}} = Source.new(
                                                  "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                                  cert_url: "test/support/static/ukfederation.pem",
                                                )
                                                |> Smee.fetch!()
                                                |> Security.verify()
    end

    test "will use a remote certificate if one is specified in the source" do
      assert {:ok, %Metadata{verified: true}} = Source.new(
                                                  "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                                                  cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem",
                                                )
                                                |> Smee.fetch!()
                                                |> Security.verify()
    end

    test "will return an :error tuple if the metadata verification fails" do
      assert {:error, _message} = Source.new(
                                    "test/support/static/tampered.xml",
                                    cert_url: "test/support/static/ukfederation.pem",
                                    type: :single,
                                  )
                                  |> Smee.Fetch.local!()
                                  |> Security.verify()

    end

  end

  describe "verify?/1" do
    test "returns true if passed a signed metadata struct, with certificate" do
      assert true = Source.new(
                      "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                      cert_url: "test/support/static/ukfederation.pem",
                    )
                    |> Smee.fetch!()
                    |> Security.verify?()
    end

    test "will check a certificate against an sha1 fingerprint if also passed a fingerprint" do
      assert true = Source.new(
                      "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                      cert_url: "test/support/static/ukfederation.pem",
                      cert_fingerprint: "AD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
                    )
                    |> Smee.fetch!()
                    |> Security.verify?()

    end

    test "will return false if the certificate does not match the fingerprint, if one is passed" do
      refute Source.new(
               "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
               cert_url: "test/support/static/ukfederation.pem",
               cert_fingerprint: "BD:80:7A:6D:26:8C:59:01:55:47:8D:F1:BA:61:68:10:DA:81:86:66"
             )
             |> Smee.fetch!()
             |> Security.verify?()

    end

    test "will use a local certificate if one is specified in the source" do
      assert true = Source.new(
                      "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                      cert_url: "test/support/static/ukfederation.pem",
                    )
                    |> Smee.fetch!()
                    |> Security.verify?()
    end

    test "will use a remote certificate if one is specified in the source" do
      assert true = Source.new(
                      "http://metadata.ukfederation.org.uk/ukfederation-metadata.xml",
                      cert_url: "http://metadata.ukfederation.org.uk/ukfederation.pem",
                    )
                    |> Smee.fetch!()
                    |> Security.verify?()
    end

    test "will return false if the metadata verification fails" do
      refute Source.new(
               "test/support/static/tampered.xml",
               cert_url: "test/support/static/ukfederation.pem",
               type: :single,
             )
             |> Smee.Fetch.local!()
             |> Security.verify?()

    end
  end

end
