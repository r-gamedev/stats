require 'yaml'

class Util
  CONF_FILE = "./conf.yaml"
  BOT_NAME = "ghost-of-gamedev"
  BOT_VERSION = "0.0.1"
  BOT_OWNER = "lemtzas"
  class << self
    def yamldump(file,yaml)
      File.open(file,'w') { |f|f.write(YAML.dump(yaml))}
    end

    def save_conf()
      yamldump(CONF_FILE,@@o)
    end

    def load_conf()
      if File.exist?(CONF_FILE) then
        @@o = YAML.load_file(CONF_FILE)
        return @@o
      else
        @@o = {}
        @@o["username"] ||= "USERNAME_HERE"
        @@o["password"] ||= "PASSWORD_HERE"
        @@o["client_id"] ||= "Hj8EM025J_R0vw"
        @@o["client_secret"] ||= "SJrDMiQvrqlaOrCS4eh1hpoRF14"
        @@o["useragent"] ||= "#{BOT_NAME} v#{BOT_VERSION} by /u/#{BOT_OWNER}"
        @@o["from"] ||= "FROM_WHERE?"
        @@o["to"] ||= "TO_WHERE"
        @@o["twitter"] ||= {}
        @@o["twitter"]["consumer_key"] = "eyW5jGGS7auKYPplGcIXHXmEl"
        @@o["twitter"]["consumer_secret"] = "uRWruO6mucq10zkxNwxUR9isui2eSCxNBrWk3qzUmzIQrVf5Hr"
        @@o["twitter"]["access_token"] = "TOKEN_HERE"
        @@o["twitter"]["access_token_secret"] = "TOKEN_SECRET_HERE"
        save_conf
        puts "conf file created at '#{CONF_FILE}' - please edit before continuing"
        exit
      end
    end
  end
end

def cpp(string, indent: 0, width: 100)
  result = string.lines.collect do |split|
    r = split.scan(/(?:.{1,#{width-indent}}(?: |$)|.+)/)
    if not r.empty? then
      r
    else
      split
    end
  end
  result.flatten!
  result.collect! {|s| (" "*indent) + s }
  puts result
end

def cpp2(i)
  string = (i[:text] or "")
  indent = (i[:indent] or 0)
  width = (i[:width] or 100)
  cpp(string, indent: indent, width: width)
end