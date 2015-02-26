require 'readline'

require "dshell/version"
require "dshell/commander"
module Dshell
  # Your code goes here...
end

def Dshell(&block)
  Dshell::Commander.new(&block).listen
end
