require 'uri'

# class that groks the megar command line options and invokes the required task
class Megar::Shell

  # holds the parsed options
  attr_reader :options

  # holds the remaining command line arguments
  attr_reader :args

  # initializes the shell with command line argments:
  #
  # +options+ is expected to be the hash structure as provided by GetOptions.new(..)
  #
  # +args+ is the remaining command line arguments
  #
  def initialize(options,args)
    @options = (options||{}).each{|k,v| {k => v} }
    @args = args
  end

  # Command: execute the megar task according to the options provided on initialisation
  def run
    if email && password
      $stderr.puts "Connecting to mega as #{email}.."
      raise "Failed to connect!" unless session.connected?
      case args.first
      when /ls/i
        ls
      when /get/i
        get(args[1])
      when /put/i
        put(args.drop(1))
      else
        $stderr.puts "Connected!"
      end
    else
      usage
    end
  end

  # defines the valid command line options
  OPTIONS = %w(help verbose email=s password=s)

  class << self

    # prints usage/help information
    def usage
      $stderr.puts <<-EOS

Megar v#{Megar::VERSION}
===================================

Usage:
  megar [options] [commands]

Options:
  -h  | --help           : shows command help
  -v  | --verbose        : run with verbose
  -e= | --email=value    : email address for login
  -p= | --password=value : password for login

Commands:
  (none)                 : will perform a basic connection test only
  ls                     : returns a full file listing
  get file_id            : downloads the file with id file_id
  put file_name          : uploads the file called "file_name"

Examples:
  megar --email=my@mail.com --password=MyPassword ls
  megar -e my@mail.com -p MyPassword ls
  megar -e my@mail.com -p MyPassword get 74ZTXbyR
  megar -e my@mail.com -p MyPassword put ../path/to/my_file.png

EOS
    end
  end

  # prints usage/help information
  def usage
    self.class.usage
  end

  # do file listing
  def ls
    session.files.each do |file|
      puts file
    end
  end

  # download file with +file_id+
  def get(file_id)
    if file = session.files.find_by_id(file_id)
      $stderr.puts "Downloading #{file_id} to #{file.name}.."
      File.open(file.name,'wb') do |f|
        f.write file.body
      end
    else
      $stderr.puts "I couldn't find the file with ID #{file_id}"
    end
  end

  # upload file(s) +filenames+
  def put(filenames)
    Array(filenames).each do |filename|
      $stderr.puts "Uploading #{filename}.."
      session.files.create(body: filename)
    end
  end

  def session
    @session ||= Megar::Session.new(email: email, password: password)
  end

  # Option shortcuts
  def email    ; options[:email]    ; end
  def password ; options[:password] ; end

end