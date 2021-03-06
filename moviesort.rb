#!/usr/bin/env ruby

require 'rubygems'
require 'rest-client'
require 'json'
require 'readline'
require 'optparse'
require 'yaml'
require 'streamio-ffmpeg'
require_relative 'imdb_search'
require_relative 'imdb_get'
require_relative 'moviedb_search'
require_relative 'moviedb_get'

class MovieSort

  def self.clear_dir
    # This has been put in to clear up test data - to use this would be silly. Don't.
    puts "Deleting films/.nfo files in: #{@working_directory}"
    directory_name = "MovieSort"
    @options[:types] << "*.nfo" << "*.txt"
    all_video_files = Dir.glob(@options[:types])
    # put in error handling if no files
    all_video_files.each {|mf|
      puts "Deleting #{mf}"
      File.delete(mf)  
    }
    exit
  end
  
  def self.themoviedb_lookup(type, title, year = "") 
    case type
    when "search"
     puts "Looking up themoviedb.org for: #{title}"
      search = "#{title} #{year}"
      url = "http://api.themoviedb.org/3/search/movie?query=#{search}&api_key=#{@options[:moviedb_api]}"
    when "themoviedb_by_id"
      url = "http://api.themoviedb.org/3/movie/#{title}?api_key=#{@options[:moviedb_api]}&append_to_response=releases,trailers,images"
    when "imdb_by_id"
      url = "http://www.omdbapi.com/?i=#{title}"
      puts url
    when "imdb"
      puts "Looking up imdb.com for: #{title}"
      url = imdb_lookup(title, year)
    else
      raise 'Flagrant error'
    end 
    url = URI.encode(url)
    response = RestClient.get url 
    response = JSON.parse response
  end 

  def self.build_report(filename, title, id)
    report_filename = "#{@working_directory}/report.html" 
    File.open(report_filename, 'a+') { |report| 
      if title
        report.puts "Searched: #{filename} and matched with <a href=\"www.themoviedb.org/movie/#{id}\">#{title}</a><br>"
      else
        report.puts "Nothing found for #{filename}"
      end
    }
  end

  def self.sanitize_filename(title, year)
    title.gsub!(/[^\w\s_-]+/, '')
    title.gsub!(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
    title.gsub!(/\s+/, '_')
    title << "_(#{year})"
  end 

  def self.get_cast(id)
    #http://api.themoviedb.org/3/movie/550/casts?api_key=61a8fcb885ddad6d5967a2204f3e231c
    url = "http://api.themoviedb.org/3/movie/#{id}/casts?api_key=#{@options[:moviedb_api]}"
    url = URI.encode(url)
    cast_response = RestClient.get url 
    cast_response = JSON.parse cast_response
  end

  def self.build_nfo(response_by_id)
    nfo_filename = "#{Dir.pwd}/#{response_by_id.title}.nfo"
    puts "Creating .nfo file: #{response_by_id.title}.nfo"
    #cast_response = get_cast(response_by_id.id)
    File.open(nfo_filename, 'w') { |nfo|
      nfo.puts "<movie>"
      nfo.puts "  <title>#{response_by_id.title}</title>"
      nfo.puts "  <outline>#{response_by_id.plot}</outline>"
      response_by_id.genre.each {|genre|
        nfo.puts "  <genre>#{genre}</genre>"
      }
      
      response_by_id.actors.each {|actor|
        nfo.puts "  <actor>"
        nfo.puts "      <name>#{actor[:name]}</name>"
        nfo.puts "      <role>#{actor[:role]}</role>"
      nfo.puts "  </actor>"
      }
      nfo.puts "  <id>#{response_by_id.id}</id>"
     # foo = {} 
     # i = 0
     # cast_response['cast'] .each {|cr|
     #   foo[i] = { "name" => cr['name'], "role" => cr['character'], "order" => cr['order']}
     #   i += 1
     # }
     # foo = foo.sort_by { |k,v| v['order']}
     # foo.each { |k,v|
     #   nfo.puts "  <actor>"
     #   nfo.puts "    <name>#{v['name']}</name>"
     #   nfo.puts "    <role>#{v['role']}</role>"
     #   nfo.puts "  </actor>"
     # }
     # cast_response['crew'].each {|cr|
     #   job  = cr['job'].tr(" ", "")
     #   nfo.puts "  <#{job}>#{cr['name']}</#{job}>"
     # }
      nfo.puts "</movie>"
    }
  end

  def self.rename_file(response_by_id)
    puts response_by_id
    title = response_by_id.title
    year = response_by_id.year
    id = response_by_id.id
    sanitize_filename(title, year)
    build_nfo(response_by_id)
    title_nfo = title + ".nfo"
    puts title_nfo
    title = title + File.extname(@filename)
    puts "renaming #{@filename} to #{title}"
    build_report(@filename, title, id)
    File.rename(Dir.pwd + "/" + @filename, Dir.pwd + "/" + title)
    if @options[:make_folder] == true
      puts "-" * 20
      puts  "Creating folder"
      new_folder = Dir.pwd + "/" + response_by_id.title
      unless File.exist?(new_folder)
        Dir.mkdir(new_folder) 
      else
        puts "#{new_folder} Already exists!"
      end
      File.rename title, new_folder + "/" + title
      File.rename title_nfo, new_folder + "/" + title_nfo
    end
    @command = 'exit'
    @command2 = 'exit'
  end

  def self.execute_command(command, results)
    puts "-" * 20
    if results[:source] == "moviedb"
      film = MovieDbFilmGet.new(results[:id])
    end
    if results[:source] == "imdb"
      film = ImdbFilmGet.new(results[:id])
    end
    puts "-" * 20
    puts "Title: #{film.title}"
    puts "Overview: #{film.plot}"
    puts "-" * 20
    @command2 = nil
    while @command2 != 'exit'
      @command2 = Readline.readline("Is this film correct? (y/n) > ", true)
      break if @command2 == "n"
      break if @command2.nil?
      case @command2
      when 'y'
        rename_file(film)
      end
    end
  end

  def self.process_command(options_range, results)
    # Options_range will be an array unless there are 
    # no options in which case its the filename (mf)
    @command = nil
    while @command != 'exit'
      puts "-"*20
      if options_range
        options = "(#{options_range.first}..#{options_range.last})" 
        @command = Readline.readline("Please Select #{options} (i=ignore) (m=manual) > ",true)
      else
        @command = Readline.readline("Nothing found for #{results}: (i=ignore) (m=manual) > ",true)
      end  
      break if @command == "exit"
      break if @command == "i"
      break if @command.nil?
      case @command
      when /^[-+]?[0-9]*\.?[0-9]+$/
        command_int = @command.strip.to_i
        # Make sure command is within range 
        if options_range.include? (command_int)
          execute_command(command_int, results[command_int])
        else
          puts "#{command_int} is an invalid option. Please select #{options}"
        end
      when "m"
        puts "manual mode"
        command3 = Readline.readline("Please enter search term: > ",true)
        file_search(command3)
      end
    end
  end
  def self.file_search(mf)
    file_hash = {}
    i = 1
    file_hash[i] = { :filename => mf }
    #clean_filename = mf.chomp(File.extname(mf) ).capitalize.tr(" ", "_")
    clean_filename = mf.chomp(File.extname(mf) ).capitalize
    puts "208 #{clean_filename}"
    if @options[:imdb] == true
      films = ImdbFilmSearch.search(clean_filename)
    else
      films = MovieDbFilmSearch.search(clean_filename)
    end  
    if films
      puts "#{films.count} matches found"
      f_count = 1
      films.each {|search_result|
        puts "-- #{f_count}) -  #{search_result.title} (#{search_result.title})"  
        file_hash[i][f_count] = {}
        file_hash[i][f_count][:moviename] = search_result.title
        file_hash[i][f_count][:filename] = clean_filename 
        file_hash[i][f_count][:id] = search_result.id
        file_hash[i][f_count][:source] = search_result.source
        f_count +=1
      }
      options_range =* (0...f_count)
      process_command(options_range, file_hash[i])
    else
      puts "no films found for #{clean_filename}"
    end
  end


  def self.search_current_dir(directory)
    Dir.chdir(directory)
    all_video_files = Dir.glob @options[:types]
    all_video_files.each {|mf|
      @filename = mf
      file_search(mf)  
    }
    puts "#{all_video_files.count} Movie files found in #{directory}"
  end
  
  @options = {
    :types => ["*.m4v", "*.avi", "*.mp4", "*.mkv"],
    :moviedb_api => nil,
    :make_folder => true
  }
  op = OptionParser.new do |x|
    x.banner = 'moviesort.rb [options] [file]'
    x.separator '---------'
    x.on("-h", "--help", "Show this message"){ puts op;  exit }
    x.on("-d", "--delete", "Delete movie files and info files") do 
      clear_dir 
    end
    x.on("-f", "--folders", "search folders") do 
      @options[:search_folder] = true
      puts "Searching Sub-folders"
    end
    x.on("-mf", "--makefolder", "make folders") do 
      @options[:make_folder] = true
    end
    x.on("-i", "--imdb", "search imdb") do 
      @options[:imdb] = true
    end
  end

  CONFIG_FILE = File.join(ENV['HOME'],'.moviesort.rc.yaml')
  if File.exists? CONFIG_FILE
    config_options = YAML.load_file(CONFIG_FILE)
    @options.merge!(config_options)
  else
    puts "no config file found at #{ENV['HOME']}"
    File.open(CONFIG_FILE, 'w') { |file| YAML::dump(@options,file) }
    STDERR.puts "Initialized configuration file in #{CONFIG_FILE}"
  end

  puts "-" * 50
  op.parse!(ARGV)
  file = ARGV.shift 
  puts "file is: #{file}" if file 
  if file
    if File.directory?(file)
      @working_directory = Dir.pwd + "/" +file
    end
  else
    @working_directory = Dir.pwd
    puts "Looking for film files in: #{@working_directory}"
  end

  Dir.chdir(@working_directory)
  search_current_dir(@working_directory)
  if @options[:search_folder] 
    folders = find_folders
    puts "#{folders.count} folders found" if @options[:search_folder] = true
    folders.each {|f| search_current_dir(@working_directory+"/"+f)} 
  end
end

