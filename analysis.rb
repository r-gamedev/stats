require 'yaml'

def load_data dir
  Dir["stats/#{dir}/*"].map do |filename|
    YAML.load_file filename
  end
end