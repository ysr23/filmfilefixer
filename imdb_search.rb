require_relative 'film'

class ImdbFilmSearch 

    def self.search(title)
      title = URI.escape(title) 
      json_url = "http://www.omdbapi.com/?s=#{title}" 
      resp = Net::HTTP.get_response(URI.parse(json_url))
      json_data = resp.body
      json_hash = JSON.parse(json_data)["Search"]
      films = []
      if json_hash
        json_hash.each {|search_result|
          film  = Film.new
          film.source = "imdb"
          film.title = search_result['Title']
          film.year = search_result['Year']
          film.plot = search_result['Plot']
          film.id = search_result['imdbID']
          films << film
        }
      end
    films
    end
end
