helpers do
  def search_by_title(title)
    title = "%#{title}%" 
    result = {}
    result[:songs] = Song.paginate(:page => params[:page],
                      :per_page   => 20,
                      :conditions => { :title.like => title })
    result[:size] = Song.all(:title.like => title).length
    result
  end

  def search_by_artist(artist)
    artist = "%#{artist}%" 
    result = {}
    result[:songs] = Song.paginate(:page => params[:page],
                      :per_page   => 20,
                      :conditions => { :artist.like => artist })
    result[:size] = Song.all(:artist.like => artist).length
    result
  end

  def search_by_genre(genre)
    genre = "%#{genre}%"
    result = {}
    result[:songs] = Song.paginate(:page => params[:page],
                      :per_page   => 20,
                      :conditions => { :genre.like => genre })
    result[:size] = Song.all(:genre.like => genre).length
    result
  end

  def logged_in?
    request.cookies["user"] && (not request.cookies["user"].empty?)
  end

  def current_user
    User.get(request.cookies["user"].to_i)
  end

  def log_in(email)
    response.set_cookie "user", :value => @user.id, :domain => "", :path => "/"
    response.set_cookie "songs", :value => @user.songs, :domain => "", :path => "/"
  end

  def set_songs(arr)
    songs = arr.uniq.join(",")
    response.set_cookie "songs", :value => songs, :domatin => "", :path => "/"
    current_user.update(:songs => songs) if logged_in?
  end

  def get_songs
    if logged_in?
      current_user.songs.split(",")
    else
      request.cookies["songs"] ? request.cookies["songs"].split(",") : []
    end
  end

  def log_out
    response.set_cookie("user", :value => nil, :path => "/", :domain => "")
    response.set_cookie("songs", :value => nil, :path => "/", :domain => "")
  end

  def seperate_genre
    genre_hash = {}
    genre_list = Song.all.map{|song| song.genre.split("/")}.uniq
    genre_list.each do |lis|
      if genre_hash[lis[0]]
        first = lis.shift
        genre_hash[first] += lis
        genre_hash[first] = genre_hash[first].uniq
      else
        genre_hash[lis.shift] = lis
      end
    end
    genre_list = []
    genre_hash.each{|k, v| genre_list << [k, v].flatten}
    genre_list
  end
end
