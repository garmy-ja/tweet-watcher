#!/usr/bin/env ruby -Ku


# load library
require 'rubygems'
require 'tweetstream'
require "net/http"
require "uri"
require "pp"

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
push7appno  = conf.gets.chomp
push7apikey = conf.gets.chomp
conf.close

uri = URI.parse("https://api.push7.jp/api/v1/"+push7appno+"/send")

logging('Start: watcher bot started.')

begin

  TweetStream::Client.new.follow(462569554) do |status|
    logging("Detected tweet: #{status.text}")
    if status.user_id == 462569554 then
      logging("Push Notification executing tweet from #{status.user.id}")
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "application/json"
      payload = {
        "title" => "#{status.user.screen_name} の新しいツイートがあります", 
        "body"  => status.text, 
        "icon"  => "https://pbs.twimg.com/profile_images/1982673843/0216odakyu_twitter.jpg",
        "url"   => "https://twitter.com/#{status.user.screen_name}/status/#{status.id}",
        "apikey" => push7apikey}.to_json
      request.body = payload
      response = https.request(request)
    end
  end

ensure
  logging('Error: Daemon down.')
  fail
end
