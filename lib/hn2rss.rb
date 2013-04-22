require 'net/http'
require 'json'
require 'rss'
require 'date'

module HN2RSS
  class << self
    attr_accessor :minimum_points
  end

  class HN
    attr_accessor :limit

    def initialize
      @limit = 20
    end

    def fetch_news
      news = Net::HTTP.get(URI.parse(endpoint))
      news = JSON.parse news
      news['results']
    end

  private

    def endpoint
      "http://api.thriftdb.com/api.hnsearch.com/items/_search" <<
      "?filter[queries][]=points%3a[#{HN2RSS.minimum_points}%20TO%20*]" <<
      "&sortby=create_ts%20desc&limit=#{@limit}".freeze
    end
  end

  class RSS
    def initialize news
      @news = news.freeze
    end

    def rss
      ::RSS::Maker.make("atom") do |rss|
        rss.channel.about       = link
        rss.channel.link        = link
        rss.channel.title       = title
        rss.channel.description = description
        rss.channel.author      = "HN2RSS"
        rss.channel.date        = Time.now

        # XXX ugly hack to be W3C compliant
        raise unless rss.channel.instance_variable_get("@links").count == 1
        rss.channel.instance_variable_get("@links").first.rel = 'self'

        @news.each do |news|
          news = news['item']
          rss.items.new_item do |item|
            item.link  = news['url'] || hn_link('item', news['id'])
            item.date  = news['create_ts']
            item.title = news['title']
            item.description = text news
            # XXX ugly hack to set description type to HTML
            item.instance_variable_get("@description").type = 'html'
          end
        end
      end.to_s
    end

    def dump!
      File.open(filename, "w") do |file|
        file.puts rss
      end
    end

    def average
      return 0 if @news.empty?

      oldest = DateTime.parse(@news.last['item']['create_ts'])
      average = count / (DateTime.now - oldest)

      if average > 1
        period = "day"
      else
        average *= 30
        period = "month"
      end

      "#{average.to_f.round(1)} news per #{period}"
    end

    def link
      "http://labs.infertux.com/hn2rss/#{HN2RSS.minimum_points}.atom"
    end

    def title
      "HN #{HN2RSS.minimum_points}"
    end

    def description
      "Last #{count} news over #{HN2RSS.minimum_points} points"
    end

  private

    def text news
      item_link = hn_link 'item', news['id']
      user_link = hn_link 'user', news['username']

      <<-TEXT
        <li>Discussion thread: <a href="#{item_link}">#{item_link}</a>
        <li>Points: #{news['points']}
        <li>Comments: #{news['num_comments']}
        <li>HN poster: <a href="#{user_link}">#{news['username']}</a>

        <p>#{news['text']}</p>
      TEXT
    end

    def hn_link resource, id
      "https://news.ycombinator.com/#{resource}?id=#{id}"
    end

    def count
      @news.count
    end

    def filename
      File.expand_path("../../site/#{HN2RSS.minimum_points}.atom", __FILE__)
    end
  end
end

