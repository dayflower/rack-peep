require "rack/peep/version"
require "rack/request"
require "rack/response"
require "rack/file"
require "securerandom"
require "json"
require "date"

module Rack
  class Peep
    Interaction = Struct.new(:id, :timestamp, :req, :req_headers, :res)

    def initialize(app, options = {})
      @app = app
      @options = options

      @path = (options[:path] || '/peep').sub(%r{/+$}, "")

      @page_size = options[:page_size] || 10

      if options[:storage]
        @storage = options[:storage]
      else
        require "rack/peep/storage/memory"
        @storage = Rack::Peep::Storage::Memory.new(page_size: @page_size)
      end

      static_root = ::File.expand_path('../../../static', __FILE__)
      @static_server = Rack::File.new(static_root)
    end

    def call(env)
      req = Rack::Request.new(env)

      if req.path_info.index(@path + '/') == 0
        return peep(env, req)
      end

      req_headers = request_headers(req)

      status, headers, body = @app.call(env)

      res = Rack::Response.new(body, status, headers)

      id = SecureRandom.uuid
      interaction = Interaction.build(id, DateTime.now, req, req_headers, res)

      @storage.add(interaction)

      [ status, headers, body ]
    end

    def peep(env, req)
      if req.path_info == @path + '/entries'
        entries = @storage.fetch(nil)[:entries]
        body = JSON.pretty_generate(entries)
        res = Rack::Response.new(body)
        res['Content-Type'] = 'application/json'
        return res
      else
        path_info = req.path_info[@path.length .. -1]
        if path_info == '/'
          path_info += 'index.html'
        end
        env['PATH_INFO'] = path_info
        return @static_server.call(env)
      end
    end

    private

    # methods about http headers don't exist on Rack 1.x
    # following methods are derived from Rack::VCR
    def request_headers(req)
      fields = req.env.select  { |k, v| k.start_with? 'HTTP_' }
                      .collect { |k, v| [ normalize_header_field(k), v ] }

      Hash[ Hash[fields].merge(
        {
          "Content-Type"   => req.content_type,
          "Content-Length" => req.content_length,
        }.reject { |k, v| v.nil? or v == "0" }
      ).sort ]
    end

    def normalize_header_field(k)
      k.sub(/^HTTP_/, '')
       .split('_').map(&:capitalize).join('-')
    end

    class Interaction
      def self.build(*params)
        self.new(*params).to_h
      end

      def to_h
        {
          id: self.id,
          timestamp: self.timestamp.iso8601,
          req: req_to_h(self.req, self.req_headers),
          res: res_to_h(self.res),
        }
      end

      private

      def req_to_h(req, headers)
        {
          method: req.request_method,
          url: req.url,
          fullpath: req.fullpath,
          headers: headers,
          content_type: req.content_type,
          content_length: req.content_length,
          query_string: req.query_string,
          query: req.GET,
          body: readable_req_param(req),
        }
      end

      def res_to_h(res)
        {
          status: res.status,
          headers: Hash[ res.headers.sort ],
          content_type: res.content_type,
          content_length: res.content_length,
          body: readable_res_body(res),
        }
      end

      def readable_req_param(req)
        if req.form_data?
          return JSON.pretty_generate(req.POST)
        elsif req.content_type == 'application/json'
          return render_json(try_read(req.body))
        end

        nil
      end

      def readable_res_body(res)
        if res.content_type == 'application/json'
          return render_json(res.body.join(""))
        end

        nil
      end

      def render_json(raw_body)
        begin
          JSON.pretty_generate(JSON.parse(raw_body))
        rescue
          nil
        end
      end

      def try_read(body)
        if body
          body.rewind
          b = body.read
          body.rewind
          b
        end
      end
    end
  end
end
