SCHEDULER.every '1m', first_in: 0 do
  puts 'Updating meters...'
  bernard = Bernard::Client.new
  bernard.update_meters
end

SCHEDULER.every '60m', first_in: 0 do
  puts 'Updating graphs...'
  bernard = Bernard::Client.new
  bernard.update_graphs
end

SCHEDULER.every '60m',first_in: 0 do
  puts 'Updating lists...'
  bernard = Bernard::Client.new
  bernard.update_lists
end
