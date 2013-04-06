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
        rss.channel.title       = title
        rss.channel.description = description
        rss.channel.updated     = Time.now.to_s
        rss.channel.author      = "HN2RSS"

        @news.each do |news|
          news = news['item']
          rss.items.new_item do |item|
            item.title       = news['title']
            item.link        = news['url'] || ""
            item.description = "#{news['points']} points"
            item.updated     = news['create_ts']
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

    def count
      @news.count
    end

    def filename
      File.expand_path("../../site/#{HN2RSS.minimum_points}.atom", __FILE__)
    end
  end
end

