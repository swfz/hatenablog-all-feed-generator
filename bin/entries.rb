#!/usr/bin/env ruby

# ruby bin/entries.rb hoge example.com

require 'awesome_print'
require 'active_support/core_ext/hash'
require 'oga'
require 'json'
require 'oauth'
require 'date'

module Hatena
  class API
    attr_reader :client, :header

    def initialize(site)
      unless (ENV['HATENABLOG_CONSUMER_KEY'] && ENV['HATENABLOG_CONSUMER_SECRET'] )
        p 'Not Found environment [HATENABLOG_CONSUMER_KEY|HATENABLOG_CONSUMER_SECRET]'
        exit 1
      end
      unless (ENV['HATENABLOG_ACCESS_TOKEN'] && ENV['HATENABLOG_ACCESS_TOKEN_SECRET'] )
        p 'Not Found environment [HATENABLOG_ACCESS_TOKEN|HATENABLOG_ACCESS_TOKEN_SECRET]'
        exit 1
      end

      @header = {
          'Accept' => 'application/xml',
          'Content-Type' => 'application/xml'
      }

      consumer = OAuth::Consumer.new(
          ENV['HATENABLOG_CONSUMER_KEY'],
          ENV['HATENABLOG_CONSUMER_SECRET'],
          site: site,
          timeout: 300
      )

      @client = OAuth::AccessToken.new(
          consumer,
          ENV['HATENABLOG_ACCESS_TOKEN'],
          ENV['HATENABLOG_ACCESS_TOKEN_SECRET']
      )
    end
  end
end

USERNAME    = ARGV[0]
BLOG_DOMAIN = ARGV[1]
SITE_TITLE = '' # サイトタイトル
SITE_DESCRIPTION = '' # サイト説明
SITE_URL = '' # e.g.) https://swfz.hatenablog.com/

hatena = Hatena::API.new('http://blog.hatena.ne.jp')
first_url = "https://blog.hatena.ne.jp/#{USERNAME}/#{BLOG_DOMAIN}/atom/entry"

json = []

def merge_json(hatena, json, request_url)
  res = hatena.client.request(:get, request_url, hatena.header)
  doc = Oga.parse_xml(res.body)

  next_page = doc.at_xpath('//link[@rel="next"]').try(:get, 'href')

  entries = doc.xpath('//entry').map do |entry|
    url = entry.at_xpath('./link[@rel="alternate"]').get('href')
    categories = entry.xpath('./category').map do |node|
      node.attributes.select { |a| a.name == 'term' }.first.value.force_encoding('UTF-8')
    end
    id = entry.at_xpath('./id').text.split('-').last

    {
      title: entry.at_xpath('./title').text.force_encoding('UTF-8'),
      link: url,
      description: entry.at_xpath('./summary').text.force_encoding('UTF-8'),
      published: entry.at_xpath('./published').text,
      guid: "hatenablog://entry/#{id}",
      categories: categories,
      # はてなのRSSでは存在したが、API経由で取得できなそうだったのでいったんなし
      # enclosure: '',
      draft: entry.at_xpath('./app:control/app:draft').text
    }
  end
  p "entries: #{entries.size}"

  json.push(entries)
  merge_json(hatena, json, next_page) unless next_page.nil?
end

def format_row(row)
  categories = row[:categories].map { |c| "<category>#{c}</category>" }.join("\n")

  <<-XML
    <item>
      <title>#{row[:title]}</title>
      <link>#{row[:link]}</link>
      <description>#{CGI.escape_html(row[:description])}</description>
      <pubDate>#{DateTime.parse(row[:published]).strftime('%a, %d %b %Y %H:%M:%S %z')}</pubDate>
      <guid isPermalink="false">#{row[:guid]}</guid>
      #{categories}
    </item>
  XML
end

def format(rows)
  items = rows.map { |row| format_row(row) }.join("\n")
  <<-XML
    <?xml version="1.0"?>
    <rss version="2.0">
      <channel>
        <title>#{SITE_TITLE}</title>
        <link>#{SITE_URL}</link>
        <description>#{SITE_DESCRIPTION}</description>
        <lastBuildDate>#{DateTime.now.strftime('%a, %d %b %Y %H:%M:%S %z')}</lastBuildDate>
        <docs>http://blogs.law.harvard.edu/tech/rss</docs>
        <generator>Hatena::Blog</generator>
        #{items}
      </channel>
    </rss>
  XML
end

merge_json(hatena, json, first_url)

xml = format(json.flatten.reject { |row| row[:draft] == 'yes' }.sort_by { |row| row[:published] }.reverse!)
File.write('rss.xml', xml)
