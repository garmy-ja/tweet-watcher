#!/usr/bin/env ruby -Ku


# load library
require 'rubygems'
require 'twitter'
require "net/http"
require "uri"
require "pp"
require 'open-uri'

# define logging script activity function
def logging( log_str )
  begin
    file = open(File.expand_path('../_log_watcher2',__FILE__),'a')
    file.print Time.now.to_s, "\t", log_str, "\n"
  STDOUT.sync = true
  print Time.now.to_s, "\t", log_str, "\n"
  STDOUT.sync = false
  ensure
    file.close
  end
end

## Initialize
# Twitter gem configuration

logging("token files : token2.conf")
conf = open(File.expand_path('../token2.conf',__FILE__),'r')
client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = conf.gets.chomp
  config.consumer_secret     = conf.gets.chomp
  config.access_token        = conf.gets.chomp
  config.access_token_secret = conf.gets.chomp
end
slackurl    = conf.gets.chomp
conf.close

uri = URI.parse(slackurl)

logging('Start: watcher bot(2) started.')

watch_words = [
  "が発生し",
  "株式会社ALE",
  "株式会社Cygames",
  "株式会社アクセルスペース",
  "株式会社アストロスケール",
  "ASTROSCALE",
  "株式会社SmartHR",
  "DATUM STUDIO株式会社",
  "株式会社マクアケ",
  "任天堂株式会社",
  "株式会社ミラティブ",
  "SHOWROOM株式会社",
  "READYFOR株式会社",
  "株式会社ispace",
  "株式会社インフォステラ",
  "株式会社鳥人間",
  "株式会社Precious Analytics"
]

begin
  client.filter(follow: "407585199, 4289920812, 2457800210") do |status|
    logging("catch new tweet from #{status.user.id}")
    watch_words.each do | watch_word |
      if status.text.match(watch_word) and (not status.text.index("RT"))
        logging("Slack post executing tweet from #{status.user.id}")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri)
        request["Content-Type"] = "application/json"
        payload = {
          "attachments" => [
            {
              "text" => "\*Tweet監視bot\* キーワード \*#{watch_word}\* にマッチするツイートがなされました。\n#{status.text}\n<https://twitter.com/#{status.user.screen_name}/status/#{status.id}|link to tweet>",
              "mrkdwn_in" => [ "text" ],
              "color"  => "warning"
            }
          ]
        }.to_json
        request.body = payload
        response = https.request(request)
      end
    end
  end

ensure
  logging('Error: Daemon down.')
  fail
end
