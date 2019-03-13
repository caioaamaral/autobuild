require 'autobuild/test'

module Autobuild
    describe Reporting do
        describe ".report" do
            it "returns 'no errors' if there are none" do
                report_result = Reporting.report {}
                assert_equal [], report_result
            end

            describe "on_package_failures: :raise" do
                before do
                    @package_e = Class.new(Autobuild::Exception).
                        exception('test exception')
                end
                after do
                    Autobuild::Package.clear
                end

                it "lets an Interrupt pass through" do
                    assert_raises(Interrupt) do
                        Reporting.report(on_package_failures: :raise) { raise Interrupt }
                    end
                end
                it "raises a package failure" do
                    flexmock(Reporting).should_receive(:error).never
                    e = assert_raises(@package_e.class) do
                        Reporting.report(on_package_failures: :raise) do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e
                        end
                    end
                    assert_equal @package_e, e
                end
                it "raises an Interrupt if it was interrupted" do
                    assert_raises(Interrupt) do
                        Reporting.report(on_package_failures: :raise) do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e
                            raise Interrupt
                        end
                    end
                end
                it "combines multiple failures into a CompositeException error before raising it" do
                    other_package_e = Class.new(Autobuild::Exception).exception('test')
                    e = assert_raises(CompositeException) do
                        Reporting.report(on_package_failures: :raise) do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e << other_package_e
                        end
                    end
                    assert_equal [@package_e, other_package_e], e.original_errors
                end
                it "returns packages non-fatal errors" do
                    flexmock(@package_e, fatal?: false)
                    report_result = Reporting.report(on_package_failures: :raise) do
                        pkg = Autobuild::Package.new('test')
                        pkg.failures << @package_e
                    end
                    assert_equal [@package_e], report_result
                end
                it "raises Interrupt if an Interrupt has been raised" do
                    flexmock(@package_e, fatal?: false)
                    assert_raises(Interrupt) do
                        Reporting.report(on_package_failures: :raise) do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e
                            raise Interrupt
                        end
                    end
                end
            end

            describe "on_package_failures: :exit" do
                before do
                    @package_e = Class.new(Autobuild::Exception).
                        exception('test exception')
                end

                it "lets an Interrupt pass through" do
                    assert_raises(Interrupt) do
                        Reporting.report(on_package_failures: :exit) do
                            raise Interrupt
                        end
                    end
                end
                it "reports package fatal errors and exits" do
                    flexmock(Reporting).should_receive(:error).with(@package_e).once
                    assert_raises(SystemExit) do
                        Reporting.report do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e
                        end
                    end
                end
                it "reports package non-fatal errors and exits, even if an Interrupt has been raised" do
                    flexmock(Reporting).should_receive(:error).with(@package_e).once
                    assert_raises(SystemExit) do
                        Reporting.report do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e
                            raise Interrupt
                        end
                    end
                end
                it "reports package non-fatal errors and returns them" do
                    flexmock(@package_e, fatal?: false)
                    flexmock(Reporting).should_receive(:error).with(@package_e).once

                    report_result = Reporting.report do
                        pkg = Autobuild::Package.new('test')
                        pkg.failures << @package_e
                    end
                    assert_equal [@package_e], report_result
                end
                it "reports package non-fatal errors and raises Interrupt if an Interrupt has been raised" do
                    flexmock(@package_e, fatal?: false)
                    flexmock(Reporting).should_receive(:error).with(@package_e).once
                    assert_raises(Interrupt) do
                        Reporting.report do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e
                            raise Interrupt
                        end
                    end
                end
            end

            describe "on_package_failures: :report" do
                before do
                    @package_e = Class.new(Autobuild::Exception).
                        exception('test exception')
                    @other_package_e = Class.new(Autobuild::Exception).
                        exception('test')
                end

                it "lets an Interrupt pass through" do
                    assert_raises(Interrupt) do
                        Reporting.report(on_package_failures: :report) { raise Interrupt }
                    end
                end
                it "reports package errors and returns them" do
                    flexmock(Reporting).should_receive(:error).with(@package_e).once
                    flexmock(Reporting).should_receive(:error).with(@other_package_e).once

                    report_result = Reporting.report(on_package_failures: :report) do
                        pkg = Autobuild::Package.new('test')
                        pkg.failures << @package_e << @other_package_e
                    end
                    assert_equal [@package_e, @other_package_e], report_result
                end
                it "reports package errors and raises Interrupt if an interrupt was raised" do
                    flexmock(Reporting).should_receive(:error).with(@package_e).once
                    flexmock(Reporting).should_receive(:error).with(@other_package_e).once
                    assert_raises(Interrupt) do
                        Reporting.report(on_package_failures: :report) do
                            pkg = Autobuild::Package.new('test')
                            pkg.failures << @package_e << @other_package_e
                            raise Interrupt
                        end
                    end
                end
            end
        end
    end
end

class TestReporting < Minitest::Test
    def test_package_message_with_marker_inside_token
        package = Autobuild::Package.new('pkg')
        assert_equal 'patching pkg: unapplying', package.process_formatting_string('patching %s: unapplying')
    end

    def test_package_message_with_marker_at_beginning
        package = Autobuild::Package.new('pkg')
        assert_equal 'pkg unapplying', package.process_formatting_string('%s unapplying')
    end

    def test_package_message_with_marker_at_end
        package = Autobuild::Package.new('pkg')
        assert_equal 'patching pkg', package.process_formatting_string('patching %s')
    end

    def test_package_message_without_formatting
        flexmock(Autobuild).should_receive('color').never
        package = Autobuild::Package.new('pkg')
        assert_equal 'patching a package pkg', package.process_formatting_string('patching a package %s')
    end

    def test_package_message_with_formatting
        flexmock(Autobuild).should_receive('color').with('patching a package', :bold, :red).and_return('|patching a package|').once
        package = Autobuild::Package.new('pkg')
        assert_equal '|patching a package| pkg', package.process_formatting_string('patching a package %s', :bold, :red)
    end
end
