defmodule SmeeUtilsTest do
  use ExUnit.Case

  alias Smee.Utils
  alias Smee.Source

  @xml File.read!("test/support/static/aggregate.xml")

  describe "sha1/1" do

    test "returns the correct sha1 hash of the value passed to it" do
      assert "77603e0cbda1e00d50373ca8ca20a375f5d1f171" = Utils.sha1("https://indiid.net/idp/shibboleth")
      assert "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12" = Utils.sha1("The quick brown fox jumps over the lazy dog")
    end

    test "returns nil if passed nil" do
      assert nil == Utils.sha1(nil)
    end

    test "returns nil if passed an empty string" do
      assert nil == Utils.sha1("")
    end

  end

  describe "parse_http_datetime/1" do

    test "returns nil when passed nil" do
      assert is_nil(Utils.parse_http_datetime(nil))
    end

    test "returns nil when passed an empty string" do
      assert is_nil(Utils.parse_http_datetime(""))
    end

    test "Actual datetimes pass through unchanged" do
      dt = DateTime.utc_now()
      assert ^dt = Utils.parse_http_datetime(dt)
    end

    test "parses a correct http datetime string" do
      assert ~U[2023-02-12 20:52:35Z] = Utils.parse_http_datetime("Sun, 12 Feb 2023 20:52:35 GMT")
    end

    test "parses a correct http datetime string that's the first item in a list" do
      assert ~U[2023-02-12 20:52:35Z] = Utils.parse_http_datetime(["Sun, 12 Feb 2023 20:52:35 GMT"])
    end

    test "raises an exception if the date cannot be parsed" do
      assert_raise RuntimeError, fn -> Utils.parse_http_datetime("Sun, 1 Feb 2023 20:52:35 GMT") end
      assert_raise RuntimeError, fn -> Utils.parse_http_datetime("baboons") end
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

  describe "http_agent_name/0" do

    test "returns a string beginning with Smee " do
      assert String.starts_with?(Utils.http_agent_name(), "Smee")
    end

    test "returns a string containing correct version" do
      assert String.contains?(Utils.http_agent_name(), "#{Application.spec(:smee, :vsn)}")
    end

  end

  describe "xdoc_to_string/1" do

    test "Converts a parsed, Xmerl structure as a string sort-of mostly matching the original*" do
      xml_string = ~s|<?xml version="1.0" encoding="UTF-8" ?>\n<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"></xs:schema>|
      xmerl = SweetXml.parse(xml_string)
      unxmerl = Utils.xdoc_to_string(xmerl)

      assert is_binary(Utils.xdoc_to_string(xmerl))
      ## This is difficult, need canonicalisation to accurately compare - TODO!
      #assert ^xml_string = Utils.xdoc_to_string(xmerl)
      assert unxmerl == Utils.xdoc_to_string(
               SweetXml.parse(Utils.xdoc_to_string(xmerl))
             ) # At least consistent with its own XML
    end

  end

  describe "fetchable_remote_xml/1" do

    test "returns aggregate source URLs as they are, because they should point directly to XML" do
      assert "http://metadata.example.com/metadata.xml" = Utils.fetchable_remote_xml(
               Source.new("http://metadata.example.com/metadata.xml")
             )
    end

    test "returns MDQ *base* URLs adjusted to directly to the service's aggregate equivalent" do
      assert "http://mdq.ukfederation.org.uk/entities" = Utils.fetchable_remote_xml(
               Smee.source("http://mdq.ukfederation.org.uk/", type: :mdq)
             )
    end

  end

  describe "nillify_map_empties/1" do

    test "any values in a map that are empty strings are converted to nils" do
      assert %{one: "One", two: nil, three: 3, four: nil} = Utils.nillify_map_empties(
               %{one: "One", two: "", three: 3, four: ""}
             )
    end

  end

  describe "normalize_fingerprint/1" do

    test "should return nil if passed nil, as a fingerprint is not required" do
      assert Utils.normalize_fingerprint(nil) == nil
    end

    test "should return correct 40 character capitalised hex strings with colons when passed such" do
      assert "3F:6B:F4:AF:E0:1B:3C:D7:C1:F2:3D:F6:EA:C5:60:AE:B1:5A:E8:26" = Utils.normalize_fingerprint(
               "3F:6B:F4:AF:E0:1B:3C:D7:C1:F2:3D:F6:EA:C5:60:AE:B1:5A:E8:26"
             )
    end

    test "should return 40 character capitalised hex strings with colons when passed correct hashes without colons" do
      assert "3F:6B:F4:AF:E0:1B:3C:D7:C1:F2:3D:F6:EA:C5:60:AE:B1:5A:E8:26" = Utils.normalize_fingerprint(
               "3F6BF4AFE01B3CD7C1F23DF6EAC560AEB15AE826"
             )

      assert "3F:6B:F4:AF:E0:1B:3C:D7:C1:F2:3D:F6:EA:C5:60:AE:B1:5A:E8:26" = Utils.normalize_fingerprint(
               "3f6bf4afe01b3cd7c1f23df6eac560aeb15ae826"
             )
    end

    test "should return 40 character capitalised hex strings with colons when passed correct hashes that are lowercase" do
      assert "3F:6B:F4:AF:E0:1B:3C:D7:C1:F2:3D:F6:EA:C5:60:AE:B1:5A:E8:26" = Utils.normalize_fingerprint(
               "3f:6b:f4:af:e0:1b:3c:d7:c1:f2:3d:f6:ea:c5:60:ae:b1:5a:e8:26"
             )

    end

    test "should raise an exception if not passed a valid sha1 hash at all" do
      assert_raise RuntimeError, fn -> Utils.normalize_fingerprint("The quick brown fox") end
    end

  end

  describe "check_cache_dir!/1" do

    test "should raise an exception if passed what looks like an obviously dangerous or bad path for a cache" do
      assert_raise RuntimeError, fn -> Utils.check_cache_dir!(nil) end
      assert_raise RuntimeError, fn -> Utils.check_cache_dir!("") end
      assert_raise RuntimeError, fn -> Utils.check_cache_dir!("/") end
      assert_raise RuntimeError, fn -> Utils.check_cache_dir!(System.user_home!()) end
      assert_raise RuntimeError, fn -> Utils.check_cache_dir!(File.cwd!()) end
    end

    test "should simply return an apparently innocent cache path" do
      assert "/tmp/cache" = Utils.check_cache_dir!("/tmp/cache")
    end

  end

  describe "tidy_tags/1" do

    test "should return an empty list if passed nil" do
      assert [] = Utils.tidy_tags(nil)
    end

    test "should return an empty list if passed an empty list" do
      assert [] = Utils.tidy_tags([])
    end

    test "should return an list of one binary item if passed one item" do
      assert ["hello"] = Utils.tidy_tags("hello")
      assert ["hello"] = Utils.tidy_tags(:hello)
    end

    test "should return a list of binary strings if passed strings and/or atoms or numbers" do
      assert ["1", "a", "b", "c", "d"] = Utils.tidy_tags([1, :a, "b", "c", :d])
    end

    test "should return a list without duplicate tags, including mixed types" do
      assert ["1", "3", "two"] = Utils.tidy_tags([1, 1, "1", "two", :two, "3", "3"])
    end

  end

  describe "format_xml_date/1" do
    test "returns datetime in a suitable string for inclusion in metadata" do
      {:ok, dt} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      assert "2016-05-24T13:26:08Z" = Utils.format_xml_date(dt)
    end
  end

  describe "valid_until/1" do

    test "returns same datetime in a suitable string when passed a datetime" do
      {:ok, dt} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      assert "2016-05-24T13:26:08Z" = Utils.valid_until(dt)
    end

    test "when passed an integer, will return datetime string that many days in the future" do
      now_dt = DateTime.utc_now()
               |> DateTime.truncate(:second)
      {:ok, future_dt, _} = Utils.valid_until(30)
                            |> DateTime.from_iso8601()
      assert DateTime.diff(future_dt, now_dt) == (30 * 24 * 60 * 60)
    end

    test "when passed 'auto' or :auto will return the datetime string for the default validity period" do
      now_dt = DateTime.utc_now()
               |> DateTime.truncate(:second)
      {:ok, future_dt, _} = Utils.valid_until("default")
                            |> DateTime.from_iso8601()
      assert DateTime.diff(future_dt, now_dt) == (Smee.SysCfg.validity_days * 24 * 60 * 60)
    end

    test "when passed 'default' or :default will also return the datetime string for the default validity period" do
      now_dt = DateTime.utc_now()
               |> DateTime.truncate(:second)
      {:ok, future_dt, _} = Utils.valid_until("auto")
                            |> DateTime.from_iso8601()
      assert DateTime.diff(future_dt, now_dt) == (Smee.SysCfg.validity_days * 24 * 60 * 60)
    end

  end

  describe "before/2" do

    test "returns true if the subject DateTime is before the second DateTime" do
      {:ok, dt1} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      dt2 = DateTime.utc_now()
      assert Utils.before?(dt1, dt2)
    end

    test "returns false if the subject DateTime is after the second DateTime" do
      dt1 = DateTime.utc_now()
      {:ok, dt2} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      refute Utils.before?(dt1, dt2)
    end

    test "accepts a date string as the second parameter" do
      {:ok, dt1} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      assert Utils.before?(dt1, "2019-05-07")
    end

    test "works with both Dates and DateTimes" do
      {:ok, d1} = Date.new(2016, 05, 24)
      dt1 = DateTime.utc_now()
      d2 = Date.utc_today()
      assert  assert Utils.before?(d1, dt1)
      assert  assert Utils.before?(d1, d2)
    end

  end

  describe "after/2" do

    test "returns true if the subject DateTime is after the specified DateTime" do
      dt1 = DateTime.utc_now()
      {:ok, dt2} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      assert Utils.after?(dt1, dt2)
    end

    test "returns false if the subject DateTime is before the specified DateTime" do
      {:ok, dt1} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      dt2 = DateTime.utc_now()
      refute Utils.after?(dt1, dt2)
    end

    test "accepts a date string as the second parameter" do
      {:ok, dt1} = DateTime.new(~D[2016-05-24], ~T[13:26:08.003], "Etc/UTC")
      assert Utils.after?(dt1, "2012-05-07")
    end

    test "works with both Dates and DateTimes" do
      {:ok, then} = Date.new(2016, 05, 24)
      now_dt = DateTime.utc_now()
      now_d = Date.utc_today()
      assert assert Utils.after?(now_dt, then)
      assert assert Utils.after?(now_d, then)
    end

  end

  describe "days_ago/2" do

    test "returns the Date for the specified number of days ago" do
      date_a_week_ago = Date.utc_today()
                        |> Date.add(-7)
      assert ^date_a_week_ago = Utils.days_ago(7)
    end

  end

  describe "normalise_mdid/1" do

    test "returns nil given an empty string" do
      assert is_nil(Utils.normalise_mdid(""))
    end

    test "returns nil given a nil" do
      assert is_nil(Utils.normalise_mdid(nil))
    end

    test "returns a string given a string" do
      assert "hello" = Utils.normalise_mdid("hello")
    end

    test "returns a string given an atom" do
      assert "world" = Utils.normalise_mdid(:world)
    end

    test "returns a string given an integer" do
      assert "5" = Utils.normalise_mdid(5)
    end

  end

end
