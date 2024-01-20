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

  @spec xmlsec1_modern?() :: boolean()
  def xmlsec1_modern?() do
    Application.get_env(:smee, :xmlsec1_modern, false)
  end

  @spec cache_directory() :: binary()
  def cache_directory() do
    Application.get_env(:smee, :cache_dir, default_cache_directory())
  end

  @spec default_cache_directory() :: binary()
  def default_cache_directory() do
    :filename.basedir(:user_cache, "smee")
  end

  ################################################################################



end