require 'yaml'
require 'pry'
require './util'
require './reddscan'

def load_data dir
  Dir["stats/#{dir}/*"].map do |filename|
    YAML.load_file filename
  end
end

$reddscan = ReddScan.new(Util.load_conf(), logger: $stdout);
#$week = $reddscan.scan_user "lemtzas"
#week_data = load_data "week"

binding.pry