defmodule Mix.Tasks.Deps.Smee do
  @moduledoc "Install backend CLI commands required by Smee"
  @shortdoc "Install backend CLI commands required by Smee"

  use Mix.Task

  alias Mix.Shell.IO

  @manual_text """
  This task can't install backend requirements for this OS.
  You will need to manually install these commands:
  xmllint xsltproc xmlsec1
  """

  @impl Mix.Task
  def run(_args) do

    case :os.type do
      {_, :nt} -> IO.error @manual_text
      {:unix, :darwin} -> IO.cmd("brew install xmlsec1 libxml2 libxslt", [])
      {:unix, :linux} -> issue = File.read!("/etc/issue")
                         cond do
                           String.contains?(issue, "Debian") ->
                             IO.cmd("sudo apt-get install xmlsec1 libxml2-utils xsltproc", [])
                           String.contains?(issue, "Ubuntu") ->
                             IO.cmd("sudo apt-get install xmlsec1 libxml2-utils xsltproc", [])
                           String.contains?(issue, "Red Hat") ->
                             IO.cmd("sudo yum install xmlsec1 libxml2 libxslt", [])
                           String.contains?(issue, "Alpine") ->
                             IO.cmd("sudo apk add --update --no-cache libxslt xmlsec libxml2-utils", [])
                           true ->
                             IO.error @manual_text
                         end
      _ -> IO.error @manual_text
    end

  end
end
