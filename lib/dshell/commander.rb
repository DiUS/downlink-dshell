module Dshell
  class Commander

    attr_reader :history, :whitelist, :commands

    def initialize &block
      @commands = {}
      @history = []
      @whitelist = []

      instance_eval(&block)

      command :help do
        show_help
      end
    end

    def allow *commands
      whitelist.concat(commands.map(&:to_sym))
    end

    def listen
      show_motd
      while true do
        print  '> '
        input = STDIN.readline
        name, *argv = input.chomp.split(' ')
        name = name.to_sym
        history << input
        handle(name, argv)
      end
    end

    def command name, &block
      @commands[name] = block
    end

    def motd value
      @motd = value
    end

    def handle(name, argv)
      com = command_for(name)
      if com
        com.call(argv)
      else
        no_command name
      end
    end

    def command_for(name)
      commands[name] if allowed? name
    end

    def allowed?(name)
      whitelist.empty? or whitelist.include?(name) or (name == :help)
    end

    def allowed_commands
      commands.keys.select do |name|
        allowed?(name)
      end
    end

    def no_command(name)
      puts "No command #{name}"
    end

    def show_help
      puts "Available commands:"
      puts allowed_commands.join ' '
    end

    def show_motd
      puts @motd
    end

  end
end
