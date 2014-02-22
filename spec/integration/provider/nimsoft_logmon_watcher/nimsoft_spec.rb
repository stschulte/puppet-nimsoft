#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_watcher).provider(:nimsoft), '(integration)' do
  include PuppetlabsSpec::Files

  let :input do
    filename = tmpfilename('logmon.cfg')
    FileUtils.cp(my_fixture('logmon.cfg'), filename)
    filename
  end

  let :catalog do
    Puppet::Resource::Catalog.new
  end

  def run_in_catalog(*resources)
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply
  end

  before :each do
    described_class.initvars
    Puppet::Util::NimsoftConfig.initvars
    described_class.stubs(:config).returns Puppet::Util::NimsoftConfig.add(input)
    Puppet::Type.type(:nimsoft_logmon_watcher).stubs(:defaultprovider).returns described_class
  end

  describe "removing a resource" do
    it "should do nothing if watcher is absent" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'no_such_profile/no_such_watcher', :ensure => 'absent')
      run_in_catalog(resource).changed?.should be_empty
      File.read(input).should == File.read(my_fixture('logmon.cfg'))
    end

    it "should do nothing if watcher is present in a different profile" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'secure log/NFS Timeout', :ensure => 'absent')
      run_in_catalog(resource).changed?.should be_empty
      File.read(input).should == File.read(my_fixture('logmon.cfg'))
    end

    it "should remove the watcher if currently present" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'system log/NFS Timeout', :ensure => 'absent')
      run_in_catalog(resource).changed?.should_not be_empty
      File.read(input).should == File.read(my_fixture('remove_watcher.cfg'))
    end

    it "should remove the watchers section after removing the last watcher" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'secure log/failed su', :ensure => 'absent')
      run_in_catalog(resource).changed?.should_not be_empty
      File.read(input).should == File.read(my_fixture('remove_lastwatcher.cfg'))
    end
  end

  describe "creating a resource" do
    it "should complain about a missing profile" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'no_such_profile/failed su', :ensure => 'present')
      run_in_catalog(resource)
    end
    it "should add the watcher to the list"
    it "should create the wather section first"
  end

  describe "modifying a resource" do
    it "should do nothing if watcher is in sync"
  end
end


