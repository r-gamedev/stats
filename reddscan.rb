require 'redd'
require 'redcarpet'
require 'redcarpet/render_strip'
require 'htmlentities'
require 'pry'
require 'andand'

class ReddScan
  attr_accessor :client
  attr_accessor :r_auth
  attr_accessor :subreddit
  attr_accessor :md
  attr_accessor :html

  def connect (config)
    client = Redd.it(
      :script,
      config['client_id'],
      config['client_secret'],
      config['username'],
      config['password'],
      user_agent: config['useragent'])
    try do
      return client, client.authorize!
    end
  end

  def initialize (config,
                  logger: File.open(File::NULL, "w"),
                  subreddit: "gamedev")
    @logger = logger
    @md = Redcarpet::Markdown.new(Redcarpet::Render::StripDown, :space_after_headers => true)
    @client, @r_auth = connect(config)
    @html = HTMLEntities.new()
    @subreddit = @client.subreddit_from_name(subreddit)
  end

  #block passed to this is used to map output
  #period: :hour, :day, :week, :month, :year, :all
  def scan_top (period)
    posts = []
    top = @subreddit.get_top(t: period, limit: 100)
    @logger.puts "Scanning Content", "Num\tLast ID"
    begin
      posts.concat top
      after = top.last.fullname
      @logger.puts "#{top.count}\t#{after}"
      top = @subreddit.get_top(t: period, limit: 100, after: after)
    end until top.count == 0
    @logger.puts "#{top.count}\tdone"

    if block_given?
      posts.map! do |post|
        yield post
      end
    end

    posts
  end



  private

    def try
      yield
    rescue Redd::Error::InvalidOAuth2Credentials
      puts $!.inspect, $@
      try{
        @r = Redd.it(:script, @o['client_id'], @o['client_secret'], @o['username'], @o['password'], user_agent: @o['useragent'])
        @r_auth = @r.authorize!
        @r.authorize!
        puts "Re-authorized"
      }
      retry
    rescue Redd::Error::RateLimited => error
      puts "Rate Limited by Reddit #{error.time}"
      sleep(error.time)
      retry
    rescue Redd::Error => error
      # 5-something errors are usually errors on reddit's end.
      puts $!.inspect
      raise error unless (500...600).include?(error.code)
      retry
    rescue Faraday::SSLError => e
      puts $!.inspect
      retry
    rescue Faraday::ConnectionFailed
      puts $!.inspect, $@
      retry
    rescue StandardError => e
      puts $!.inspect, $@
      binding.pry
    end
end