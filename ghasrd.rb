#!/usr/bin/ruby

require 'terminal-table'
require 'octokit'
require 'optparse'
require 'ostruct'
require 'pp'
require 'json'
require 'net/http'
require 'uri'

# Get command Line options using docs @ https://ruby-doc.org/stdlib-3.0.1/libdoc/optparse/rdoc/OptionParser.html

class Optparse
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.verbose = false
    options.extraVerbose = false
    options.APIEndpoint = 'https://api.github.com'

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

      opts.separator ''
      opts.separator 'Mandatory options:'

      opts.on('-o', '--owner OWNER', '(Required) the OWNER of the repository') do |owner|
        unless owner.match('^([a-z0-9])(?!.*--)([a-z0-9-])*([a-z0-9])$')
          raise OptionParser::InvalidArgument, "OWNER may only contain alphanumeric characters or single hyphens, and cannot begin or end with a hyphen. '#{owner}' fails this test!"
        end

        options.owner = owner 
      end

      opts.on('-r', '--repo REPO', '(Required) a REPO to query') do |repo|
        unless repo.match('^[a-z0-9-]*$')
          raise OptionParser::InvalidArgument, "REPO may only contain alphanumeric characters or hyphens. '#{repo}' fails this test!"
        end

        options.repo = repo
      end

      opts.separator ''
      opts.separator 'Specific options:'


      # List the reports available
      opts.on('-l', '--list', 'List available reports') do
        options.command = 'list'
      end

      # get or grab one or more PR reports

      opts.on('-p x,y,z', '--pr x,y,z', Array, 'Get reports for the most recent commit on the source branch for each of the listed Pull Request numbers') do |pr_list|
        unless pr_list.all? {|i| i.match('^([0-9])*$') }
          raise OptionParser::InvalidArgument, "Pull Request Item lists may only contain numbers. '#{pr_list.join(',')}' fails this test!"
        end

        options.pr_list = pr_list
        options.command = 'pr'
      end

      opts.on('-g x,y,z', '--get x,y,z', '--grab x,y,z', Array, 'Get one or more reports by the Analysis ID.') do |report_list|
        unless report_list.all? {|i| i.match('^([0-9])*$') }
          raise OptionParser::InvalidArgument, "Analysis ID lists may only contain numbers. '#{report_list.join(',')}' fails this test!"
        end

        options.report_list = report_list
        options.command = 'get'
      end

      # Run verbosely
      opts.on('-v', 'Run verbosely') do
        options.verbose = true
      end

       # Run verbosely
       opts.on('-V', 'Run extra verbosely') do
        options.verbose = true
        options.extraVerbose = true
      end
 
      opts.separator ''
      opts.separator 'Common options:'

      # No argument, shows at tail.  This will print an options summary.
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    begin
      opt_parser.parse!(args)
      mandatory_missing = []
      mandatory_missing << '-o OWNER' if options[:owner].nil?
      mandatory_missing << '-r REPO' if options[:repo].nil?
      raise OptionParser::MissingArgument, mandatory_missing.join(' ') unless mandatory_missing.empty?
    rescue OptionParser::ParseError => ex
      puts ex
      puts opt_parser
      exit 1
    end
    options

  end  # parse()

end  # class Optparse

def show_wait_spinner(fps=30)
  chars = %w[| / - \\]
  delay = 1.0 / fps
  iter = 0
  spinner = Thread.new do
    while iter do  # Keep spinning until told otherwise
      print chars[(iter += 1) % chars.length]
    sleep delay
    print "\b"
    end
  end
  yield.tap{
    iter = false
    spinner.join
  }
end

# begin ... end defines code that needs to run on its own in its own context
# rescue gives a block to execute if an error occurs during runtime.
# it functions to handle exceptions, and takes a single argument: the class/type of error that you want to rescue from.
# in this example we are fetching environment variables.
# a KeyError is raised when the specified key is not found.
# in this case it is an environment variable
# if an environment variable does not exist, execute the code in the rescue block and exit status 1
# in a shell script a non-zero exit value means it is an error 

begin
  GITHUB_PAT = ENV.fetch('GITHUB_PAT')
rescue KeyError
  warn 'To be able to run this script, you are required to set the following environment variables:'
  warn '- GITHUB_PAT: A Personal Access Token (PAT) for your account'
  exit 1
end

client = Octokit::Client.new access_token: GITHUB_PAT
client.auto_paginate = true

options = Optparse.parse(ARGV)

if options.extraVerbose
  pp options
  puts "Running as @#{client.user.login}"
end

begin
  case options.command
  when 'list'
    puts "Listing available reports for https://github.com/#{options.owner}/#{options.repo}..."
    rows = []
    width = 40
    table = Terminal::Table.new headings: ['ID', 'Tool','Commit SHA(7)', 'Commit date', 'Commit author', 'Commit message']
    table.style = {all_separators: true}
    show_wait_spinner{
      begin
        analyses = client.get("/repos/#{options.owner}/#{options.repo}/code-scanning/analyses")
  
        analyses.each do |analysis|
          commit_info = client.get("/repos/#{options.owner}/#{options.repo}/git/commits/#{analysis.commit_sha}")
          table.add_row [analysis.id, analysis.tool.name, analysis.commit_sha[0..6], analysis.created_at, commit_info.author.name, commit_info.message.length < width ? commit_info.message : commit_info.message[0...(width - 4)] + '...'] 
        end
      end
    }
    puts table
    puts ''
    puts "To get a report issue the command\n  #{$PROGRAM_NAME} -o #{options.owner} -r #{options.repo} -g [ID]\nwhere [ID] is the ID of the analysis you are interested in from the table above."
    unless rows.empty?
      puts "\nFor example:\n  #{$PROGRAM_NAME} -o #{options.owner} -r #{options.repo} -g #{rows[rows.length - 1][0]}\nto get the last report on that table"
    end

  when 'get'
    puts 'Getting reports...'
    options.report_list.each do |report_id|
      puts "  Getting SARIF report with ID #{report_id}..."
      begin
        uri = URI.parse("#{options.APIEndpoint}/repos/#{options.owner}/#{options.repo}/code-scanning/analyses/#{report_id}")
        request = Net::HTTP::Get.new(uri)
        request.basic_auth('dummy', "#{GITHUB_PAT}")
        request['Accept'] = 'application/vnd.github.v3+json'
        request['Accept'] = 'application/sarif+json'

        req_options = {
          use_ssl: uri.scheme == 'https',
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
        begin
          puts "  Report does not exist for #{options.APIEndpoint}/repos/#{options.owner}/#{options.repo}/code-scanning/analyses/#{report_id}"
          next
        end if response.code != '200'
        f = File.new('analysis_' + report_id + '.sarif', 'w')
        f.write(response.body)
        puts '  Report Downloaded to analysis_' + report_id + '.sarif'
        f.close
      end
    end
    puts '...done.'

  when 'pr'
    options.pr_list.each do |pr_id|
       puts "Getting SARIF report(s) for PR ##{pr_id} in https://github.com/#{options.owner}/#{options.repo}:"
       pr_info = client.get("/repos/#{options.owner}/#{options.repo}/pulls/#{pr_id}")
       puts "  HEAD is #{pr_info.head.sha}"
       analyses = client.get("/repos/#{options.owner}/#{options.repo}/code-scanning/analyses")
       required_analyses = analyses.select {|analysis| analysis.commit_sha == pr_info.head.sha}
       begin
         required_analyses.each do |analysis|
           puts "  Found Report #{analysis.id}"
           begin
             uri = URI.parse("#{options.APIEndpoint}/repos/#{options.owner}/#{options.repo}/code-scanning/analyses/#{analysis.id}")
             request = Net::HTTP::Get.new(uri)
             request.basic_auth('dummy', "#{GITHUB_PAT}")
             request['Accept'] = 'application/vnd.github.v3+json'
             request['Accept'] = 'application/sarif+json'

             req_options = {
             use_ssl: uri.scheme == 'https',
             }

             response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
               http.request(request)
             end
             begin
               puts "  Report does not exist for #{options.APIEndpoint}/repos/#{options.owner}/#{options.repo}/code-scanning/analyses/#{analysis.id}"
               next
             end if response.code != '200'
             puts "  Opening File pr_#{pr_id}_analysis_#{analysis.id}.sarif for writing"
             # f = File.new('pr_'+pr_id+'_analysis_'+analysis.id+'.sarif', 'w')
             f = File.new('pr_' + pr_id + '_analysis_' + analysis.id.to_s + '.sarif', 'w')
             # f = File.new('test.sarif', 'w')
             f.write(response.body)
             f.close
             puts "  Report Downloaded to pr_#{pr_id}_analysis_#{analysis.id}.sarif"
           end
         end
         next
       end unless required_analyses.empty?
       puts "  No analyses found for SHA #{pr_info.head.sha} for PR ##{pr_id} in https://github.com/#{options.owner}/#{options.repo}"
    rescue Octokit::NotFound
      puts "  Could not find the needed data - is https://github.com/#{options.owner}/#{options.repo} the correct repository, or do you have the correct PR number?"
      next
     end
  end

rescue Octokit::Unauthorized
  puts 'Bad Credentials - is your GITHUB_PAT ok?'
  exit 1
rescue Octokit::NotFound
  puts "Could not find the needed data - is https://github.com/#{options.owner}/#{options.repo} the correct repository, or do you have the correct PR/Analysis IDs?"
  exit 1
rescue Octokit::Forbidden
  puts "Code Scanning has not been enabled for https://github.com/#{options.owner}/#{options.repo}"
  exit 1
rescue Octokit::ServerError
  puts 'It appears the service is currently not available - please try again later. You can check https://www.githubstatus.com/ for operational details'
  exit 1
rescue Octokit::ClientError => ex
  puts 'There is an Octokit Client Error we do not have a specific message for yet'
  puts ex
  exit 1
rescue Octokit::Error => ex
  puts 'There is a Octokit Error we do not have a specific message for yet'
  puts ex
  exit 1
rescue StandardError => ex
  puts 'There is a Standard Error we do not have a specific message for yet'
  puts ex
  exit 1
end
