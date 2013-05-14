require_relative 'film'

class MovieDbFilmGet < Film

  def initialize(id)
    json_url = "http://api.themoviedb.org/3/movie/#{id}i?api_key=61a8fcb885ddad6d5967a2204f3e231c"
    resp = Net::HTTP.get_response(URI.parse(json_url))
    json_data = resp.body
    json_hash = JSON.parse(json_data)
    json_url_cast = "http://api.themoviedb.org/3/movie/#{id}/casts?api_key=61a8fcb885ddad6d5967a2204f3e231c"
    resp_cast = Net::HTTP.get_response(URI.parse(json_url_cast))
    json_data_cast = resp_cast.body
    json_hash_cast = JSON.parse(json_data_cast)
    @title = json_hash['title']
    @year = json_hash['release_date'][0..3]
    @plot = json_hash['overview']
    @imdb_id = json_hash['imdb_id']
    @actors = [] 
    @id = json_hash['id']                  
    if json_hash_cast['cast']
      json_hash_cast['cast'].each {|actor|
        puts "#{actor['name']}, #{actor['character']}"
        actor_hash = { :name => actor['name'], 
                       :role => actor['character'], 
                       :order => actor['order'] 
        } 
        @actors.push(actor_hash)
      }
      @actors = @actors.sort_by {|v| v[:order]} #not working
    end
    @genre = []
    if json_hash['genres']
      json_hash['genres'].each {|genre|
        @genre << genre['name']
      }
    end
    @tagline = json_hash['tagline']
    @runtime = json_hash['runtime'] 
  end

end

