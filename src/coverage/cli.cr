module Coverage; end

require "./version"
require "./inject/**"
require "http/client"

Coverage::CLI.run
