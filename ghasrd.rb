#!/usr/bin/ruby

# frozen_string_literal: true

require 'terminal-table'
require 'pathname'
require 'octokit'
require 'optparse'
require 'ostruct'
require 'pp'
require 'json'
require 'net/http'
require 'uri'

# Get command Line options using docs @ https://ruby-doc.org/stdlib-3.0.1/libdoc/optparse/rdoc/OptionParser.html

# Class Optparse
# Parses the command line options
class Optparse
  # the parse functionality for this class
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.

    options = OpenStruct.new
    options.verbose = false
    options.extraVerbose = false
    options.api = 'https://api.github.com'
    options.hostname = 'github.com'
    options.directory = Pathname.new(Dir.pwd)

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
      opts.separator ''
      opts.separator 'Owner and repo:'

      opts.on('-o', '--owner OWNER', 'The owner of the repository') do |owner|
        unless owner.match('^([a-z0-9])(?!.*--)([a-z0-9-])*([a-z0-9])$')
          raise OptionParser::InvalidArgument,
                'OWNER may only contain alphanumeric characters or single hyphens,' \
                ' and cannot begin or end with a hyphen.' \
                " '#{owner}' fails this test!"
        end

        options.owner = owner
      end

      opts.on('-r', '--repo REPO', 'The repository to query') do |repo|
        unless repo.match('^[a-z0-9-]*$')
          raise OptionParser::InvalidArgument,
                "REPO may only contain alphanumeric characters or hyphens. '#{repo}' fails this test!"
        end

        options.repo = repo
      end

      opts.separator ''
      opts.separator 'Actions:'
      # List the reports available
      opts.on('-l', '--list', 'List available reports') do
        options.command = 'list'
      end

      # get or grab one or more PR reports

      opts.on(
        '-p x,y,z',
        '--pr x,y,z',
        Array,
        'Get reports for the most recent commit on the source branch', 'for each of the listed Pull Request numbers'
      ) do |pr_list|
        unless pr_list.all? { |i| i.match('^([0-9])*$') }
          raise OptionParser::InvalidArgument,
                "Pull Request IDs may only contain numbers. '#{pr_list.join(',')}' fails this test!"
        end

        options.pr_list = pr_list
        options.command = 'pr'
      end

      # get or grab one or more reports listed by ID

      opts.on('-g x,y,z', '--get x,y,z', '--grab x,y,z', Array,
              'Get one or more reports by the Analysis Report ID.') do |report_list|
        unless report_list.all? { |i| i.match('^([0-9])*$') }
          raise OptionParser::InvalidArgument,
                "Analysis Report IDs lists may only contain numbers. '#{report_list.join(',')}' fails this test!"
        end

        options.report_list = report_list
        options.command = 'get'
      end

      # get or grab one or more reports listed by SHA

      opts.on(
        '-s x,y,z',
        '--sha x,y,z',
        Array,
        'Get reports for each of the listed Commit SHAs',
        'We can figure out what commit you’re referring to',
        'if you provide the first few characters of the SHA-1 hash,',
        'as long as that partial hash is at least four characters long and',
        'no other commit can have a hash that begins with the same prefix.'
      ) do |sha_list|
        unless sha_list.all? { |i| i.match('^([0-9a-z])*$') && i.length >= 4 && i.length <= 40 }
          raise OptionParser::InvalidArgument,
                'Listed SHAs should be  < 40 characters long and may only contain numbers and lowercase letters. '\
                "'#{sha_list.join(',')}' fails this test!"
        end

        options.sha_list = sha_list
        options.command = 'sha'
      end

      opts.separator ''
      opts.separator 'Other options:'

      # Set the output directory
      opts.on('-d', '--dir DIRECTORY', 'The directory to write the reports to') do |directory|
        path = Pathname.new(directory)
        raise 'Directory does not exist' unless path.exist?

        raise 'Path given is not a directory' unless path.directory?

        puts "Output directory is #{path.expand_path}"
        options.directory = path.expand_path
      end

      # Run verbosely
      opts.on('-v', 'Run verbosely') do
        options.verbose = true
      end

      # Run extra verbosely
      opts.on('-V', 'Run extra verbosely') do
        options.verbose = true
        options.extraVerbose = true
      end

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
    rescue OptionParser::ParseError => e
      puts e
      puts opt_parser
      exit 1
    end
    options
  end
end

# Utility Methods

def show_wait_spinner(fps = 30)
  chars = %w[| / - \\]
  delay = 1.0 / fps
  iter = 0
  spinner = Thread.new do
    while iter # Keep spinning until told otherwise
      print chars[(iter += 1) % chars.length]
      sleep delay
      print "\b"
    end
  end
  yield.tap do
    iter = false
    spinner.join
  end
end

def get_uri(uri, token)
  request = Net::HTTP::Get.new(uri)
  request.basic_auth('dummy', token)
  request['Accept'] = 'application/vnd.github.v3+json'
  request['Accept'] = 'application/sarif+json'

  req_options = {
    use_ssl: uri.scheme == 'https'
  }

  Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end
end

def get_report(options, report, file_name)
  puts "  Getting SARIF report with ID #{report}..."

  response = get_uri(
    URI.parse("#{options.api}/repos/#{options.owner}/#{options.repo}/code-scanning/analyses/#{report}"),
    GITHUB_PAT
  )

  unless response.code == '200'
    puts '  Report does not exist for:'\
         "#{options.api}/repos/#{options.owner}/#{options.repo}/code-scanning/analyses/#{report}"
    return
  end

  path = options.directory + file_name
  path.open('w') do |f|
    f.write(response.body)
    puts "  Report Downloaded to #{file_name}"
  end
end

# Main

# begin ... end defines code that needs to run on its own in its own context
# rescue gives a block to execute if an error occurs during runtime.
# it functions to handle exceptions, and takes a single argument: the class/type of error that you want to rescue from.
# in this example we are fetching environment variables.
# a KeyError is raised when the specified key is not found.
# in this case it is an environment variable
# if an environment variable does not exist, execute the code in the rescue block and exit status 1
# in a shell script a non-zero exit value means it is an error

options = Optparse.parse(ARGV)

pp options if options.extraVerbose

begin
  GITHUB_PAT = ENV.fetch('GITHUB_PAT')

  Octokit.configure do |c|
    c.api_endpoint = options.api
    puts "Connecting to #{c.api_endpoint}" if options.extraVerbose
  end

  client = Octokit::Client.new access_token: GITHUB_PAT
  client.auto_paginate = true

  puts "Running as @#{client.user.login}" if options.extraVerbose

  case options.command
  when 'list'
    print "Getting a list of available reports for https://#{options.hostname}/#{options.owner}/#{options.repo}..."
    width = 40
    table = Terminal::Table.new headings: ['ID', 'Tool', 'Commit SHA(7)', 'Commit date', 'Commit author',
                                           'Commit message']
    table.style = { all_separators: true }
    show_wait_spinner do
      reports = client.get("/repos/#{options.owner}/#{options.repo}/code-scanning/analyses")

      reports.each do |report|
        commit_info = client.get("/repos/#{options.owner}/#{options.repo}/git/commits/#{report.commit_sha}")
        table.add_row [
          report.id,
          report.tool.name,
          report.commit_sha[0..6],
          report.created_at,
          commit_info.author.name,
          commit_info.message.length < width ? commit_info.message : "#{commit_info.message[0...(width - 4)]}..."
        ]
      end
    end
    puts 'done.'
    puts table
    puts ''
    puts 'To get an report issue the command:'
    puts "  #{$PROGRAM_NAME} -o #{options.owner} -r #{options.repo} -g [ID]"
    puts 'where [ID] is the ID of the analysis report you are interested in from the table above.'
    unless table.rows.empty?
      puts 'For example:'
      puts "  #{$PROGRAM_NAME} -o #{options.owner} -r #{options.repo} -g #{table.rows[table.rows.length - 1][0]}"
      puts 'to get the last report on that table'
    end

  when 'get'
    puts 'Getting reports...'
    puts "  Writing output to: #{options.directory}"

    options.report_list.each do |report|
      get_report(options, report, "analysis_#{report}.sarif")
    end
    puts '...done.'

  when 'pr'
    options.pr_list.each do |pr_id|
      puts "Getting SARIF report(s) for PR ##{pr_id} in https://#{options.hostname}/#{options.owner}/#{options.repo}:"
      puts "  Writing output to: #{options.directory}"
      pr_info = client.pull_request("#{options.owner}/#{options.repo}", pr_id.to_s)
      puts "  HEAD is #{pr_info.head.sha}"
      reports = client.get("/repos/#{options.owner}/#{options.repo}/code-scanning/analyses")
      report_list = reports.select { |report| report.commit_sha == pr_info.head.sha }
      unless report_list.empty?
        report_list.each do |report|
          puts "  Found Report #{report.id}"
          get_report(options, report.id, "pr_#{pr_id}_analysis_#{report.id}.sarif")
        end
      end
      if report_list.empty?
        puts "  No analysis reports found for SHA #{pr_info.head.sha} for PR ##{pr_id} in https://#{options.hostname}/#{options.owner}/#{options.repo}"
      end
    rescue Octokit::NotFound
      puts "  Could not find the needed data - is https://#{options.hostname}/#{options.owner}/#{options.repo}"
      puts '  the correct repository, or do you have the correct PR number?'
      next
    end

  when 'sha'
    puts 'Getting reports...'
    puts "  Writing output to: #{options.directory}"
    options.sha_list.each do |sha|
      begin
        commit_info = client.get("/repos/#{options.owner}/#{options.repo}/commits/#{sha}")
      rescue Octokit::UnprocessableEntity
        warn "  No commit found for SHA: #{sha}"
        next
      end
      puts "  Matching #{sha} to #{commit_info.sha}"
      reports = client.get("/repos/#{options.owner}/#{options.repo}/code-scanning/analyses")
      report_list = reports.select { |report| report.commit_sha == commit_info.sha }
      unless report_list.empty?
        report_list.each do |report|
          puts "  Found Report #{report.id}"
          get_report(options, report.id, "sha_#{sha}_analysis_#{report.id}.sarif")
        end
      end
      if report_list.empty?
        puts "  No analysis reports found for SHA #{sha} in https://#{options.hostname}/#{options.owner}/#{options.repo}"
      end
    rescue Octokit::NotFound
      puts "  Could not find the needed data - is https://#{options.hostname}/#{options.owner}/#{options.repo}"
      puts '  the correct repository, or do you have the correct sha?'
      next
    end
    puts '...done.'
  end
rescue KeyError
  warn 'To be able to run this script, you are required to set the following environment variables:'
  warn '- GITHUB_PAT: A Personal Access Token (PAT) for your account'
  exit 1
rescue Octokit::Unauthorized
  warn 'Bad Credentials - is your GITHUB_PAT ok?'
  exit 1
rescue Octokit::NotFound
  warn "Could not find the needed data - is https://#{options.hostname}/#{options.owner}/#{options.repo}"
  warn 'the correct repository, or do you have the correct PR and/or Analysis Report IDs?'
  exit 1
rescue Octokit::Forbidden
  warn '\bError!'
  warn "Code Scanning has not been enabled for https://#{options.hostname}/#{options.owner}/#{options.repo}"
  exit 1
rescue Octokit::ServerError
  warn 'It appears the service is currently not available - please try again later.'
  warn 'You can check https://www.githubstatus.com/ for operational details' unless options.hostname != 'github.com'
  exit 1
rescue Octokit::ClientError => e
  warn 'There is an Octokit Client Error we do not have a specific rescue for yet'
  warn e
  exit 1
rescue Octokit::Error => e
  warn 'There is a Octokit Error we do not have a specific rescue for yet'
  warn e
  exit 1
rescue StandardError => e
  warn 'There is a Standard Error we do not have a specific rescue for yet'
  warn e
  exit 1
end
