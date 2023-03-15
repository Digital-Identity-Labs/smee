defmodule Smee.MixProject do
  use Mix.Project

  def project do
    [
      app: :smee,
      version: "0.2.0",
      elixir: "~> 1.14",
      description: "SAML Metadata Extractor, Etc",
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
        # logo: "path/to/logo.png",
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
      {:req, "~> 0.3.3"},
      {:sweet_xml, "~> 0.7.3"},
      {:rambo, "~> 0.3.4"},
      {:briefly, "~> 0.4.0"},
      {:easy_ssl, "~> 1.3"},
      {:xmerl_xml_indent, "~> 0.1.0"},
      {:xmlixer, "~> 0.1.1"},
      {:castore, ">= 0.0.0"},

      {:apex, "~> 1.2", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14 and >= 0.14.4", only: [:dev, :test]},
      {:benchee, "~> 1.0.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      {:earmark, "~> 1.3", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:doctor, "~> 0.17.0", only: :dev, runtime: false}
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
