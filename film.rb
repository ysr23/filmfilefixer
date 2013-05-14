require 'json'
require 'net/http'

class Film
  attr_accessor :source
  attr_accessor :title
  attr_accessor :year
  attr_accessor :plot
  attr_accessor :id
  attr_accessor :imdb_id
  attr_accessor :actors
  attr_accessor :genre
  attr_accessor :director
  attr_accessor :writer

  def get_film_details
    "#{title} - #{year}"
  end

end

