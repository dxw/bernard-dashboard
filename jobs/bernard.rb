require 'net/https'

if ENV['KEEN_PROJECT_ID'].nil? || ENV['KEEN_READ_KEY'].nil?
  fail 'Please set KEEN_PROJECT_ID and KEEN_READ_KEY environment variables'
end

SCHEDULER.every '1m', first_in: 0 do
  project_id = ENV['KEEN_PROJECT_ID']
  read_key = ENV['KEEN_READ_KEY']

  http = Net::HTTP.new('api.keen.io', 443)
  http.open_timeout = 5
  http.read_timeout = 5
  http.use_ssl = true

  request = Net::HTTP::Post.new("/3.0/projects/#{project_id}/queries/count")
  request['Authorization'] = read_key
  request['Content-Type'] = 'application/json'
  request.body = { event_collection: 'tick', timeframe: 'this_14_day', group_by: 'type' }.to_json

  response = http.request(request)

  JSON.parse(response.body)['result'].each do |tick|
    puts "#{tick['type']}: #{tick['result']}"
    send_event("tick_#{tick['type']}", { current: tick['result'] })
  end

  request = Net::HTTP::Post.new("/3.0/projects/#{project_id}/queries/count")
  request['Authorization'] = read_key
  request['Content-Type'] = 'application/json'
  request.body = { event_collection: 'tick', timeframe: 'this_7_day', group_by: 'type', interval: 'daily' }.to_json

  response = http.request(request)

  graphs = {}

  JSON.parse(response.body)['result'].each_with_index do |timeframe, i|
    timeframe['value'].each do |value|
      graphs[value['type']] ||= []

      graphs[value['type']] << { x: i, y: value['result'] }
    end
  end

  graphs.each do |name, data|
    puts "Updating graph #{name}"
    send_event("tick_graph_#{name}", points: data, displayedValue: data.last['y'])
  end
end
