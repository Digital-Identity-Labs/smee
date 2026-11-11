defmodule Smee.Behaviours.XMLProcessorBackend do
  
  @callback  tidy(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  well_formed(xml :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  validate(xml :: binary(), schema :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  verify(xml :: binary(), certificates :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  sign(xml :: binary(), certificate :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  transform(xml :: binary(),  stylesheet :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  list_ids(xml :: binary(),  stylesheet :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  @callback  extract_entity(xml :: binary(),  stylesheet :: binary(), options :: keyword()) :: {:ok, binary()} | {:error, binary()}
  
end