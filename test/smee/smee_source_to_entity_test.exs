defmodule SmeeSourceToEntityTest do
  use ExUnit.Case

  alias Smee.Entity

  @file_src Smee.Source.new("test/support/static/aggregate.xml")
  # |> Smee.fetch!()

  @remote_src Smee.Source.new("http://metadata.ukfederation.org.uk/ukfederation-metadata.xml")

  describe "Priority" do

    test "is passed from file Source to entities" do

      %Entity{priority: 3} = %{@file_src | priority: 3}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()

    end

    test "is passed from HTTP Source to entities" do

      %Entity{priority: 3} = %{@remote_src | priority: 3}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()

    end

  end

  describe "Local" do

    test "is passed from file Source to entities" do

      %Entity{local: true} = %{@file_src | local: true}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()

    end

    test "is passed from HTTP Source to entities" do
      %Entity{local: true} = %{@remote_src | local: true}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()
    end

  end

  describe "Bilateral" do

    test "is passed from file Source to entities" do

      %Entity{bilateral: true} = %{@file_src | bilateral: true}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()

    end

    test " is passed from HTTP Source to entities" do
      %Entity{bilateral: true} = %{@remote_src | bilateral: true}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()
    end

  end

  describe "Tags" do

    test "is passed from file Source to entities" do

      %Entity{tags: ["a", "b"]} = %{@file_src | tags: ["a", "b"]}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()

    end

    test "is passed from HTTP Source to entities" do
      %Entity{tags: ["a", "b"]} = %{@remote_src | tags: ["a", "b"]}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()
    end

  end

  describe "Fedid" do

    test "fedid is passed from file Source to entities" do

      %Entity{fedid: "example"} = %{@file_src | fedid: "example"}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()

    end

    test "fedid is passed from HTTP Source to entities" do
      %Entity{fedid: "example"} = %{@remote_src | fedid: "example"}
                             |> Smee.fetch!()
                             |> Smee.Metadata.stream_entities()
                             |> Stream.take(1)
                             |> Enum.to_list()
                             |> List.first()
    end

  end

end
