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
    defaults = {
      :interval => 1
    }
    @options = defaults.merge( (options||{}).each{|k,v| {k => v} } )
  end

  # runs the octopump task
  def run
    usage
  end

  # defines the valid command line options
  OPTIONS = %w(help verbose)

  class << self

    # prints usage/help information
    def usage
      $stderr.puts <<-EOS

Megar v#{Megar::VERSION}
===================================

Usage:
  octopump [options] uri

Options:
  -h  | --help    : shows command help
  -v  | --verbose : run with verbose

Examples:

EOS
    end
  end

  # prints usage/help information
  def usage
    self.class.usage
  end

end