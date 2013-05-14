require_relative 'film'

class ImdbFilmGet < Film

    def initialize(id)
      json_url = "http://www.omdbapi.com/?i=#{id}" 
      puts json_url
      resp = Net::HTTP.get_response(URI.parse(json_url))
      json_data = resp.body
      json_hash = JSON.parse(json_data)
     # if json_hash.poster
     #   Net::HTTP.start("ia.media-imdb.com") do |http|
     #     img = http.get('/wp-content/uploads/2013/02/What-is-a-MEME.jpg')
     #     open( './img.jpg', 'wb' ) { |file| file.write(img.body)}
     #   end
     # end
      @title = json_hash['Title']
      @year = json_hash['Year']
      @plot = json_hash['Plot']
      @imdb_id = json_hash['mdbID']
      @id = json_hash['imdbID'] 
      @actors = []
      json_hash['Actors'].split(',').each {|actor|
        actor_hash = { :name => actor.strip, :role => ""}
        @actors.push(actor_hash)
      }
      @role = "foo"# imdb does not provide role info
      @genre = json_hash['Genre'].split(',').collect {|x| x.strip}
      @director = json_hash['Director'].split(',').collect {|x| x.strip}
      @writer = json_hash['Writer'].split(',').collect {|x| x.strip}
      @runtime = json_hash['Runtime']
    end
end
