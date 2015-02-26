module Dshell
  class Commander
    ROOT = Pathname.new('/tmp/downlink').realpath

    attr_reader :history, :whitelist, :commands, :current_dir

    def initialize &block
      @commands = {}
      @history = []
      @whitelist = []
      @current_dir = ROOT
      @command_help = {}

      instance_eval(&block)

      help :help, "Show help"
      command :help do |argv|
        if argv.empty?
          show_help
        else
          show_help_for_command argv.first.to_sym
        end
      end

      self
    end

    def show_error message
      puts "\033[31m#{message}\033[0m"
    end

    def change_dir dir
      dir = real_file_for dir
      begin
        dir = dir.realpath
        dir = ROOT unless dir.to_s.start_with?(ROOT.to_s)
      rescue Errno::ENOENT
        not_found = true
      end
      if not_found
        show_error "No directory #{virtual_file_for dir}"
      else
        @current_dir = dir
      end
    end

    def virtual_file_for file
      file.to_s.gsub(/^#{ROOT}\/?/, '/')
    end

    def real_file_for file
      if file.absolute?
        ROOT.join(file.to_s.gsub(/^\//,''))
      else
        Pathname.new(File.expand_path(file, current_dir))
      end
    end

    def allow *commands
      whitelist.concat(commands.map(&:to_sym))
    end

    def listen
      show_instructions
      while true do
        print "#{virtual_file_for current_dir}> "
        input = STDIN.readline
        name, *argv = input.chomp.split(' ')
        name = name.to_sym
        history << input
        handle(name, argv)
      end
    end

    def command name, &block
      name = name.to_sym
      @commands[name] = block
    end

    def help name, instructions
      @command_help[name] = instructions
    end

    def instructions value
      @instructions = value
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
      commands[name] if allowed_command? name
    end

    def allowed_command?(name)
      whitelist.empty? or whitelist.include?(name) or (name == :help)
    end

    def allowed_commands
      commands.keys.select do |name|
        allowed_command?(name)
      end
    end

    def no_command(name)
      show_error "No command #{name}"
    end

    def show_help
      puts "Available commands:"
      puts allowed_commands.join ' '
      puts "type 'help <command name>' for help on particular command"
    end

    def show_help_for_command name
      name = name.to_sym
      if allowed_command? name
        if @command_help[name]
          puts "#{name}: #{@command_help[name]}"
        else
          show_error "No help for #{name}"
        end
      else
        no_command name
      end
    end

    def show_instructions
      puts @instructions
    end

  end
end
