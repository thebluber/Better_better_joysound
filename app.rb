#encoding:utf-8
require "rubygems"
require "sinatra"
require 'data_mapper'
require './models/user.rb'
require './models/keyword.rb'
require './models/song.rb'
require './models/joysound.rb'
require './helper/helper.rb'
require 'cgi'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite:test.db")
DataMapper.auto_upgrade!
#DataMapper.auto_migrate!

get "/" do
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
    erb :index
end

