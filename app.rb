#encoding:utf-8
require "rubygems"
require "sinatra"
require 'data_mapper'
require './models/user.rb'
require './models/keyword.rb'
require './models/song.rb'
require './models/genre.rb'
require './models/joysound.rb'
require './helper/helper.rb'
require 'cgi'
enable :sessions
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:test.db")
DataMapper.auto_upgrade!
#DataMapper.auto_migrate!

get "/" do
    if !session["genre_list"]
      session["genre_list"] = seperate_genre
    end
    if params[:query] then
      params[:query].downcase!
      @results = search(params[:query])
      puts @results
    end
    @results ||= []
    @count = {:all => @results.size}
    if not get_songs.empty?
      @remembered = Song.all(:number => get_songs, :order => :artist)
      @results -= @remembered if @results
    end
    @remembered ||= []
    @count[:remembered] = @count[:all] - @results.size
    @genre_list = seperate_genre
    erb :index
end

get "/search/:genre" do
  @results = search_by_genre(CGI::unescape(params[:genre]))
    @results ||= []
    @count = {:all => @results.size}
    if not get_songs.empty?
      @remembered = Song.all(:number => get_songs, :order => :artist)
      @results -= @remembered if @results
    end
    @remembered ||= []
    @count[:remembered] = @count[:all] - @results.size
  erb :results
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
    @remembered = Song.all(:number => get_songs, :order => :artist)
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

get "/genre" do
 @genre_list = seperate_genre
 @genre_list.to_s
end
