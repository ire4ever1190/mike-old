require "kemal"

logging false

get "/" do
  "Hello World!"
end

get "/person/:name" do |env|
    name = env.params.url["name"]
    "Hello #{name}"
end

Kemal.config.port = 8080
Kemal.run
