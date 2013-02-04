require 'uri'

# class that groks the megar command line options and invokes the required task
class Megar::Shell

  # holds the parsed options
  attr_reader :options

  # initializes the shell with command line argments:
  #
  # +options+ is expected to be the hash structure as provided by GetOptions.new(..)
  #
  # +args+ is the remaining command line arguments
  #
  def initialize(options,args)
    @options = (options||{}).each{|k,v| {k => v} }
  end

  # runs the megar task
  def run
    if email && password
      $stderr.puts "Connecting to mega as #{email}.."
      raise "Failed to connect!" unless session.connected?
      $stderr.puts "Connected!"
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
  megar [options]

Options:
  -h  | --help           : shows command help
  -v  | --verbose        : run with verbose
  -e= | --email=value    : email address for login
  -p= | --password=value : password for login

Examples:

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