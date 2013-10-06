#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/nimsoft_config'


describe Puppet::Util::NimsoftConfig do
  include PuppetlabsSpec::Files

  let :filename do
    file = tmpfilename('sample.cfg')
    unless File.exists? file
      FileUtils.cp(my_fixture('sample.cfg'), file)
    end
    file
  end

  let :instance do
    described_class.new(filename)
  end

  after :each do
    described_class.initvars
  end

  describe ".add" do
    it "should create a new instance if not already loaded" do
      described_class.expects(:new).with('/tmp/foo/bar.cfg').once
      described_class.add('/tmp/foo/bar.cfg')
    end

    it "should not parse the config file directly" do
      config = described_class.add(my_fixture('sample.cfg'))
      config.should_not be_loaded
    end

    it "should not create a new instance if already loaded"  do
      described_class.expects(:new).with('/tmp/foo/bar.cfg').once
      i = described_class.add('/tmp/foo/bar.cfg')
      described_class.add('/tmp/foo/bar.cfg').should == i
    end
  end

  describe "#parse" do
    it "should return nil if the config file is not present" do
      FileUtils.rm(filename)
      instance.parse.should be_nil
      instance.children.should be_empty
    end

    it "should parse sections and attributes" do
      instance.parse
      instance.children.map(&:name).should == ['foo', '/var/tmp']
      instance.children.each do |child|
        child.parent.should == instance
      end
      instance.child('foo')[:fookey1].should == 'foovalue1'
      instance.child('foo')[:fookey2].should == 'foovalue2 with spaces'
      instance.child('foo')[:fookey3].should == 'foovalue3'
      instance.child('foo').child('bar').child('baz')[:bazkey1].should == 'bazvalue1'
      instance.child('/var/tmp')[:special].should == 'replace slashes'
    end
  end

  describe "#loaded?" do
    it "should be considered loaded after parsing" do
      instance.should_not be_loaded
      instance.parse
      instance.should be_loaded
    end
  end

  describe "#tocfg" do
    it "should preserve content and order" do
      instance.parse
      instance.to_cfg.should == File.read(filename)
    end
  end

  describe "#sync" do
    it "should write the modified config to disk" do
      instance.parse
      instance.path('foo/bar/baz')[:bazkey3] = 'new value'
      Puppet::Util::NimsoftSection.new('newsection', instance)[:key1] = 'value1'
      instance.sync
      File.read(filename).should == File.read(my_fixture('modify_and_sync.cfg'))
    end

    it "should create the file if necessary" do
      FileUtils.rm(filename)
      instance.parse
      instance.path('foo/bar/baz')[:bazkey3] = 'new value'
      Puppet::Util::NimsoftSection.new('newsection', instance)[:key1] = 'value1'
      instance.sync
      File.read(filename).should == File.read(my_fixture('create_and_sync.cfg'))
    end
  end

  describe "#path" do
    before :each do
      instance.parse
    end

    it "should return the specified section" do
      section = instance.path('foo')
      section.parent.should == instance
      section.name.should == 'foo'
      section[:fookey1].should == 'foovalue1'
    end

    it "should return the specified subsection" do
      section = instance.path('foo/bar/baz')
      section.parent.parent.parent.should == instance
      section.name.should == 'baz'
      section[:bazkey1].should == 'bazvalue1'
    end

    it "should create a new section if necessary" do
      section = instance.path('new_section')
      section.parent.should == instance
      section.name.should == 'new_section'
    end

    it "should create a new subsection if necessary" do
      section = instance.path('new_section/subsection/subsubsection')
      section.parent.parent.parent.should == instance
      section.name.should == 'subsubsection'
    end
  end
end
