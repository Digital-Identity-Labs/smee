defmodule Smee.Certificate do

  alias __MODULE__
  alias Smee.Metadata
  alias Smee.Utils

  def prepare_file!(input) do
    case prepare_file(input) do
      {:ok, path} -> path
      {:error, msg} -> raise "Cannot prepare certificate: #{msg}"
    end
  end

  def prepare_file(nil) do
    Smee.Resources.default_cert_file()
    |> prepare_file()
  end

  def prepare_file(%{cert_url: nil}) do
    Smee.Resources.default_cert_file()
    |> prepare_file()
  end

  def prepare_file(%{cert_url: url, cert_fingerprint: fingerprint}) do
    prepare_file(url, fingerprint)
  end

  def prepare_file(%{cert_url: url}) do
    prepare_file(url, nil)
  end

  def prepare_file(url, fingerprint) when is_binary(url) do
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
    cert_file = Path.join(dynamic_cert_dir, hashname)

    if File.exists?(cert_file) do
      {:ok, cert_file}
    else
      try do
        pem_data = download(url)

        {:ok, fh} = File.open(cert_file, [:write, :utf8])
        IO.write(fh, pem_data)
        File.close(fh)

      rescue
        e -> {:error, "File #{url} cannot be downloaded!"}
      end
      {:ok, cert_file}
    end
  end

  defp  ensure_local_cert!(url) do
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
      e -> {:error, "Unable to parse certificate #{path}"}
    end

  end

  defp cert_dir do

  end

  def download(url) do
    Req.get!(
      url,
      headers: [{"accept", "application/x-pem-file"}],
      max_redirects: 3,
      cache: true,
      user_agent: Utils.http_agent_name,
      http_errors: :raise,
      max_retries: 3,
      retry_delay: &retry_jitter/1
    ).body
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
      _ -> Briefly.create(directory: true)
    end

  end

end
