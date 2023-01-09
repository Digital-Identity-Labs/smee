defmodule SmeeUtilsTest do
  use ExUnit.Case

  alias Smee.Utils

  describe "sha1/1" do

    test "returns the correct sha1 hash of the value passed to it" do
      assert "77603e0cbda1e00d50373ca8ca20a375f5d1f171"  = Utils.sha1("https://indiid.net/idp/shibboleth")
      assert "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"  = Utils.sha1("The quick brown fox jumps over the lazy dog")
      assert "da39a3ee5e6b4b0d3255bfef95601890afd80709"  = Utils.sha1("")
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

end



