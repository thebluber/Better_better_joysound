#encoding:utf-8
class User
  include DataMapper::Resource
  property :id, Serial
  property :email, String
  property :songs, Text
end

