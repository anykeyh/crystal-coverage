module Coverage; end

require "./version"
require "./inject/**"
require "./runtime"

Coverage::CLI.run
