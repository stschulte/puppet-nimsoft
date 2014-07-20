#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_exclude).provider(:nimsoft), '(integration)' do
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
    Puppet::Type.type(:nimsoft_logmon_exclude).stubs(:defaultprovider).returns described_class
  end

  describe "removing a resource" do
    it "should do nothing if exclude is absent" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'no_such_profile/no_such_exclude', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('logmon.cfg')))
      expect(status.changed?).to be_empty
    end

    it "should do nothing if exclude is present in a different profile" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'secure log/exclude_debug', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('logmon.cfg')))
      expect(status.changed?).to be_empty
    end

    it "should remove the exclude if currently present" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'system log/exclude_debug', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_remove.cfg')))
      expect(status.changed?).to_not be_empty
    end

    it "should remove the exclude section after removing the last exclude" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'secure log/exclude_su_oracle', :ensure => 'absent')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_remove_last.cfg')))
      expect(status.changed?).to_not be_empty
    end
  end

  describe "creating a resource" do
    it "should add the exclude to the list"  do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'secure log/exclude_su_nobody', :ensure => 'present', :active => 'yes', :match => '/FAILED su for nobody/')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_add.cfg')))
      expect(status.changed?).to_not be_empty
    end

    it "should create the exclude section first" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'empty profile/foo', :ensure => 'present', :active => 'yes', :match => '/.*/')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_add_new_section.cfg')))
      expect(status.changed?).to_not be_empty
    end
  end

  describe "modifying a resource" do
    it "should do nothing if exclude is in sync" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'system log/exclude_info', :ensure => 'present', :active => 'yes', :match => '/INFO/')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('logmon.cfg')))
      expect(status.changed?).to be_empty
    end

    it "should modify exclude if not in sync" do
      resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'system log/exclude_info', :ensure => 'present', :active => 'no', :match => 'INFO*')
      status = run_in_catalog(resource)
      expect(File.read(input)).to eq(File.read(my_fixture('output_modify.cfg')))
      expect(status.changed?).to_not be_empty
    end
  end
end


