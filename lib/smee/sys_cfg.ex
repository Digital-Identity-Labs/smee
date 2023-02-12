defmodule Smee.SysCfg do

  @moduledoc false

  @spec strategies() :: list(atom())
  def strategies do
    [:pragmatic, :fast, :small, :standalone]
  end

  @spec strategy() :: atom()
  def strategy() do
    Application.get_env(:smee, :strategy, :pragmatic)
  end

  @spec security_backend() :: atom()
  def security_backend() do
    Application.get_env(:smee, :verifier, Smee.Security.Xmlsec1)
  end

  ################################################################################


end