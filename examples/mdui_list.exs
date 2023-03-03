#!/usr/bin/env elixir
Mix.install(
  [
    {:sweet_xml, "~> 0.7.3"},
    {:rambo, "> 0.0.0"},
    {:smee,  "~> 0.1.1", path: "/Users/pete/Projects/smee"},
  ]
)

"http://metadata.ukfederation.org.uk/ukfederation-metadata.xml"
|> Smee.source()
|> Smee.fetch!()
|> Smee.Extract.mdui_info()
|> Enum.each(
     fn mdui ->

       IO.puts "EntityID: #{mdui[:entity_id]}"
       IO.puts "IDP DisplayName: #{mdui[:idp_displayname]}"
       IO.puts "IDP Description: #{mdui[:idp_description]}"
       IO.puts "IDP Information URL: #{mdui[:idp_information_url]}"
       IO.puts "IDP Privacy URL: #{mdui[:idp_privacy_url]}"
       IO.puts "SP DisplayName: #{mdui[:sp_displayname]}"
       IO.puts "SP Description: #{mdui[:sp_description]}"
       IO.puts "SP Information URL: #{mdui[:sp_information_url]}"
       IO.puts "SP Privacy URL: #{mdui[:sp_privacy_url]}"
       IO.puts "Organisation Name: #{mdui[:org_name]}"
       IO.puts "Organisation DisplayName: #{mdui[:org_displayname]}"
       IO.puts "\n"

     end
   )
