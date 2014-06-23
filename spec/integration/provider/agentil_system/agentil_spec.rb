#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil'

describe Puppet::Type.type(:agentil_system).provider(:agentil), '(integration)' do
  include PuppetlabsSpec::Files

  let :resource_present do
    Puppet::Type.type(:agentil_system).new(
      :name      => 'PRO_sap01',
      :ensure    => 'present',
      :templates => [ 'System Template for system id 1' ],
      :ip        => [ '192.168.0.1', '192.168.0.44' ]
    )
  end

  # resource does not exist, so applying the resource should
  # change nothing
  let :resource_absent do
    Puppet::Type.type(:agentil_system).new(
      :name   => 'no_such_system',
      :ensure => 'absent'
    )
  end

  # resource does exist, applying should remove it
  let :resource_destroy do
    Puppet::Type.type(:agentil_system).new(
      :name   => 'PRO_sap01',
      :ensure => 'absent'
    )
  end

  let :resource_destroy_with_template do
    Puppet::Type.type(:agentil_system).new(
      :name   => 'PRO_sap01-2',
      :ensure => 'absent'
    )
  end

  let :resource_create do
    Puppet::Type.type(:agentil_system).new(
      :name      => 'DEV_sap03',
      :ensure    => 'present',
      :sid       => 'DEV',
      :host      => 'devhost.example.com',
      :ip        => [ '10.0.0.100', '10.0.0.101' ],
      :stack     => 'abap',
      :user      => 'SAP_PROBE',
      :client    => '000',
      :group     => 'LOGON_GROUP_01',
      :landscape => 'sapdev.example.com',
      :templates => [ 'Custom Template' ]
    )
  end

  let :resource_modify do
    Puppet::Type.type(:agentil_system).new(
      :name            => 'PRO_sap01-2',
      :ensure          => 'present',
      :sid             => 'P02',
      :stack           => 'java',
      :ip              => [ '192.168.0.88', '192.168.0.89' ],
      :templates       => [ 'Custom Template' ],
      :system_template => 'System Template for system id 1',
      :landscape       => 'sapdev.example.com'
    )
  end

  let :input do
    filename = tmpfilename('sapbasis_agentil.cfg')
    FileUtils.cp(my_fixture('sample.cfg'), filename)
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
    Puppet::Util::Agentil.initvars
    Puppet::Util::Agentil.stubs(:filename).returns input
    Puppet::Type.type(:agentil_system).stubs(:defaultprovider).returns described_class
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        state = run_in_catalog(resource_absent)
        File.read(input).should == File.read(my_fixture('sample.cfg'))
        state.changed?.should be_empty
      end
    end

    describe "when resource is currently present" do
      it "should remove the resource" do
        state = run_in_catalog(resource_destroy)
        File.read(input).should == File.read(my_fixture('output_remove.cfg'))
        state.changed?.should == [ resource_destroy ]
      end

      it "should remove the system template along with the system" do
        state = run_in_catalog(resource_destroy_with_template)
        File.read(input).should == File.read(my_fixture('output_remove_with_template.cfg'))
        state.changed?.should == [ resource_destroy_with_template ]
      end
    end
  end

  describe "ensure => present" do
    describe "when resource is currently absent" do
      it "should add the resource" do
        state = run_in_catalog(resource_create)
        File.read(input).should == File.read(my_fixture('output_add.cfg'))
        state.changed?.should == [ resource_create ]
      end
    end

    describe "when resource is currently present" do
      it "should do nothing if in sync" do
        run_in_catalog(resource_present).changed?.should be_empty
        File.read(input).should == File.read(my_fixture('sample.cfg'))
      end

      it "should modify attributes if not in sync" do
        run_in_catalog(resource_modify).changed?.should == [ resource_modify ]
        File.read(input).should == File.read(my_fixture('output_modify.cfg'))
      end
    end
  end
end
