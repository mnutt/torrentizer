#!/usr/bin/env ruby

ROOT = File.expand_path(File.join(File.dirname(__FILE__),".."))

url = ARGV[0]
hash = ARGV[1]
torrent_path = "#{ROOT}/public/made/#{hash}.torrent"

def download_file(url, hash)
  puts "Downloading #{url}"
    
  `mkdir -p /tmp/source/#{hash}`

  original_filename = get_original_filename(url)
  if original_filename
    puts `cd /tmp/source/#{hash} && curl -L '#{url.gsub("'", "")}' > #{original_filename}`
  else
    puts `cd /tmp/source/#{hash} && curl -L -O '#{url.gsub("'", "")}'`
  end

  tmp_file  = `find /tmp/source/#{hash} | tail -n 1`.strip
  raise "File not downloaded" if tmp_file.nil? || tmp_file == ""
  tmp_file
end

def get_original_filename(url)
  curl_output = `curl -L -I '#{url.gsub("'", "")}'`
  headers = curl_output.split(/[\r\n]/)
  puts headers.inspect
  content_types = headers.select{|h| h =~ /^Content-Type/}
  @content_type_from_http = content_types.empty? ? '' : content_types.last.split(": ").last rescue nil
  file_name_from_http = filename_from_http_content_disposition(headers)
  file_name_from_http || filename_from_http_location(headers)
end

def filename_from_http_content_disposition(headers)
  disposition = headers.select{|h| h =~ /^Content-Disposition/}.last || ""
  disposition =~ /filename=\"([^\"]+)\"/
  $1
rescue
  nil
end

def filename_from_http_location(headers)
  location = headers.select{|h| h =~ /^Location/}.last || ""
  File.basename(location.split(": ").last)
rescue
  nil
end

def cleanup(hash)
  `rm -R /tmp/sources/#{hash}`
end

def make_torrent(original, hash, url)
  clean_url = url.gsub("'", "")
  options = [ "-c \"Made by Sideloader\"",
	      "-a http://tracker.openbittorrent.com:80/announce",
              "-w '#{clean_url}'",
              "-o #{ROOT}/public/made/#{hash}.torrent" ]
  `#{ROOT}/vendor/mktorrent/mktorrent #{options.join(' ')} #{original}`
end

begin
  original = download_file(url, hash)
  make_torrent(original, hash, url)
ensure
  cleanup(hash)
end
