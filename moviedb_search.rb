require_relative 'film'

class MovieDbFilmSearch 

  def self.search(title)
    title = URI.escape(title) 
    json_url = "http://api.themoviedb.org/3/search/movie?query=#{title}&api_key=61a8fcb885ddad6d5967a2204f3e231c"
    resp = Net::HTTP.get_response(URI.parse(json_url))
    json_data = resp.body
    json_hash = JSON.parse(json_data)["results"]
    @json_url = json_url
    films = []
    json_hash.each {|search_result|
      film = Film.new
      film.source = "moviedb"
      film.title = search_result['title']
      film.year = search_result['release_date'][0..3]
      film.plot = search_result['plot_simple']
      film.id = search_result['id']
      films << film
    }
  films
  end

end

