#
# Example:
#
# TIQ_EXPORT_DIR='export' TIQ_START='2013-01-01' TIQ_END='2014-12-31' TIQ_HOST='...' TIQ_API_KEY='...' TIQ_API_SECRET='...' ruby export.rb
#
#

require 'rubygems'
require 'tempoiq'
require 'json'
require 'csv'
require 'fileutils'
require 'time'

export_dir = ENV['TIQ_EXPORT_DIR']
start_on = Time.parse(ENV['TIQ_START'])
end_on = Time.parse(ENV['TIQ_END'])

tiq = TempoIQ::Client.new(ENV['TIQ_API_KEY'], ENV['TIQ_API_SECRET'], ENV['TIQ_HOST'])

tiq.list_devices.each do |device|
  puts "Exporting [#{device.name}]: #{device.key}"

  meta_file = File.join(export_dir, device.key, 'meta.json')
  data_file = File.join(export_dir, device.key, 'data.csv')

  FileUtils.mkdir_p(File.dirname(meta_file))
  File.open(meta_file, 'w') do |f|
    f.puts device.to_json
  end

  CSV.open(data_file, 'w') do |csv|
    csv << %w[timestamp value]
    cursor = tiq.read({devices: {key: device.key}, sensors: 'all'}, start_on, end_on)
    cursor.each do |row|
      values = row.values[device.key]
      values.keys.each do |key|
        csv << [row.ts, row.value(device.key, key), key]
      end
    end
  end
end