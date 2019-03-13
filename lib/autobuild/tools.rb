module Autobuild
    class << self
        # Configure the programs used by different packages
        attr_reader :programs
        # A cache of entries in programs to their resolved full path
        #
        # @return [{String=>[String,String,String]}] the triplet (full path,
        #   tool name, value of ENV['PATH']). The last two values are used to
        #   invalidate the cache when needed
        #
        # @see tool_in_path
        attr_reader :programs_in_path

        # Get a given program, using its name as default value. For
        # instance
        #   tool('automake')
        # will return 'automake' unless the autobuild script defined
        # another automake program in Autobuild.programs by doing
        #   Autobuild.programs['automake'] = 'automake1.9'
        def tool(name)
            programs[name.to_sym] || programs[name.to_s] || name.to_s
        end

        # Find a file in a given path-like variable
        def find_in_path(file, envvar = 'PATH')
            env.find_in_path(file, envvar)
        end

        # Resolves the absolute path to a given tool
        def tool_in_path(name, env: self.env)
            path, path_name, path_env = programs_in_path[name]
            current = tool(name)
            env_path = env.resolved_env['PATH']
            if (path_env != env_path) || (path_name != current)
                # Delete the current entry given that it is invalid
                programs_in_path.delete(name)
                path =
                    if current[0, 1] == "/"
                        # This is already a full path
                        current
                    else
                        env.find_executable_in_path(current)
                    end

                unless path
                    raise ArgumentError, "tool #{name}, set to #{current}, "\
                        "can not be found in PATH=#{env_path}"
                end

                programs_in_path[name] = [path, current, env_path]
            end

            path
        end
    end

    @programs = Hash.new
    @programs_in_path = Hash.new
end
