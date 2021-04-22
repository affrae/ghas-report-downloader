#!/usr/bin/ruby

require 'octokit'
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

# Get command Line options using docs @ https://ruby-doc.org/stdlib-2.1.1/libdoc/optparse/rdoc/OptionParser.html

class Optparse

    def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      options = OpenStruct.new
      options.verbose = false
  
      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: ghasrd.rb [options]"
  
        opts.separator ""
        opts.separator "Specific options:"
  
        # List the reports available
        opts.on("-l", "--list",
                "List the reports avilable") do
          options.command = "list"
        end
        
        # get or grab one or more reports

        opts.on("-g x,y,z", "--get x,y,z", "--grab x,y,z", Array, "Get one or more reports by analysis_id") do |reportList|
           options.reportList = reportList
        end
  
        # Run verbosely
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
           options.verbose = v
        end
  
        opts.separator ""
        opts.separator "Common options:"
  
        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end
  
      opt_parser.parse!(args)
      options
    end  # parse()
  
  end  # class Optparse
  
# begin ... end defines code that needs to run on its own in its own context
# rescue gives a block to execute if an error occurs during runtime.
# it functions to handle exceptions, and takes a single argument: the class/type of error that you want to rescue from.
# in this example we are fetching environment variables.
# a KeyError is raised when the specified key is not found.
# in this case it is an environment variable
# if an environment variable does not exist, execute the code in the rescue block and exit status 1
# in a shell script a non-zero exit value means it is an error 

begin
    GITHUB_USERID = ENV.fetch("GITHUB_USERID")
    GITHUB_PAT = ENV.fetch("GITHUB_PAT")
rescue KeyError
    $stderr.puts "To run this script, please set the following environment variables:"
    $stderr.puts "- GITHUB_USERID: Your GitHub username"
    $stderr.puts "- GITHUB_PAT: A Personal Access Token (PAT) for your account"
    exit 1
end

options = Optparse.parse(ARGV)
if options.verbose then
    pp options
end

@client = nil