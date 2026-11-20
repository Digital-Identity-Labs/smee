Application.put_env(:smee, :xml_processor, :uppsala)

ex_unit_opts = [
  capture_log: [
    level: :error
  ]
]

ExUnit.configure(exclude: [:compatibility, :deprecated, :examples])
ExUnit.start(ex_unit_opts)
