#encoding:utf-8
class Song 
  include DataMapper::Resource

  property :id,   Serial
  property :title, String, :length => 256
  property :artist, String, :length => 256
  property :number, String, :unique => true
  property :genre, String, :length => 256
  property :utaidashi, String, :length => 256

end

