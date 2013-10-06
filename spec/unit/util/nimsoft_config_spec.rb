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
      instance.child('foo')[:fookey1].should == 'foovalue1'
      instance.child('foo')[:fookey2].should == 'foovalue2 with spaces'
      instance.child('foo')[:fookey3].should == 'foovalue3'
      instance.child('foo').child('bar').child('baz')[:bazkey1].should == 'bazvalue1'
      instance.child('/var/tmp')[:special].should == 'replace slashes'
    end
  end

  describe "#tocfg" do
    it "should preserve content and order" do
      instance.parse
      instance.to_cfg.should == File.read(filename)
    end
  end

end
