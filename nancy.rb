require "rack"

module Nancy
  class Base
    def initialize
      @routes = {}
    end

    attr_reader :routes
    attr_reader :request

    def get(path, &handler)
      route("GET", path, &handler)
    end

    def post(path, &handler)
      route("POST", path, &handler)
    end

    def put(path, &handler)
      route("PUT", path, &handler)
    end

    def patch(path, &handler)
      route("PATCH", path, &handler)
    end

    def delete(path, &handler)
      route("DELETE", path, &handler)
    end

    def call(env)
      @request = Rack::Request.new(env)
      verb = @request.request_method
      requested_path = @request.path_info

      handler = @routes.fetch(verb, {}).fetch(requested_path, nil)

      if handler
        result = instance_eval(&handler)
        if result.class == String
          [200, {}, [result]]
        else
          result
        end
      else
        [404, {}, ["Oops! No rote for #{verb} #{requested_path}"]]
      end

    end

    def params
      @request.params
    end

    private

    def route(verb, path, &handler)
      @routes[verb] ||= {}
      @routes[verb][path] = handler
    end
  end

  Application = Base.new

  module Delegator
    def self.delegate(*methods, to:)
      Array(methods).each do |method_name|
        define_method(method_name) do |*args, &block|
          to.send(method_name, *args, &block)
        end

        private method_name
      end
    end

    delegate :get, :patch, :put, :post, :delete, :head, to: Application
  end
end

include Nancy::Delegator

get "/hello" do
  "Nancy says hello"
end

get "/" do
  "Your params #{params.inspect}"
end

post "/" do
  request.body.read
end

get "/bare-get" do
  "Whoa, it works!"
end

Rack::Handler::WEBrick.run nancy_application, Port: 9292
