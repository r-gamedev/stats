require 'redd'
require 'redcarpet'
require 'redcarpet/render_strip'
require 'htmlentities'
require 'pry'
require 'andand'
require 'yaml/store'
require 'descriptive_statistics'

require './util'

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
    end until top.count < 100
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


$stdout.sync = true
config = Util.load_conf()

reddscan = ReddScan.new(config, logger: $stdout)


# maps a Redd post into something more convenient
def map (post)
  {
    stats: {
      score: post.score,
      comments: post.num_comments,
      category: post.link_flair_text,
      category_css: post.link_flair_css_class,
      gilded: post.gilded,
    },
    info: {
      title: post.title.andand.gsub(/\W+/, ' '),
      fullname: post.fullname,
      url: post.url,
      created: post.created,
      editd: post.edited,
      author_flair: {
        text: post.author_flair_text.andand.gsub(/\W+/, ' '),
        #css: post.author_flair_css_class
      },
      link_flair: {
        text: post.link_flair_text,
        css: post.link_flair_css_class
      }
    }
  }
end

# posts: the full list of posts in the above format
def all_stats (posts)
  categories = posts.map { |p| p[:stats][:category] }.uniq
  stats = {
    general: sub_stats(posts),
    by_category: {}
  }
  categories.each do |category|
    posts_in_category = posts.select { |p| p[:stats][:category] == category }
    stats[:by_category][category] = sub_stats(posts_in_category)
  end
  stats
end

def sub_stats (posts)
  stats = {
    scores: 0,
    comments: 0
  }
  stats[:count] = posts.count
  scores = posts.map { |p| p[:stats][:score] }
  comments = posts.map { |p| p[:stats][:comments] }
  stats[:scores] = restricted_stats(scores)
  stats[:comments] = restricted_stats(comments)
  stats
end

def restricted_stats (scores)
  {
    min: scores.min,
    q1: scores.percentile(25),
    q2: scores.percentile(50),
    q3: scores.percentile(75),
    max: scores.max,
    mean: scores.mean,
    sum: scores.sum
  }
end

# retrieves, scans, and stores posts
#label: included in the filename
#period: :hour, :day, :week, :month, :year, :all
#block used to generate stats
def scan_and_store_with_stats (
    label,
    period,
    logger: File.open(File::NULL, "w"),
    reddscan: nil)

  time = Time.now
  time_local = time.to_s
  time_utc = time.utc.to_s
  time.utc # time is UTC now
  time_label = time.strftime("%Y%m%d_%H%M")
  filename = "stats/#{label}/#{time_label}.store.yaml"
  meta = {
      time_utc: time_utc,
      time_local: time_local,
      label: label,
      period: period
    }

  logger.puts "### Label: '#{label}' - '#{period}' ###"
  logger.puts "# Time: #{time_local}"
  logger.puts "# Scanning"
  data = reddscan.scan_top(period) do |post|
    map(post)
  end

  logger.puts "# Generating stats"
  if block_given?
    stats = yield data
  end

  Dir.mkdir "stats" unless Dir.exist? "stats"
  Dir.mkdir "stats/#{label}" unless Dir.exist? "stats/#{label}"
  logger.puts "# Dumping to `#{filename}`"
  store = YAML::Store.new filename
  store.transaction do
    store[:meta] = meta
    store[:stats] = stats
    store[:data] = data
  end
end

{ "24h": :day ,
  "week": :week,
  "month": :month,
  "year": :year,
  "all": :all }.each do |key, value|

    scan_and_store_with_stats(
        key, value,
        logger: $stdout,
        reddscan: reddscan) do |posts|
      all_stats(posts)
    end

end
