#encoding:utf-8


class Update

  def self.Update.get_new_titles_no_thread
    urls = ["http://joysound.com/ex/st/wii/parts/add_ichiran.htm", "http://joysound.com/ex/st/wii/parts/new_ichiran.htm"]
    title = []
    urls.each do |url|
      html = Nokogiri::HTML(open(url))
      title += html.css(".music").map{|title| title.text}
    end
    title
  end 
  def self.get_new_titles
    urls = ["http://joysound.com/ex/st/wii/parts/add_ichiran.htm", "http://joysound.com/ex/st/wii/parts/new_ichiran.htm"]
    semaphore = Mutex.new
    titles = []
    threads = urls.map do |url| 
      Thread.new(url, semaphore){ |url, semaphore|
        html = Nokogiri::HTML(open(url)) 
        semaphore.synchronize {
          titles += html.css(".music").map{|title| title.text}   
        }
      } 
    end
    threads.map(&:join)
    titles
  end

  def self.search_and_save_title(title)
    search_url = "http://joysound.com/ex/search/songsearchword.htm?wiiall=1&searchType=01&searchWord=#{CGI::escape(title)}&searchWordType=2&searchLikeType=3"
    parsed = Nokogiri::HTML(open(search_url))
    links = parsed.css(".wii a").map do |link|
      "http://joysound.com" + link.attribute("href")
    end
    links.each{|link| self.save_data_from_page(link)}
  end

  def self.save_data_from_page(url)
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
    res = {:title => title, :artist => artist, :wii_number => number, :genre => genre, :utaidashi => utaidashi}
    song = Song.first_or_create(res)
    puts song
  end

  def self.update_songDB
    titles = self.get_new_titles_no_thread
    titles.each do |title|
      self.search_and_save_title(title)
    end
  end

end


