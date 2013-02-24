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
        session.files.each do |file|
          puts file
        end
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

Examples:
  megar --email=my@mail.com --password=MyPassword ls
  megar -e my@mail.com -p MyPassword ls

EOS
    end
  end

  # prints usage/help information
  def usage
    self.class.usage
  end

  def session
    @session ||= Megar::Session.new(email: email, password: password)
  end

  # Option shortcuts
  def email    ; options[:email]    ; end
  def password ; options[:password] ; end

end