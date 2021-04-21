#!/usr/bin/ruby

require 'octokit'

begin
    GITHUB_USERID = ENV.fetch("GITHUB_USERID")
    GITHUB_PAT = ENV.fetch("GITHUB_PAT")
  rescue KeyError
    $stderr.puts "To run this script, please set the following environment variables:"
    $stderr.puts "- GITHUB_USERID: Your GitHub username"
    $stderr.puts "- GITHUB_PAT: A Personal Access Token (PAT) for your account"
    exit 1
  end

  @client = nil