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
      expect(config).to_not be_loaded
    end

    it "should not create a new instance if already loaded"  do
      described_class.expects(:new).with('/tmp/foo/bar.cfg').once
      i = described_class.add('/tmp/foo/bar.cfg')
      expect(described_class.add('/tmp/foo/bar.cfg')).to eq(i)
    end
  end

  describe "#parse" do
    it "should return nil if the config file is not present" do
      FileUtils.rm(filename)
      expect(instance.parse).to be_nil
      expect(instance.children).to be_empty
    end

    it "should parse sections and attributes" do
      instance.parse
      expect(instance.children.map(&:name)).to eq(['foo', '/var/tmp'])
      instance.children.each do |child|
        expect(child.parent).to eq(instance)
      end
      expect(instance.child('foo')[:fookey1]).to eq('foovalue1')
      expect(instance.child('foo')[:fookey2]).to eq('foovalue2 with spaces')
      expect(instance.child('foo')[:fookey3]).to eq('foovalue3')
      expect(instance.child('foo').child('bar').child('baz')[:bazkey1]).to eq('bazvalue1')
      expect(instance.child('/var/tmp')[:special]).to eq('replace slashes')
    end
  end

  describe "#loaded?" do
    it "should be considered loaded after parsing" do
      expect(instance).to_not be_loaded
      instance.parse
      expect(instance).to be_loaded
    end
  end

  describe "#tocfg" do
    it "should preserve content and order" do
      instance.parse
      expect(instance.to_cfg).to eq(File.read(filename))
    end
  end

  describe "#sync" do
    it "should write the modified config to disk" do
      instance.parse
      instance.path('foo/bar/baz')[:bazkey3] = 'new value'
      Puppet::Util::NimsoftSection.new('newsection', instance)[:key1] = 'value1'
      instance.sync
      expect(File.read(filename)).to eq(File.read(my_fixture('modify_and_sync.cfg')))
    end

    it "should create the file if necessary" do
      FileUtils.rm(filename)
      instance.parse
      instance.path('foo/bar/baz')[:bazkey3] = 'new value'
      Puppet::Util::NimsoftSection.new('newsection', instance)[:key1] = 'value1'
      instance.sync
      expect(File.read(filename)).to eq(File.read(my_fixture('create_and_sync.cfg')))
    end
  end

  describe "#path" do
    before :each do
      instance.parse
    end

    it "should return the specified section" do
      section = instance.path('foo')
      expect(section.parent).to eq(instance)
      expect(section.name).to eq('foo')
      expect(section[:fookey1]).to eq('foovalue1')
    end

    it "should return the specified subsection" do
      section = instance.path('foo/bar/baz')
      expect(section.parent.parent.parent).to eq(instance)
      expect(section.name).to eq('baz')
      expect(section[:bazkey1]).to eq('bazvalue1')
    end

    it "should create a new section if necessary" do
      section = instance.path('new_section')
      expect(section.parent).to eq(instance)
      expect(section.name).to eq('new_section')
    end

    it "should create a new subsection if necessary" do
      section = instance.path('new_section/subsection/subsubsection')
      expect(section.parent.parent.parent).to eq(instance)
      expect(section.name).to eq('subsubsection')
    end
  end
end
