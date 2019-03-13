module Autobuild
    class CVSImporter < Importer
        # Creates a new importer which gets the module +name+ from the
        # repository in +root+. The following values are allowed in +options+:
        # [:cvsup] options to give to 'cvs up'. Default: -dP.
        # [:cvsco] options to give to 'cvs co'. Default: -P.
        #
        # This importer uses the 'cvs' tool to perform the import. It defaults
        # to 'cvs' and can be configured by doing
        #   Autobuild.programs['cvs'] = 'my_cvs_tool'
        def initialize(root_name, options = {})
            cvsopts, common = Kernel.filter_options options, :module => nil, :cvsup => '-dP', :cvsco => '-P'
            @root   = root_name
            @module = cvsopts[:module]
            raise ArgumentError, "no module given" unless @module

            @options_up = cvsopts[:cvsup] || '-dP'
            @options_up = Array[*@options_up]
            @options_co = cvsopts[:cvsco] || '-P'
            @options_co = Array[*@options_co]
            super(common.merge(repository_id: "cvs:#{@root}:#{@module}"))
        end

        # Array of options to give to 'cvs checkout'
        attr_reader :options_co
        # Array of options to give to 'cvs update'
        attr_reader :options_up

        # Returns the module to get
        def modulename
            @module
        end

        private

        def update(package, options = Hash.new) # :nodoc:
            if options[:only_local]
                package.warn "%s: the CVS importer does not support local updates, skipping"
                return false
            end

            unless File.exist?("#{package.srcdir}/CVS/Root")
                raise ConfigException.new(package, 'import'), "#{package.srcdir} is not a CVS working copy"
            end

            root = File.open("#{package.srcdir}/CVS/Root", &:read).chomp
            mod  = File.open("#{package.srcdir}/CVS/Repository", &:read).chomp

            # Remove any :ext: in front of the root
            root = root.gsub(/^:ext:/, '')
            expected_root = @root.gsub(/^:ext:/, '')
            # Remove the optional ':' between the host and the path
            root = root.gsub(/:/, '')
            expected_root = expected_root.gsub(/:/, '')

            if root != expected_root || mod != @module
                raise ConfigException.new(package, 'import'),
                    "checkout in #{package.srcdir} is from #{root}:#{mod}, was expecting #{expected_root}:#{@module}"
            end
            package.run(:import, Autobuild.tool(:cvs), 'up', *@options_up,
                        retry: true, working_directory: package.importdir)
            true # no easy way to check if package was updated, keep previous behavior and consider updated
        end

        def checkout(package, options = Hash.new) # :nodoc:
            head, tail = File.split(package.srcdir)
            cvsroot = @root

            FileUtils.mkdir_p(head) unless File.directory?(head)
            package.run(:import, Autobuild.tool(:cvs), '-d', cvsroot, 'co', '-d', tail, *@options_co, modulename,
                retry: true, working_directory: head)
        end
    end

    # Returns the CVS importer which will get the +name+ module in repository
    # +repo+. The allowed values in +options+ are described in CVSImporter.new.
    def self.cvs(root, options = {}, backward_compatibility = nil)
        if backward_compatibility
            backward_compatibility[:module] = options
            CVSImporter.new(root, backward_compatibility)
        else
            CVSImporter.new(root, options)
        end
    end
end
