#!/usr/bin/ruby

require 'terminal-table'
require 'octokit'
require 'optparse'
require 'ostruct'
require 'pp'

# Get command Line options using docs @ https://ruby-doc.org/stdlib-2.1.1/libdoc/optparse/rdoc/OptionParser.html

class Optparse

    def self.parse(args)
        # The options specified on the command line will be collected in *options*.
        # We set default values here.
        options = OpenStruct.new
        options.verbose = false
        options.extraVerbose = false

        opt_parser = OptionParser.new do |opts|
            opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

            opts.separator ""
            opts.separator "Mandatory options:"

            opts.on("-o", "--owner OWNER", "(Required) the OWNER of the repository") do |owner|
                raise OptionParser::InvalidArgument.new "OWNER may only contain alphanumeric characters or single hyphens, and cannot begin or end with a hyphen." if !owner.match('^[a-z0-9][a-z0-9-]*[a-z0-9]$')
                options.owner = owner 
            end

            opts.on("-r", "--repo REPO", "(Required) a REPO to query") do |repo|
                options.repo = repo
            end

            opts.separator ""
            opts.separator "Specific options:"


            # List the reports available
            opts.on("-l", "--list", "List available reports") do
                options.command = "list"
            end

            # get or grab one or more PR reports

            opts.on("-p x,y,z", "--pr x,y,z", Array, "Get reports for the most recent commit on the source branch for each of the listed Pull Request numbers") do |prList|
                options.prList = prList
                options.command = "pr"
            end

            opts.on("-g x,y,z", "--get x,y,z", "--grab x,y,z", Array, "Get one or more reports by the Analysis ID.") do |reportList|
                options.reportList = reportList
                options.command = "get"
            end

            # Run verbosely
            opts.on("-v", "Run verbosely") do
                options.verbose = true
            end

             # Run verbosely
             opts.on("-V", "Run extra verbosely") do
                options.verbose = true
                options.extraVerbose = true
            end
 
            opts.separator ""
            opts.separator "Common options:"

            # No argument, shows at tail.  This will print an options summary.
            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
        end

        begin
            opt_parser.parse!(args)
            mandatoryMissing = []
            mandatoryMissing << "-o OWNER" if options[:owner].nil?
            mandatoryMissing << "-r REPO" if options[:repo].nil?
            raise OptionParser::MissingArgument.new mandatoryMissing.join(' ') if mandatoryMissing.length > 0
        rescue OptionParser::ParseError => ex
            puts ex
            puts opt_parser
            exit 1
        end
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
    GITHUB_PAT = ENV.fetch("GITHUB_PAT")
rescue KeyError
    $stderr.puts "To run this script, please set the following environment variables:"
    $stderr.puts "- GITHUB_PAT: A Personal Access Token (PAT) for your account"
    exit 1
end

client = Octokit::Client.new :access_token => GITHUB_PAT

options = Optparse.parse(ARGV)
if options.extraVerbose then
    pp options
    puts "Running as @#{client.user.login}"
end

case options.command
when "list"
    puts "Listing available reports for #{options.owner}/#{options.repo}"
    client.auto_paginate = true
    rows = []
    width = 40
    theReturn = client.get("/repos/#{options.owner}/#{options.repo}/code-scanning/analyses")
    table = Terminal::Table.new :headings => ['ID', 'Commit SHA(7)', 'Commit date', 'Commit author', 'Message']
    theReturn.each do |analysis|
        commitInfo = client.get("/repos/#{options.owner}/#{options.repo}/git/commits/#{analysis.commit_sha}")
        table.add_row [analysis.id, analysis.commit_sha[0..6], analysis.created_at, commitInfo.author.name, commitInfo.message.length < width ?  commitInfo.message : commitInfo.message[0...(width -4)] + "..."] 
        table.add_separator
    end
    puts table
    puts ""
    puts "To get a report issue the command\n  #{$PROGRAM_NAME} -o #{options.owner} -r #{options.repo} -g [ID]\nwhere [ID] is the ID of the analysis you are interested in from the table above."
    puts "\nFor example:\n  #{$PROGRAM_NAME} -o #{options.owner} -r #{options.repo} -g #{rows[rows.length-1][0]}\nto get the last report on that table" if rows.length > 0
when "get"
    puts "Getting reports..."
    options.reportList.each do |reportID|
        puts "  Getting SARIF report with ID #{reportID}: To be implemented"
    end
    puts "...done."

when "pr"
    puts "Getting reports for PRs..."
    options.prList.each do |prID|
        puts "  Getting SARIF report for PR ##{prID}: To be implemented"
    end
    puts "...done."
end

