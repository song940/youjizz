# encoding: UTF-8

require 'net/http'
require 'nokogiri'
require 'colorize'
require 'fileutils'
require 'tempfile'
require 'uri'
require 'json'

###
# Lsong
# i@lsong.org
# http://lsong.org
# 
# MIT LICENSE
# http://lsong.mit-license.org/
# 
# RUNTIME
# ==============
# $ ruby -v
# ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-darwin12.4.0]
#
def fetch_site
  n = 1  
  puts "index of page #{n} .".colorize(:yellow)
  site = "http://m.youjizz.com"
  until (posts_url = fetch_page(site,n)).nil?
    posts_url.each do |post_url|
      post_title = get_title_from post_url
      if File.exist?("#{post_title}/manifest.json")
        puts "already exist #{post_title}".colorize(:red)
        next
      end
      #FileUtils.rm_rf("#{post_title}")
      puts "fetch of #{post_title}".colorize(:green)

      will_download_images = []
      will_download_videos = []

      downloaded_images = []
      downloaded_videos = []

      post_images, post_videos  = fetch_images_and_videos post_url
      puts "discover #{post_images.count} images and #{post_videos.count} videos".colorize(:yellow)

      post_images.each_with_index do |image_url, index|
        image_filename = "#{post_title}_#{index + 1}#{get_ext_from image_url}"
        will_download_images << { :filename => image_filename, :url => image_url }
      end

      post_videos.each_with_index do |video_url, index|
        n = 1
        video_filename = "#{post_title}#{get_ext_from video_url}"
        while (will_download_videos.find_all{ |v| v[:filename] == video_filename }.count > 0)
          video_filename = "#{post_title}_x#{n}#{get_ext_from video_url}"
        end
        will_download_videos << { :filename => video_filename, :url => video_url }
      end

      puts "create album dir of #{post_title}".colorize(:yellow)
      FileUtils.mkdir_p("#{post_title}/preview")
      will_download_images.each_with_index do |image, index|
        puts "downloading image #{image[:filename]}".colorize(:yellow)
        image_path =  "#{post_title}/preview/#{image[:filename]}"
        download_file(image[:url], image_path) unless File.exist? image_path
        downloaded_images << image[:url] if File.exist? image_path
      end
      FileUtils.mkdir_p("#{post_title}/videos")
      will_download_videos.each_with_index do |video, index|
        puts "downloading video #{video[:filename]}".colorize(:yellow)
        video_path =  "#{post_title}/videos/#{video[:filename]}"
        download_file(video[:url], video_path) unless File.exist? video_path
        downloaded_videos << video[:url] if File.exist? video_path
      end

      files = post_images + post_videos
      failed_files = files - (downloaded_images + downloaded_videos)
      if failed_files.count > 0
        puts "download #{post_title} with  #{failed_files.count}/#{files.count} failed ".colorize(:red)
        next
      end
      puts "done , write to manifest.json".colorize(:yellow)
      manifest = { 
              :title    =>  post_title          , 
              :url      =>  post_url            ,
              :images   =>  will_download_images,
              :videos   =>  will_download_videos
            }
      
      File.open("#{post_title}/manifest.json","w") do |f|
        f.write(manifest.to_json)
      end

    end  
    puts "waiting for 3s to continue .".colorize(:blue)
    sleep 30
    n = n + 1
  end
end

def get_ext_from(res_url)
  File.extname(res_url).split('?')[0]
end

def fetch_page(site,num)
  posts_url = []
  page_url = "#{site}/page#{num}.html"
  uri = URI.parse(page_url)
  Net::HTTP.start(uri.host,uri.port) do |http|
      resp = http.get(uri.path)
      #parse xml
      doc = Nokogiri::HTML(resp.body)
      posts = doc.css('.row .preview[href^=http]')
      posts.each do |post|
        post_url =  post.attr('href')
        #now loading ...
        puts post_url
        posts_url << post_url
      end
  end
  posts_url
end

def get_title_from(post_url)
  File.basename(post_url,'.html').gsub(/-+\d+$/,'')
end


def get_video_id_from(post_url)
  /(\d+).html$/.match(post_url)[1]
end

def fetch_images_and_videos(post_url)
  images_url = []
  videos_url = []
  post_title = get_title_from post_url
  uri = URI.parse(post_url)
  Net::HTTP.start(uri.host,uri.port) do |http|
    resp = http.get(uri.path)
    doc = Nokogiri::HTML(resp.body)
    images = doc.css('#preview img')
    images.each_with_index do |image,index|
      image_url = image.attr('src')
      images_url << image_url
    end
    #mpeg4 video
    video_mp4 = doc.css('.preview_thumb').first
    videos_url << video_mp4.attr('href') unless video_mp4.nil?
  end
  #flv video
  video_id = get_video_id_from post_url
  Net::HTTP.start('www.youjizz.com') do |http|
    resp = http.get("/playlist.php?id=#{video_id}")
    doc = Nokogiri::HTML(resp.body)
    levels = doc.css('level')
    levels.each_with_index do |flv,index|
      flv_file =  flv.attr('file')
      flv_url = URI.decode flv_file
      videos_url << flv_url
    end
  end
  return images_url,videos_url
end

def download_file(from, to)
  tempfile = "#{to}.tmp"
  `wget "#{from}" -O #{tempfile}`
  FileUtils.mv(tempfile, to) if $?.to_i == 0
end

def main
  fetch_site
end

main