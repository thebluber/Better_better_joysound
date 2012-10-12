#encoding:utf-8
class Keyword
  include DataMapper::Resource

  property :id, Serial
  property :keyword, String

  has n, :songs, :through => Resource
end

