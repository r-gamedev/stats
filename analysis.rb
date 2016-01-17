require 'yaml'
require './util'
require './reddscan'

def load_data dir
  Dir["stats/#{dir}/*"].map do |filename|
    YAML.load_file filename
  end
end

$reddscan = ReddScan.new(Util.load_conf(), logger: $stdout);
#$week = $reddscan.scan_top :week
week_data = load_data "week"

res = {}

week_data.reverse.each { |d|
  d[:data].select { |i|
    i[:stats][:category]=="Question"
  }.each { |i|
    res[i[:info][:fullname]] ||= {
      title: i[:info][:title],
      url: i[:info][:url],
      score: i[:stats][:score]
    }
  }
}

res = res.map { |k,v|
  v
}.sort { |a,b| 
  a[:score] <=> b[:score]
}

File.open("analysis.md", "wb") do |out|
  out << "| Score | Title |\n"
  out << "|-------|-------|\n"
  res.each do |i|
    out << "| #{i[:score]} | [#{i[:title]}](#{i[:url]})|\n"
  end
end

binding.pry
