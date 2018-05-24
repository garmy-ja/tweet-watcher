#!/usr/bin/env ruby -Ku


# load library
require 'rubygems'
require 'tweetstream'
require "net/http"
require "uri"
require "pp"
require 'nokogiri'
require 'open-uri'

# define logging script activity function
def logging( log_str )
  begin
    file = open(File.expand_path('../_log_watcher',__FILE__),'a')
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

logging("token files : token.conf")
conf = open(File.expand_path('../token.conf',__FILE__),'r')
TweetStream.configure do |config|
  config.consumer_key        = conf.gets.chomp
  config.consumer_secret     = conf.gets.chomp
  config.oauth_token         = conf.gets.chomp
  config.oauth_token_secret  = conf.gets.chomp
  config.auth_method         = :oauth
end
slackurl    = conf.gets.chomp
conf.close

uri = URI.parse(slackurl)

logging('Start: watcher bot started.')

watch_id  = 462569554
watch_id2 = 599957024

begin

  TweetStream::Client.new.follow(watch_id, watch_id2) do |status|
    if status.user.id == watch_id then
      logging("Getting status from webpage")
      sleep 30

      url = 'http://www.odakyu.jp/cgi-bin/user/emg/emergency_bbs.pl'
      html = open(url).read.encode("utf-8", "Shift_JIS")
      doc = Nokogiri::HTML(html, nil, 'utf-8')
      detail = []
      doc.css('div.left_dotline_b').each { | threeline |
        detail.push({
          "title" => threeline.search("dt").text,
          "value" => threeline.search("dd").text
        })
      }
      logging("Slack post executing tweet from #{status.user.id}")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      payload = {
        "attachments" => [
          {
            "text" => "\*鉄道運行状況通知（小田急）\* <!here> \n#{status.text}\n<https://twitter.com/#{status.user.screen_name}/status/#{status.id}|link to tweet>",
            "mrkdwn_in" => [ "text" ],
            "color"  => "warning",
            "fields" => detail
          }
        ]
      }.to_json
      request.body = payload
      response = https.request(request)
    end

    if status.user.id == watch_id2 then
      logging("Getting status from webpage")
      sleep 30

      url = 'https://www.keio.co.jp/unkou/unkou_pc.html'
      html = open(url).read.encode("utf-8", "Shift_JIS")
      doc = Nokogiri::HTML(html, nil, 'utf-8')
      situation = doc.css('p.status').text

      logging("Slack post executing tweet from #{status.user.id}")
      if ( status.text.match('平常') ) then
        slack_color = "good"
        mention_text = ""
      else
        slack_color = "warning"
        mention_text = "<!here>"
      end

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      payload = {
        "attachments" => [
          {
            "text" => "\*鉄道運行状況通知（京王）\* #{mention_text}\n#{status.text}\n<https://twitter.com/#{status.user.screen_name}/status/#{status.id}|link to tweet>",
            "mrkdwn_in" => [ "text" ],
            "color" => slack_color,
		        "fields" => [
              {
                "title" => "運行状況",
                "value" => situation
              }
            ]
          }
        ]
      }.to_json
      request.body = payload
      response = https.request(request)
    end

  end

ensure
  logging('Error: Daemon down.')
  fail
end
