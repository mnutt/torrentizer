require 'rubygems'
require 'sinatra'
require 'digest/sha1'

ROOT = File.expand_path(File.dirname(__FILE__))

get '/create/*' do
  url = params[:splat].join
  hash = Digest::SHA1.hexdigest url
  `#{ROOT}/script/sideload.rb '#{url.gsub("'", "")}' #{hash} &> #{ROOT}/log/get.log &`

  redirect "/made/#{hash}.torrent"
end

get '/made/:hash.torrent' do
  "come back later"
end
