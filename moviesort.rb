#!/usr/bin/env ruby

require 'rubygems'
require 'rest-client'
require 'json'
require 'readline'
require 'optparse'
require 'yaml'
require 'curses'

class MovieSort

  def self.clear_dir
    # This has been put in to clear up test data - to use this would be silly. Don't.
    working_directory =  Dir.pwd
    puts "Deleting films/.nfo files in: #{working_directory}"
    directory_name = "MovieSort"
    all_video_files = Dir.glob (@options[:types], "*.nfo")
    # put in error handling if no files
    all_video_files.each {|mf|
      puts "Deleting #{mf}"
      File.delete(mf)  
    }
  end

  def self.themoviedb_lookup(type, title, year = "") 
    case type
    when "search"
      search = "#{title} #{year}"
      url = "http://api.themoviedb.org/3/search/movie?query=#{search}&api_key=#{@options[:moviedb_api]}"
    when "by_id"
      url = "http://api.themoviedb.org/3/movie/#{title}?api_key=#{@options[:moviedb_api]}&append_to_response=releases,trailers,images"
    else
      raise 'Flagrant error'
    end 
    url = URI.encode(url)
    response = RestClient.get url 
    response = JSON.parse response
  end 

  def self.build_report(filename, title, id)
    report_filename = "./#{@directory_name}/report.html" 
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

  def self.build_nfo(response_by_id, title)
    nfo_filename = "#{Dir.pwd}/#{title}.nfo"
    puts "Creating .nfo file: #{title}.nfo"
    cast_response = get_cast(response_by_id['id'])
    File.open(nfo_filename, 'w') { |nfo|
      nfo.puts "<movie>"
      nfo.puts "  <title>#{response_by_id['title']}</title>"
      nfo.puts "  <originaltitle>#{response_by_id['original_title']}</originaltitle>"
      nfo.puts "  <outline>#{response_by_id['overview']}</outline>"
      nfo.puts "  <runtime>#{response_by_id['runtime']}</runtime>"
      nfo.puts "  <id>#{response_by_id['imdb_id']}</id>"
      nfo.puts "  <tagline>#{response_by_id['tagline']}</tagline>"
      foo = {} 
      i = 0
      cast_response['cast'] .each {|cr|
        foo[i] = { "name" => cr['name'], "role" => cr['character'], "order" => cr['order']}
        i += 1
      }
      foo = foo.sort_by { |k,v| v['order']}
      foo.each { |k,v|
        nfo.puts "  <actor>"
        nfo.puts "    <name>#{v['name']}</name>"
        nfo.puts "    <role>#{v['role']}</role>"
        nfo.puts "  </actor>"
      }
      cast_response['crew'].each {|cr|
        job  = cr['job'].tr(" ", "")
        nfo.puts "  <#{job}>#{cr['name']}</#{job}>"
      }
      nfo.puts "</movie>"
    }
  end

  def self.rename_file(response_by_id)
    # puts response_by_id
    title = response_by_id["title"]
    year = response_by_id["release_date"]
    id = response_by_id["id"]
    year = year[0..3]
    sanitize_filename(title, year)
    build_nfo(response_by_id, title)
    title = title + File.extname(@filename)
    puts "renaming #{@filename} to #{title}"
    build_report(@filename, title, id)
    File.rename(Dir.pwd + "/" + @filename, Dir.pwd + "/" + title)
    @command = 'exit'
    @command2 = 'exit'
  end

  def self.execute_command(command, results)
    puts "-" * 20
    puts "#{command}) #{results[:moviename]}, looking up: http://www.themoviedb.org/movie/#{results[:id]} "
    response_by_id = themoviedb_lookup("by_id", results[:id])
    puts "-" * 20
    puts "Title: #{response_by_id["title"]}"
    puts "Overview: #{response_by_id["overview"]}"
    puts "-" * 20
    @command2 = nil
    while @command2 != 'exit'
      @command2 = Readline.readline("Is this film correct? (y/n)", true)
      break if @command2 == "n"
      break if @command2.nil?
      case @command2
      when 'y'
        rename_file(response_by_id)
      end
    end
  end

  def self.process_command(options_range, results)
    @command = nil
    while @command != 'exit'
      options = "(#{options_range.first}..#{options_range.last})" if options_range.count >1 
      puts "-"*20
      @command = Readline.readline("Please Select #{options} (i=ignore) (m=manual) > ",true)
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
      end
    end
  end

  def self.file_search(mf)
    @filename = mf
    file_hash = {} 
    i = 0
    file_hash[i] = { :filename => mf } 
    clean_filename = mf.chomp(File.extname(mf) ).capitalize.tr(" ", "_")
    puts "-" * 50
    puts "Looking up themoviedb.org for: #{mf}"
    response = themoviedb_lookup("search", clean_filename)
    if response["results"].count > 0 
      puts "#{response["results"].count} Matches found on moviedb.org"
      r_count = 0
      response["results"].each {|r|
        puts "-- #{r_count}) -  #{r['title']}(#{r['release_date']})"
        file_hash[i][r_count] = {} 
        file_hash[i][r_count][:moviename] = r['title']  
        file_hash[i][r_count][:filename] = clean_filename  
        file_hash[i][r_count][:id] = r['id']  
        r_count+=1
      }
      options_range =* (0...r_count)
      process_command(options_range, file_hash[i])
    else
      file_hash[i][:filename] = clean_filename  
      puts "Nothing found on themoviedb.org for #{clean_filename}" 
      build_report(@filename, nil, nil)
    end 
    i+=1
  end

  def self.dir_search
    working_directory =  Dir.pwd
    puts "Scanning for films in: #{working_directory}"
    directory_name = "MovieSort"
    Dir.mkdir(directory_name) unless File.exists?(directory_name)
    all_video_files = Dir.glob @options[:types]
    # put in error handling if no files
    all_video_files.each {|mf|
      file_search(mf)  
    }
  end

  @options = {
    :types => ["*.m4v", "*.avi", "*.mp4", "*.mkv"],
    :moviedb_api => nil
  }
  op = OptionParser.new do |x|
    x.banner = 'moviesort.rb [options] [file]'
    x.separator '---------'
    x.on("-h", "--help", "Show this message"){ puts op;  exit }
    x.on("-d", "--delete", "Delete movie files and info files") do 
      clear_dir 
    end
    x.on("-f", "--folders", "folders") do 
      @options[:folder] = true
    end
  end
  op.parse!(ARGV)
  file = ARGV.pop #GMA: shift rather than pop
  # GMA - argv size and crap out if more than one - one file or every file - eg:
  # if ARGV.empty || ARGV,size == 1
  #  $stderr.puts "one file ya dick"
  #  exit 1
  #end  
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
  dir_search
end

