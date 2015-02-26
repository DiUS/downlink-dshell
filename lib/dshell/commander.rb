module Dshell
  class Commander

    attr_reader :commands, :current_dir, :root, :config

    def initialize &block
      load_config
      @commands = {}
      @whitelist = []
      @current_dir = root
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

      Readline.completion_proc = -> (current) do
        completion_for current
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
        dir = root unless dir.to_s.start_with?(root.to_s)
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
      file.to_s.gsub(/^#{root}\/?/, '/')
    end

    def real_file_for file
      file = Pathname.new file
      if file.absolute?
        root.join(file.to_s.gsub(/^\//,''))
      else
        Pathname.new(File.expand_path(file, current_dir))
      end
    end

    def run
      login and listen
    end

    def login
      ok = true
      ok = check_authentication if has_authentication?
      unless ok
        show_error "Invalid username or password"
      end
      ok
    end

    def listen
      show_motd
      show_instructions
      while true do
        input = Readline.readline(prompt, true) || 'exit'
        name, *argv = input.chomp.split(' ')
        name = name.to_s.to_sym
        handle(name, argv)
      end
    end

    def prompt
      "#{virtual_file_for current_dir}> "
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
      if :override == name
        system('bash')
      else
        com = command_for(name)
        if com
          com.call(argv)
        else
          no_command name
        end
      end
    end

    def command_for(name)
      commands[name] if allowed_command? name
    end

    def allowed_command?(name)
      allowed_commands.include? name
    end

    def allowed_commands
      @allowed_commands ||= begin
        allow = (config['allowed_commands'] || commands.keys) + required_commands
        allow.map(&:to_sym).uniq.sort
      end
    end

    def required_commands
      [:help, :exit, :ssh]
    end

    def no_command(name)
      show_error "No command #{name}"
    end

    def show_help
      puts "Available commands:"
      puts allowed_commands.join ' '
      puts "type 'help <command name>' for help on particular command"
    end

    def show_help_for_command(name)
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

    def show_motd
      puts config['motd'] if config['motd']
    end

    def show_history
      puts Readline::HISTORY.to_a
    end

    def add_to_history(input)
      Readline::HISTORY.push input
    end

    def completion_for(current)
      allowed_commands.select do |comm|
        comm.to_s.start_with? current
      end
    end

    def load_config
      @config = YAML.load(File.read '/etc/downlink/config.yml') || {}
      @root ||= Pathname.new(
        config.fetch('rootfs', '/var/downlink')
      ).realpath
    end

    def username
      config['username']
    end

    def password
      config['password']
    end

    def has_authentication?
      username and password
    end

    def check_authentication
      print 'username: '
      given_username = STDIN.readline.chomp
      print 'password: '
      given_password = STDIN.readline.chomp
      given_username == username and given_password == password
    end

  end
end
