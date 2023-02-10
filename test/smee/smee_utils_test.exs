defmodule SmeeUtilsTest do
  use ExUnit.Case

  alias Smee.Utils

  @xml File.read!("test/support/static/aggregate.xml")

  describe "sha1/1" do

    test "returns the correct sha1 hash of the value passed to it" do
      assert "77603e0cbda1e00d50373ca8ca20a375f5d1f171" = Utils.sha1("https://indiid.net/idp/shibboleth")
      assert "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12" = Utils.sha1("The quick brown fox jumps over the lazy dog")
      assert "da39a3ee5e6b4b0d3255bfef95601890afd80709" = Utils.sha1("")
    end

  end

  describe "file_url?/1" do

    test "returns true if passed a URL with the file: scheme" do
      assert true = Utils.file_url?("file://var/log/something.txt")
      assert true = Utils.file_url?("file:/etc/config")
    end

    test "returns false if passed a URL with the http[s]: scheme" do
      refute Utils.file_url?("https://mysite.local/something.txt")
      refute Utils.file_url?("http://example.com/news")
    end

    test "returns false if passed nothing sensible at all" do
      refute Utils.file_url?("")
      refute Utils.file_url?(nil)
    end

  end

  describe "normalize_url/1" do

    test "returns a url string if passed a valid url string" do
      assert "https://example.com/info" = Utils.normalize_url("https://example.com/info")
      assert "file:/etc/config.txt" = Utils.normalize_url("file:/etc/config.txt")
    end

    test "returns a url string if passed a URI record" do
      assert "https://elixir-lang.org/" = Utils.normalize_url(URI.parse("https://elixir-lang.org/"))
    end

    test "returns a url if passed a file path" do
      assert "file:local_file.txt" = Utils.normalize_url("local_file.txt")
      assert "file:/etc/config.txt" = Utils.normalize_url("/etc/config.txt")
    end

  end

  describe "file_url/1" do

    test "returns true if the url is a valid file path" do
      assert Utils.file_url?("file:/etc/config.txt")
    end

    test "returns false if the url is anything else" do
      refute Utils.file_url?("/etc/config.txt")
      refute Utils.file_url?("https://elixir-lang.org/")
    end

  end

  describe "local_cert?/1" do

    test "returns true when passed a Source or Metadata struct that contains a local cert URL" do
      assert Utils.local_cert?(Smee.Source.new("/var/x/fed.xml", cert_url: "./local.pem"))
      assert Utils.local_cert?(Smee.Source.new("/var/x/fed.xml", cert_url: "file:/local.pem"))
      assert Utils.local_cert?(Smee.Metadata.new(@xml, cert_url: "./local.pem"))
      assert Utils.local_cert?(Smee.Metadata.new(@xml, cert_url: "file:/local.pem"))
    end

    test "return false when passed a Source or Metadata struct that does not contain a local cert URL" do
      refute Utils.local_cert?(Smee.Source.new("/var/x/fed.xml", cert_url: nil))
      refute Utils.local_cert?(Smee.Source.new("/var/x/fed.xml", cert_url: "http://example.com/remote.pem"))
      refute Utils.local_cert?(Smee.Metadata.new(@xml, cert_url: nil))
      refute Utils.local_cert?(Smee.Metadata.new(@xml, cert_url: "http://example.com/remote.pem"))
    end

  end

  describe "local?/1" do

    test "returns true when passed a Source or Metadata struct that contains a local metadata URL" do
      assert Utils.local?(Smee.Source.new("/var/x/fed.xml", url: "./local.xml"))
      assert Utils.local?(Smee.Source.new("/var/x/fed.xml", url: "file:/local.xml"))
      assert Utils.local?(Smee.Metadata.new(@xml, url: "./local.xml"))
      assert Utils.local?(Smee.Metadata.new(@xml, url: "file:/local.xml"))
    end

    test "return false when passed a Source or Metadata struct that does not contain a local metadata URL" do
      refute Utils.local?(Smee.Source.new("http://example.com/metadata.xml"))
      refute Utils.local?(Smee.Metadata.new(@xml, url: nil))
      refute Utils.local?(Smee.Metadata.new(@xml, url: "http://example.com/remote.pem"))
    end

  end

  describe "file_url_to_path/1" do

    test "Converts a file: URL to a normal filesystem path" do
      assert "local.xml" = Utils.file_url_to_path("file:local.xml")
    end

    test "Raises an exception when passed something that is not a file: URL" do
      assert_raise RuntimeError, fn -> Utils.file_url_to_path("http://example.com/remote.pem") end
      assert_raise RuntimeError, fn -> Utils.file_url_to_path(nil) end
    end

  end

  describe "file_url_to_path/2" do

    test "Converts a file: URL to a normal filesystem path if within the base path" do
      assert "/var/data/local.xml" = Utils.file_url_to_path("file:/var/data/local.xml", "/var/data")
    end

    test "Raises an exception if passed a file: url that is not within the specified base path" do
      assert_raise RuntimeError, fn -> Utils.file_url_to_path("file:/var/data/local.xml", "/var/log") end
    end

    test "Raises an exception when passed something that is not a file: URL" do
      assert_raise RuntimeError, fn -> Utils.file_url_to_path("http://example.com/remote.pem", "/var/data") end
      assert_raise RuntimeError, fn -> Utils.file_url_to_path(nil, "/var/data") end
    end

  end

end



