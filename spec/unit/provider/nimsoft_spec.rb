#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/provider/nimsoft'

describe Puppet::Provider::Nimsoft do

  let :config do
    Puppet::Util::NimsoftConfig.new(my_fixture('sample.cfg'))
  end

  let :element do
    described_class.register_config('foo', 'foo/instances')
    described_class.root.path('instance01')
  end

  before :each do
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::NimsoftConfig.stubs(:add).with('foo').returns config
    described_class.initvars
  end

  describe "root" do
    before :each do
      described_class.register_config('foo', 'foo/instances')
    end

    it "should return the root tree" do
      described_class.root.should == config.path('foo/instances')
    end

    it "should parse the config if not already loaded" do
      config.should_not be_loaded
      config.expects(:parse).once
      described_class.root
    end

    it "should only parse the config once" do
      config.should_not be_loaded
      config.expects(:parse).once
      described_class.root
      described_class.root
    end
  end

  describe "map_property" do

    it "should create getter and setter" do
      described_class.map_property(:foo, :bar)

      provider = described_class.new(:name => 'foo', :element => element)
      provider.should respond_to :foo
      element.expects(:[]).with(:bar).returns 'bar_value'
      element.expects(:[]=).with(:bar, 'new_bar_value')

      provider.foo.should == 'bar_value'
      provider.foo = 'new_bar_value'
    end

    it "should allow passing a section" do
      described_class.map_property(:foo, :bar, :section => 'subsection1/subsection2')

      provider = described_class.new(:name => 'foo', :element => element)
      provider.should respond_to :foo
      element.path('subsection1/subsection2').expects(:[]).with(:bar).returns 'bar_value'
      element.path('subsection1/subsection2').expects(:[]=).with(:bar, 'new_bar_value')

      provider.foo.should == 'bar_value'
      provider.foo = 'new_bar_value'
    end
  end

  describe "instances" do
    it "should return an empty array if expected root section is not present" do
      described_class.register_config('foo', 'foo/no_such_section')
      described_class.instances.should be_empty
    end

    it "should return an empty array if root object has no subsections" do
      described_class.register_config('foo', 'foo/no_instances')
      described_class.instances.should be_empty
    end

    it "should return an instance for each subsection" do
      described_class.register_config('foo', 'foo/instances')
      instances = described_class.instances.map { |i| {:name => i.name, :ensure => i.get(:ensure), :element => i.get(:element)} }

      instances.should == [
        { :name => 'instance01', :ensure => :present, :element => config.path('foo/instances/instance01') },
        { :name => 'instance02', :ensure => :present, :element => config.path('foo/instances/instance02') },
        { :name => 'instance03', :ensure => :present, :element => config.path('foo/instances/instance03') }
      ]
    end
  end

  describe "exists?" do
    it "should return true if ensure is present" do
      provider = described_class.new(:name => 'foo', :ensure => :present, :element => element)
      provider.should be_exists
    end

    it "should return false if ensure is absent" do
      provider = described_class.new(:name => 'foo', :element => element)
      provider.should_not be_exists
    end
  end

  describe "create" do
    it "should add  the corresponding element" do
      described_class.register_config('foo', 'foo/instances')
      config.parse

      instance = described_class.new(:name => 'new_instance', :ensure => :present)

      config.path('foo/instances').children.map(&:name).should == %w{instance01 instance02 instance03}
      instance.create
      config.path('foo/instances').children.map(&:name).should == %w{instance01 instance02 instance03 new_instance}
    end
  end

  describe "destroy" do
    it "should delete the corresponding element" do
      config.parse
      provider = described_class.new(:name => 'foo', :element => config.path('foo/instances/instance02'))

      config.path('foo/instances').children.map(&:name).should == %w{instance01 instance02 instance03}
      provider.destroy
      provider.element.should be_nil

      config.path('foo/instances').children.map(&:name).should == %w{instance01 instance03}
    end
  end

  describe "flush" do
    it "should flush the configuration back to disc" do
      config.expects(:sync)
      provider = described_class.new(:name => 'foo', :element => element)
      provider.flush
    end
  end
end
