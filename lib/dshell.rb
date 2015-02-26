require 'readline'
require 'pathname'
require 'yaml'

require "dshell/version"
require "dshell/commander"
module Dshell
  # Your code goes here...
end

def Dshell(&block)
  Dshell::Commander.new(&block).run
end
