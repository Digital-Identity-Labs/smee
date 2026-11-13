Application.put_env(:smee, :xml_processor, :uppsala)

ExUnit.start()

ExUnit.configure(exclude: [:compatibility, :deprecated, :examples])
