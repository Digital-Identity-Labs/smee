defmodule Smee.Utils do

  def sha1(data) do
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
  end

end
