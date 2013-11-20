#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_system'

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
      :template  => 'System Template for system id 3',
      :templates => [ 'Custom Template' ]
    )
  end

  let :resource_modify do
    Puppet::Type.type(:agentil_system).new(
      :name      => 'PRO_sap01-2',
      :ensure    => 'present',
      :sid       => 'P02',
      :stack     => 'java',
      :ip        => [ '192.168.0.88', '192.168.0.89' ],
      :templates => [ 'Custom Template' ],
      :template  => 'System Template for system id 1',
      :landscape => 'sapdev.example.com'
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
    Puppet::Util::AgentilLandscape.initvars
    Puppet::Util::AgentilSystem.initvars
    Puppet::Util::AgentilTemplate.initvars
    Puppet::Util::AgentilUser.initvars
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Type.type(:agentil_system).stubs(:defaultprovider).returns described_class
    Puppet::Util::AgentilSystem.stubs(:filename).returns input
    Puppet::Util::AgentilLandscape.stubs(:filename).returns input
    Puppet::Util::AgentilTemplate.stubs(:filename).returns input
    Puppet::Util::AgentilUser.stubs(:filename).returns input
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        run_in_catalog(resource_absent).changed?.should be_empty
        File.read(input).should == File.read(my_fixture('sample.cfg'))
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
        File.read(input).should == File.read(my_fixture('sample.cfg'))
      end

      it "should modify attributes if not in sync" do
        run_in_catalog(resource_modify).changed?.should == [ resource_modify ]
        File.read(input).should == File.read(my_fixture('output_modify.cfg'))
      end
    end
  end
end
