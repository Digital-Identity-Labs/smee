defmodule Smee.SigningCertificate do

  @moduledoc false

  #alias __MODULE__
  alias Smee.Utils
  alias Smee.SysCfg

  @spec prepare_file!(input :: struct(), fingerprint :: binary() | nil) :: binary()
  def prepare_file!(input, override_fingerprint \\ nil) do
    case prepare_file(input, override_fingerprint) do
      {:ok, path} -> path
      {:error, msg} -> raise "Cannot prepare certificate: #{msg}"
    end
  end

  @spec prepare_file(input :: struct(), fingerprint :: binary() | nil) :: {:ok, binary()} | {
    :error,
    binary()
  }
  def prepare_file(input, override_fingerprint \\ nil)
  def prepare_file(%{cert_url: nil, cert_fingerprint: _}, override_fingerprint) do
    Smee.Resources.default_cert_file_url()
    |> prepare_file_url(override_fingerprint)
  end

  def prepare_file(%{cert_url: url, cert_fingerprint: fingerprint}, override_fingerprint) do
    fp = select_fingerprint(fingerprint, override_fingerprint)
    prepare_file_url(url, fp)
  end

  def prepare_file(%{cert_url: url}, override_fingerprint) do
    prepare_file_url(url, override_fingerprint)
  end

  @spec prepare_file(binary() | nil, fingerprint :: binary() | nil) :: {:ok, binary()} | {
    :error,
    binary()
  }
  def prepare_file_url(url, fingerprint \\ nil)
  def prepare_file_url(nil, fingerprint) do
    Smee.Resources.default_cert_file_url()
    |> prepare_file_url(fingerprint)
  end

  def prepare_file_url(url, fingerprint) when is_binary(url) do
    with {:ok, path} <- ensure_local_cert(url),
         {:ok, path} <- fingerprint_check(path, fingerprint) do
      {:ok, path}
    else
      err -> err
    end

  end



  #  def provided?(c) do
  #
  #  end
  #
  #  def local?(c) do
  #
  #  end
  #
  #  def remote?(c) do
  #
  #  end
  #
  #  def exists?(c) do
  #
  #  end


  ################################################################################

  defp select_fingerprint(nil, nil), do: nil
  defp select_fingerprint(builtin, nil), do: builtin
  defp select_fingerprint(_builtin, override), do: override

  defp  ensure_local_cert("file:" <> _ = url) do
    path = Utils.file_url_to_path(url)
    if File.exists?(path) do
      {:ok, path}
    else
      {:error, "File #{path} does not exist!"}
    end
  end

  defp  ensure_local_cert("http" <> _ = url) do
    hashname = Utils.sha1(url) <> ".pem"
    cert_file = Path.join(dynamic_cert_dir(), hashname)

    if File.exists?(cert_file) do
      {:ok, cert_file}
    else
      try do
        case download(url) do
          {:ok, pem_data} -> {:ok, fh} = File.open(cert_file, [:write, :utf8])
                             IO.write(fh, pem_data)
                             File.close(fh)
                             {:ok, cert_file}
          {:error, _message} -> {:error, "File #{url} cannot be downloaded!"}
        end

      rescue
        _ -> {:error, "File #{url} cannot be downloaded!"}
      end

    end
  end

  defp  ensure_local_cert(url) do
    raise "Unknown format of url #{url}!"
  end

  defp fingerprint_check(path, nil) do
    {:ok, path}
  end

  defp fingerprint_check(path, fingerprint) do

    try do
      cert_info = File.read!(path)
                  |> EasySSL.parse_pem()

      src_fingerprint = normalize_fingerprint(fingerprint)
      actual_fingerprint = normalize_fingerprint(cert_info.fingerprint)

      if src_fingerprint == actual_fingerprint do
        {:ok, path}
      else
        {:error, "Certificate fingerprint #{actual_fingerprint} does not match source fingerprint #{src_fingerprint}}"}
      end

    rescue
      _ -> {:error, "Unable to parse certificate #{path}"}
    end

  end

  def download(url) do
    response = Req.get!(
      url,
      headers: %{
        "accept" => "application/x-pem-file"
      },
      max_redirects: 5,
      cache: true,
      cache_dir: SysCfg.cache_directory(),
      user_agent: Utils.http_agent_name,
      #http_errors: :raise,
      max_retries: 3,
      retry_delay: &retry_jitter/1
    )

    case response.status do
      200 -> {:ok, response.body}
      other_status when other_status in 100..999 -> {:error, :"http_#{other_status}"}
    end

  end

  defp retry_jitter(n) do
    trunc(Integer.pow(2, n) * 1000 * (1 - 0.1 * :rand.uniform()))
  end

  defp normalize_fingerprint(fingerprint) do
    fingerprint
    |> String.trim()
    |> String.upcase()
  end

  def dynamic_cert_dir do

    case Application.get_env(:smee, :cert_dir) do
      {:ok, dir} -> dir
      _ -> {:ok, path} = Briefly.create(type: :directory)
           path
    end

  end

end
