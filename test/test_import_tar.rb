$LOAD_PATH.unshift File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'test/unit'
require 'test/tools'
require 'autobuild/import/cvs'
require 'autobuild/import/svn'
require 'autobuild/import/tar'
require 'webrick'

class TC_TarImporter < Test::Unit::TestCase
    include WEBrick
    Package = Struct.new :srcdir, :target

    def setup
        $PROGRAMS = {}
        $UPDATE = true
        $LOGDIR = "#{TestTools.tempdir}/log"
        FileUtils.mkdir_p($LOGDIR)

        @datadir = File.join(TestTools.tempdir, 'data')
        FileUtils.mkdir_p(@datadir)
        @tarfile = File.join(@datadir, 'tarimport.tar.gz')
        FileUtils.cp(File.join(TestTools::DATADIR, 'tarimport.tar.gz'), @tarfile)
        
        @cachedir = File.join(TestTools.tempdir, 'cache')
    end
    
    def teardown
        $PROGRAMS = nil
        $UPDATE = true
        $LOGDIR = nil
        TestTools.clean
    end

    def test_tar_mode
        assert_equal(TarImporter::Plain, TarImporter.url_to_mode('tarfile.tar'))
        assert_equal(TarImporter::Gzip, TarImporter.url_to_mode('tarfile.tar.gz'))
        assert_equal(TarImporter::Bzip, TarImporter.url_to_mode('tarfile.tar.bz2'))
    end

    def test_tar_valid_url
        assert_raise(ConfigException) {
            TarImporter.new 'ccc://localhost/files/tarimport.tar.gz', :cachedir => @cachedir
        }
    end

    def test_tar_remote
        s = HTTPServer.new :Port => 2000, :DocumentRoot => TestTools.tempdir
        s.mount("/files", HTTPServlet::FileHandler, TestTools.tempdir)
        webrick = Thread.new { s.start }

        # Try to get the file through the http server
        pkg = Package.new File.join(TestTools.tempdir, 'tarimport'), 'tarimport'
        importer = TarImporter.new 'http://localhost:2000/files/data/tarimport.tar.gz', :cachedir => @cachedir

        importer.checkout(pkg)
        assert(File.directory?(pkg.srcdir))
        assert(!importer.update_cache)

        sleep 2 # The Time class have a 1-second resolution
        FileUtils.touch @tarfile
        assert(importer.update_cache)
        assert(!importer.update_cache)

        s.shutdown
        webrick.join
    end
end
 
