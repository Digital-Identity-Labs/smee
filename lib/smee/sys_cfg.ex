defmodule Smee.SysCfg do

  @moduledoc false

  def strategies do
    [:pragmatic, :fast, :small, :standalone]
  end

  def strategy(metadata_or_entity) do
    Application.get_env(:smee, :strategy, :pragmatic)
  end

  def security_backend(metadata_or_entity) do
    Application.get_env(:smee, :verifier, Smee.Security.Xmlsec1)
  end

  ################################################################################


end