require 'test/unit'
require_relative 'film'
require_relative 'imdb_search'
require_relative 'moviedb_search'

class TestFilmSearch < Test::Unit::TestCase

    def test_parse_imdb_film_from_json
        title = 'rocky'
        films = ImdbFilmSearch.search(title)
        assert_equal('Rocky', films[0].title)
        assert_equal('1976', films[0].year)
    end

    def test_parse_movie_db_film_from_json
        title = 'rocky'
        films = MovieDbFilmSearch.search(title)
        assert_equal('Rocky', films[0].title)
        assert_equal('1976', films[0].year)
    end
    
end

