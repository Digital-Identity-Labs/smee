
defimpl String.Chars, for: Smee.Entity do
  @moduledoc false
  def to_string(s), do: "#[Entity #{s.uri}]"
end

defimpl String.Chars, for: Smee.Metadata do
  @moduledoc false
  def to_string(s), do: "#[Metadata #{s.url}]"
end

defimpl String.Chars, for: Smee.Source do
  @moduledoc false
  def to_string(s), do: "#[Source #{s.url}]"
end