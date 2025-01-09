defmodule Smee.MixProject do
  use Mix.Project

  def project do
    [
      app: :smee,
      version: "0.5.1",
      elixir: "~> 1.14",
      description: "SAML Metadata Extractor, Etc: A library for processing large collections of SAML metadata",
      package: package(),
      name: "Smee",
      source_url: "https://github.com/Digital-Identity-Labs/smee",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: [
        main: "readme",
        logo: "logo.png",
        extras: ["README.md", "LICENSE"]
      ],
      deps: deps(),
      compilers: Mix.compilers() ++ [:rambo], # Needed until issue fixed in Rambo
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.4"},
      {:sweet_xml, "~> 0.7"},
      {:rambo, "~> 0.3.4"},
      {:briefly, "~> 0.5.0"},
      #{:easy_ssl, "~> 1.3"},
      {:xmerl_xml_indent, "~> 0.2.0"},
      {:xmlixer, "~> 0.1.1"},
      {:castore, ">= 1.0.5"},
      {:memoize, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:csv, "~> 3.2"},
      {:zarex, "~> 1.0"},
      {:iteraptor, "~> 1.14"},

      {:apex, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14 and >= 0.14.4", only: [:dev, :test]},
      {:benchee, "~> 1.3", only: [:dev, :test]},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:earmark, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.21", only: :dev, runtime: false},
      {:ex_json_schema, "~> 0.10.2", only: :test, runtime: false}
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/Digital-Identity-Labs/smee"
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "priv"]
  defp elixirc_paths(_), do: ["lib", "priv"]

end
