#!/usr/bin/ruby

require 'octokit'

# Execute some shell command
`pwd`

# Was the app run successful?
puts $?.success?

# Process id of the exited app
puts $?.pid

# The actual exit status code
puts $?.exitstatus