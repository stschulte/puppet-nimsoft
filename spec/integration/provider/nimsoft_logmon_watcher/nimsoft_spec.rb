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
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('logmon.cfg')))
      expect(status.changed?).to be_empty
    end

    it "should do nothing if watcher is present in a different profile" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'secure log/NFS Timeout', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('logmon.cfg')))
      expect(status.changed?).to be_empty
    end

    it "should remove the watcher if currently present" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'system log/NFS Timeout', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_remove.cfg')))
      expect(status.changed?).to_not be_empty
    end

    it "should remove the watchers section after removing the last watcher" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'secure log/failed su', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_remove_last.cfg')))
      expect(status.changed?).to_not be_empty
    end
  end

  describe "creating a resource" do
    it "should add the watcher to the list" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'secure log/nfs timeout', :ensure => 'present', :active => 'yes', :match => '/nfs.*timed out/', :severity => 'critical', :message => 'NFS timeout detected')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_add.cfg')))
      expect(status.changed?).to_not be_empty
    end

    it "should create the watcher section first" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'empty profile/nfs timeout', :ensure => 'present', :active => 'yes', :match => '/nfs.*timed out/', :severity => 'critical', :message => 'NFS timeout detected')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_add_new_section.cfg')))
      expect(status.changed?).to_not be_empty
    end
  end

  describe "modifying a resource" do
    it "should do nothing if watcher is in sync" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'system log/NFS Timeout', :ensure => 'present', :active => 'yes', :match => '/nfs: server (.*) not responding, timed out/', :severity => 'critical', :subsystem => '1.4.2.1', :message => 'NFS Timed out: ${msg}', :suppkey => '${PROFILE}.${WATCHER}')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('logmon.cfg')))
      expect(status.changed?).to be_empty
    end

    it "should modify watcher if not in sync" do
      resource = Puppet::Type.type(:nimsoft_logmon_watcher).new(:name => 'system log/NFS Timeout', :ensure => 'present', :active => 'no', :match => '/nfs: server (.*) not responding, timed out/', :severity => 'warning', :subsystem => '1.4.2.1', :message => 'NFS Timed out: ${msg}', :suppkey => '${PROFILE}.${WATCHER}')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_modify.cfg')))
      expect(status.changed?).to_not be_empty
    end
  end
end
