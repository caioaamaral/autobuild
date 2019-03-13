require 'rake'

# rubocop:disable Style/MixinUsage
include Rake::DSL if defined?(Rake::DSL)
# rubocop:enable Style/MixinUsage

require 'utilrb/logger'

module Autobuild
    LIB_DIR = __dir__
    extend Logger::Root('Autobuild', Logger::INFO)
end

require 'net/smtp'
require 'socket'
require 'etc'
require 'find'
require 'thread'
require 'pathname'
require 'shellwords'
require 'find'
require 'rake/tasklib'
require 'fileutils'
require 'optparse'
require 'rake'
require 'singleton'
require 'pastel'
require 'tty-prompt'
require 'autobuild/tools'

require 'autobuild/version'
require 'autobuild/environment'
require 'autobuild/exceptions'
require 'autobuild/pkgconfig'
require 'autobuild/reporting'
require 'autobuild/mail_reporter'
require 'autobuild/subcommand'
require 'autobuild/timestamps'
require 'autobuild/parallel'
require 'autobuild/utility'
require 'autobuild/test_utility'
require 'autobuild/config'

require 'autobuild/importer'
require 'autobuild/import/cvs'
require 'autobuild/import/darcs'
require 'autobuild/importer'
require 'autobuild/import/git'
require 'autobuild/import/hg'
require 'autobuild/import/svn'
require 'autobuild/import/archive'
require 'autobuild/import/tar'

require 'autobuild/package'
require 'autobuild/configurable'
require 'autobuild/packages/autotools'
require 'autobuild/packages/cmake'
require 'autobuild/packages/genom'
require 'autobuild/packages/import'
require 'autobuild/packages/orogen'
require 'autobuild/packages/pkgconfig'
require 'autobuild/packages/dummy'
require 'autobuild/packages/ruby'
require 'autobuild/packages/python'

require 'autobuild/rake_task_extension'
