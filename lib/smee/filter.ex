defmodule Smee.Filter do

  alias Smee.Entity

  import SweetXml

#  def xpath(enum, xpath, value) do
#    enum |> Stream.filter(fn e -> xpath(e.xdoc, xpath) == value end)
#  end

  def uri(enum, uris, bool \\ true) when is_list(uris) do
    enum |> Stream.filter(fn e -> (Enum.member?(uris, e.uri)) == bool end)
  end

  def uri(enum, uri, bool ) do
    enum |> Stream.filter(fn e -> (e.uri == uri) == bool end)
  end

  def idp(enum, bool \\ true) do
    enum |> Stream.filter(fn e -> Entity.idp?(e) == bool end)
  end

  def sp(enum, bool \\ true) do
    enum |> Stream.filter(fn e -> Entity.sp?(e) == bool end)
  end

  def trustiness(enum, trustiness \\ 0.7, bool \\ true) do
    enum |> Stream.filter(fn e -> (Entity.trustiness(e) >= trustiness) == bool end)
  end

  
#  def aa(enum, bool) do
#
#  end


  ################################################################################


end
