require 'test/unit'
require_relative 'film'
require_relative 'imdb_get'
require_relative 'moviedb_get'

class TestFilmGet < Test::Unit::TestCase

    def test_parse_imdb_film_from_json
        id = 'tt0075148'
        rocky_film = ImdbFilmGet.new(id)
        assert_equal('Rocky', rocky_film.title)
        assert_equal('1976', rocky_film.year)
    end

    def test_parse_movie_db_film_from_json
        id = '1366'
        rocky_film = MovieDbFilmGet.new(id)
        assert_equal('Rocky', rocky_film.title)
        assert_equal('1976', rocky_film.year)
    end
    
#    def test_get_film_details
#        title = 'rocky'
#        url = "http://imdbapi.org/?title=#{title}&type=json&plot=simple&episode=1&limit=1&yg=0&mt=none&lang=en-US&offset=&aka=simple&release=simple&business=0&tech=0"
#        rocky_film = MovieDbFilm.new(url)
#        assert_equal('Rocky - 1976', rocky_film.get_film_details)
#    end
end

