#encoding:utf-8
require "rubygems"
require "sinatra"
require 'data_mapper'
require './models/user.rb'
require './models/song.rb'
require 'cgi'
require 'will_paginate'
require 'will_paginate/data_mapper'
require "will_paginate-bootstrap"
require './helper/helper.rb'
require "open-uri"
require "nokogiri"
require "./update.rb"
enable :sessions
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:songs.db")
DataMapper.auto_upgrade!
#DataMapper.auto_migrate!


get "/" do
    if params[:query] then
      params[:query].downcase!
      if params[:kind] == "title"
        result = search_by_title(params[:query]) 
        @results = result[:songs]
        @results_size = result[:size]
      elsif params[:kind] == "artist"
        result = search_by_artist(params[:query]) 
        @results = result[:songs]
        @results_size = result[:size]
      end
      puts @results
    end
    @results ||= []
    @results_size ||= 0
    @count = {:all => @results_size}
    if not get_songs.empty?
      @remembered = Song.all(:wii_number => get_songs, :order => :artist)
      if @results
      #  @results -= @remembered
        @results_size -= @remembered.length
      end
    end
    @remembered ||= []
    @count[:remembered] = @count[:all] - @results_size
    erb :index
end

get "/search/:genre" do
  result = search_by_genre(CGI::unescape(params[:genre]))
  @results = result[:songs]
  @results_size = result[:size]
    @results ||= []
    @results_size ||= 0
    @count = {:all => @results_size}
    if not get_songs.empty?
      @remembered = Song.all(:wii_number => get_songs, :order => :artist)
      if @results
      #  @results -= @remembered
        @results_size -= @remembered.length
      end
    end
    @remembered ||= []
    @count[:remembered] = @count[:all] - @results_size
  erb :index
end

get "/user" do
  @users = User.all
  erb :users
end

get "/user/new" do
  erb :new_user
end

post "/user/logout" do
  log_out
  redirect to "/"
end

post "/user/new" do
  @user = User.first(:email => params[:email])
  if not @user
    @user = User.create(:email => params[:email], :songs => request.cookies["songs"] || "")
  end
  log_in(params[:email])
  redirect to "/"
end

get "/remembered" do
  if not get_songs.empty?
    @remembered = Song.all(:wii_number => get_songs, :order => :artist)
  end
  erb :remembered
end

post "/song/:id/remember" do
  songs = get_songs.push(params[:id])
  set_songs(songs)
  !request.xhr? ? redirect(back) : "Remembered!"
end

post "/song/:id/forget" do
  songs = get_songs
  songs = songs.reject{|el| el == (params[:id])}
  set_songs(songs)
  !request.xhr? ? redirect(back) : "Forgotten!"
end

get "/song/txt" do
  attachment("joysound.txt")
  @remembered = Song.all(:wii_number => request.cookies["songs"].split(","))
  @remembered.map{|song| "#{song.artist} - #{song.title}: #{song.wii_number}"}.join("\n")
end


get "/genre" do
 @genre_list = seperate_genre
 @genre_list.to_s
end

