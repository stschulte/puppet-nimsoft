#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_oracle_profile).provider(:nimsoft), '(integration)' do
  include PuppetlabsSpec::Files

  let :resource_present do
    Puppet::Type.type(:nimsoft_oracle_profile).new(
      :name       => 'DEV',
      :ensure     => 'present',
      :active     => 'yes',
      :connection => 'development'
    )
  end

  # resource does not exist, so applying the resource should
  # change nothing
  let :resource_absent do
    Puppet::Type.type(:nimsoft_oracle_profile).new(
      :name   => 'no such profile',
      :ensure => 'absent'
    )
  end

  # resource does exist, applying should remove it
  let :resource_destroy do
    Puppet::Type.type(:nimsoft_oracle_profile).new(
      :name   => 'Deprecated',
      :ensure => 'absent'
    )
  end

  let :resource_create do
    Puppet::Type.type(:nimsoft_oracle_profile).new(
      :name                  => 'new profile',
      :active                => :yes,
      :description           => 'A new profile',
      :connection            => 'new connection',
      :source                => 'host3.example.com',
      :interval              => '30 min',
      :heartbeat             => '20 sec',
      :clear_msg             => 'p_timeout_1',
      :sql_timeout_msg       => 'sql_timeout_1',
      :profile_timeout_msg   => 'p_timeout_1',
      :severity              => 'major',
      :profile_timeout       => '15 min',
      :sql_timeout           => '30 sec',
      :connection_failed_msg => 'connect_failed_1'
    )
  end

  let :resource_modify do
    Puppet::Type.type(:nimsoft_oracle_profile).new(
      :name        => 'PRO',
      :ensure      => 'present',
      :active      => 'no',
      :description => 'Old PROD database',
      :heartbeat   => '1 min'
    )
  end

  let :input do
    filename = tmpfilename('oracle_monitor.cfg')
    FileUtils.cp(my_fixture('oracle_monitor.cfg'), filename)
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
    Puppet::Util::NimsoftConfig.initvars
    described_class.initvars
    described_class.stubs(:config).returns Puppet::Util::NimsoftConfig.add(input)

    Puppet::Type.type(:nimsoft_oracle_connection).stubs(:defaultprovider).returns described_class
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        run_in_catalog(resource_absent).changed?.should be_empty
        File.read(input).should == File.read(my_fixture('oracle_monitor.cfg'))
      end
    end

    describe "when resource is currently present" do
      it "should remove the resource" do
        run_in_catalog(resource_destroy).changed?.should == [ resource_destroy ]
        File.read(input).should == File.read(my_fixture('output_remove.cfg'))
      end
    end
  end

  describe "ensure => present" do
    describe "when resource is currently absent" do
      it "should add the resource" do
        run_in_catalog(resource_create).changed?.should == [ resource_create ]
        File.read(input).should == File.read(my_fixture('output_add.cfg'))
      end
    end

    describe "when resource is currently present" do
      it "should do nothing if in sync" do
        run_in_catalog(resource_present).changed?.should be_empty
        File.read(input).should == File.read(my_fixture('oracle_monitor.cfg'))
      end

      it "should modify attributes if not in sync" do
        run_in_catalog(resource_modify).changed?.should == [ resource_modify ]
        File.read(input).should == File.read(my_fixture('output_modify.cfg'))
      end
    end
  end

  describe "adding multiple resources to the catalog" do
    it "should do the right thing" do
      run_in_catalog(resource_modify, resource_present, resource_create, resource_absent, resource_destroy )
        File.read(input).should == File.read(my_fixture('output_multiple_resources.cfg'))
    end
  end
end
