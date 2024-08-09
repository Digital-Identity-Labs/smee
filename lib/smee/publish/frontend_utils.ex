defmodule Smee.Publish.FrontendUtils do

  @moduledoc false

  @default_options [format: :saml, lang: "en", id_type: :hash, to: "published", labels: false]
  @allowed_options Keyword.keys(@default_options) ++ [:valid_until, :filename]

  @spec formats() :: list(atom())
  def formats() do
    [
      :csv,
      :disco,
      :index,
      :markdown,
      :saml,
      :thiss,
      :udest,
      :udisco
    ]
  end

  def prepare_options(options) do
    Keyword.merge(@default_options, options)
    |> Keyword.take(@allowed_options)
  end

  def select_backend(options) do
    case options[:format] do
      :csv -> Smee.Publish.Csv
      :disco -> Smee.Publish.Disco
      :index -> Smee.Publish.Index
      :markdown -> Smee.Publish.Markdown
      :metadata -> Smee.Publish.SamlXml
      :saml -> Smee.Publish.SamlXml
      :thiss -> Smee.Publish.Thiss
      :udest -> Smee.Publish.Udest
      :udisco -> Smee.Publish.Udisco
      :default -> Smee.Publish.SamlXml
      nil -> Smee.Publish.SamlXml
      _ -> raise "Unknown publishing format ':#{options[:format]}' - known formats include #{Enum.join(formats(), ", :")}"
    end
  end

end
