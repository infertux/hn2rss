#!/usr/bin/env ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'hn2rss'

hn = HN2RSS::HN.new
hn.limit = 20

list = ""

[250, 500, 750, 1000, 1250].each do |points|

  HN2RSS.minimum_points = points
  news = hn.fetch_news

  rss = HN2RSS::RSS.new news
  rss.dump!

  list << "<tr>" <<
  "<td><a href=\"#{rss.link}\">#{rss.title}</a></td>" <<
  "<td>#{rss.description}</td>" <<
  "<td>about #{rss.average}</td>" <<
  "</tr>"

  puts points

end

template = File.open(File.expand_path("../../site/index.template.html", __FILE__), 'r').read

File.open(File.expand_path("../../site/index.html", __FILE__), 'w') do |index|
  index.puts template.sub("<!-- LIST -->", list)
end

