#encoding:utf-8
require 'nokogiri'
require 'open-uri'
#require './keyword.rb'
#the charIndex are not sequential 
#INDEX = [101-136, 138, 140-146, 148, 150-180, 188, 11-36]
class Joysound
  def self.data_from_page(url)
    parsed = nil
    while(!parsed) do
      begin
        parsed = Nokogiri::HTML(open(url))

        rescue OpenURI::HTTPError
          STDERR.puts "Waiting for #{url}..."
          sleep 0.5
      end
    end
    title, artist = parsed.css("#musicNameBlock h3").text.strip.split("／")
    number = parsed.css(".wiiTable td:nth-child(2)").text.strip[/\d+/]
    genre = parsed.css(".musicDetailsBlock tr:nth-child(2) a").text.strip
    utaidashi = parsed.css(".musicDetailsBlock tr:nth-child(3) td").text.strip

    res = {:title => title, :artist => artist, :number => number, :genre => genre, :utaidashi => utaidashi}
    res
  end

  def self.save_to_db(res)
    song = Song.first_or_create(res)
    puts song
    #self.generate_keywords(song.title, song)
    #self.generate_keywords(song.artist, song)
  end

  def self.generate_keywords(str, song)
    word = ""
    keywords = []
    str.each_char do |char|
      word += char
      keywords << word
    end
    keywords.each do |k|
       kw = Keyword.first_or_create(:keyword => k)
       puts kw
       kw.songs << song
       kw.save
    end
  end

  def self.load_links_threaded(links, n = 4)
    links = links.map{|link| link.attribute("href")}

    semaphore = Mutex.new

    links.each_slice(n) do |slice|
      threads = slice.map do |link|
        Thread.new(link, semaphore){ |url, semaphore|
           res = self.data_from_page("http://joysound.com/" + url)
           semaphore.synchronize {
             self.save_to_db(res)
             sleep 0.5
           }
        }
      end
      
      threads.map(&:join)

    end
  end

  def self.load_songs(url)
    STDERR.puts "Reading links..."
    parsed = nil
    while(!parsed) do
      begin
        parsed = Nokogiri::HTML(open(url))
        rescue OpenURI::HTTPError
        STDERR.puts "Waiting for #{url}..."
        sleep 0.5
      end
    end
    
    links = parsed.css(".wii a")
    if not links.empty?
      self.load_links_threaded(links)
    end
    if parsed.text["次の20件"] then
      link = parsed.css(".transitionLinks03 li:last-of-type a")
      STDERR.puts "Found more, reading #{link.attribute('href')}"
      self.load_songs("http://joysound.com" + link.attribute("href"))
    end
    links
  end

  def self.load_charIndex(start_n, end_n)
    basic_url = "http://joysound.com/ex/search/songsearchindex.htm?wiiall=1&searchType=02&searchWordType=1&charIndexKbn=02&charIndex1="
    indexes = []
    start_n.upto(end_n) do |index|
      indexes << index
    end
    thread_list = []
    indexes.each do |index|
      thread_list << Thread.new{
        self.load_songs(basic_url + index.to_s)
      }
    end
    thread_list.each {|x| x.join}
  end
end

