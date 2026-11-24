#!/usr/bin/env elixir
Mix.install([:bandit, {:smee, path: "./"}])

defmodule Router do

  alias Smee.XMLProcessor

  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/" do
    send_resp(
      conn,
      200,
      """
      ## A simple Smee XML Processor HTTP service
      
      XML processing endpoints are at:
      
        /tidy
        /well_formed
        /validate
        /list_ids
        /extract_entity/:entity_id
    
      POST raw XML in the body of the HTTP request with a content type of text/xml.
      URL encode the entityID of the requested entity and pass as a path component.
    
      This is for testing and demonstration purposes only!
    
      """
    )
  end

  post "/tidy" do
    {:ok, xml, conn} = Plug.Conn.read_body(conn, length: 200_000_000)
    case XMLProcessor.tidy(xml) do
      {:ok, tidy_xml} -> send_resp(conn, 200, tidy_xml)
      {:error, msg} -> send_resp(conn, 200, msg)
    end
  end

  post "/well_formed" do
    {:ok, xml, conn} = Plug.Conn.read_body(conn, length: 200_000_000)
    case XMLProcessor.well_formed(xml) do
      {:ok, _} -> send_resp(conn, 200, "OK")
      {:error, msg} -> send_resp(conn, 200, msg)
    end
  end

  post "/validate" do
    {:ok, xml, conn} = Plug.Conn.read_body(conn, length: 200_000_000)
    case XMLProcessor.validate(xml) do
      {:ok, _} -> send_resp(conn, 200, "OK")
      {:error, msg} -> send_resp(conn, 200, msg)
    end
  end

  post "/style" do
    send_resp(conn, 501, "Not Implemented")
  end

  post "/cert" do
    send_resp(conn, 501, "Not Implemented")
  end
  
  post "/verify" do
    send_resp(conn, 501, "Not Implemented")
  end

  post "/sign" do
    send_resp(conn, 501, "Not Implemented")
  end

  post "/transform" do
    send_resp(conn, 501, "Not Implemented")
  end

  post "/list_ids" do
    {:ok, xml, conn} = Plug.Conn.read_body(conn, length: 200_000_000)
    #    case XMLProcessor.list_ids(xml) do
    #      {:ok, ids} -> send_resp(conn, 200, Jason.encode!(ids))
    #      {:error, msg} -> send_resp(conn, 200, msg)
    #    end

    ids = XMLProcessor.list_ids(xml)
    send_resp(conn, 200, Jason.encode!(ids))
    
  end

  post "/extract_entity/:entity_id" do
    {:ok, xml, conn} = Plug.Conn.read_body(conn, length: 200_000_000)
    case XMLProcessor.extract_entity(xml, entity_id) do
      {:ok, entity_xml} -> send_resp(conn, 200, entity_xml)
      {:error, msg} -> send_resp(conn, 200, msg)
    end
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

end

require Logger
webserver = {Bandit, plug: Router, scheme: :http, port: 4000}
{:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
Logger.info("Plug now running on localhost:4000")
Process.sleep(:infinity)
