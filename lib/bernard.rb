require 'net/https'

if ENV['KEEN_PROJECT_ID'].nil? || ENV['KEEN_READ_KEY'].nil?
  fail 'Please set KEEN_PROJECT_ID and KEEN_READ_KEY environment variables'
end

module Bernard
  class Client
    attr_reader :project_id, :read_key

    def initialize
      @project_id = ENV['KEEN_PROJECT_ID']
      @read_key = ENV['KEEN_READ_KEY']

      @connection = get_http_connection
    end

    def update_meters
      response = fetch_counts(event_collection: 'tick', timeframe: 'this_14_day', group_by: 'type')

      response['result'].each do |tick|
        send_event("tick_#{tick['type']}", current: tick['result'])
      end
    end

    def update_graphs
      response = fetch_counts(event_collection: 'tick', timeframe: 'this_7_day', group_by: 'type', interval: 'daily')

      graphs = {}

      response['result'].each_with_index do |timeframe, i|
        timeframe['value'].each do |value|
          graphs[value['type']] ||= []

          graphs[value['type']] << { x: i, y: value['result'] }
        end
      end

      graphs.each do |name, data|
        send_event("tick_graph_#{name}", points: data, displayedValue: data.last['y'])
      end
    end

    private

    def fetch_counts(body = nil)
      request = Net::HTTP::Post.new("/3.0/projects/#{project_id}/queries/count")
      request['Authorization'] = read_key
      request['Content-Type'] = 'application/json'
      request.body = body.to_json

      response = @connection.request(request)
      JSON.parse(response.body)
    end

    def get_http_connection
      http = Net::HTTP.new('api.keen.io', 443)
      http.open_timeout = 15
      http.read_timeout = 15
      http.use_ssl = true

      http
    end
  end
end
