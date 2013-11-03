#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_landscape'

describe Puppet::Type.type(:agentil_landscape).provider(:agentil), '(integration)' do
  include PuppetlabsSpec::Files

  let :resource_present do
    Puppet::Type.type(:agentil_landscape).new(
      :name        => 'sapdev.example.com',
      :ensure      => 'present',
      :description => 'managed by puppet',
      :sid         => 'DEV'
    )
  end

  # resource does not exist, so applying the resource should
  # change nothing
  let :resource_absent do
    Puppet::Type.type(:agentil_landscape).new(
      :name   => 'no_such_landscape',
      :ensure => 'absent'
    )
  end

  # resource does exist, applying should remove it
  let :resource_destroy do
    Puppet::Type.type(:agentil_landscape).new(
      :name   => 'sap01.example.com',
      :ensure => 'absent'
    )
  end

  let :resource_create do
    Puppet::Type.type(:agentil_landscape).new(
      :name        => 'sap03.example.com',
      :ensure      => 'present',
      :sid         => 'QAS',
      :company     => 'foo',
      :description => 'bar'
    )
  end

  let :resource_modify do
    Puppet::Type.type(:agentil_landscape).new(
      :name        => 'sapdev.example.com',
      :ensure      => 'present',
      :description => 'managed by puppet',
      :company     => 'another company',
      :sid         => 'QAS'
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
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Type.type(:agentil_landscape).stubs(:defaultprovider).returns described_class
    Puppet::Util::AgentilLandscape.stubs(:filename).returns input
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        run_in_catalog(resource_absent)
        File.read(input).should == File.read(my_fixture('sample.cfg'))
      end
    end

    describe "when resource is currently present" do
      it "should remove the resource nothing" do
        run_in_catalog(resource_destroy)
        File.read(input).should == File.read(my_fixture('output_remove.cfg'))
      end
    end
  end

  describe "ensure => present" do
    describe "when resource is currently absent" do
      it "should add the resource" do
        run_in_catalog(resource_create)
        File.read(input).should == File.read(my_fixture('output_add.cfg'))
      end
    end

    describe "when resource is currently present" do
      it "should do nothing if in sync" do
        run_in_catalog(resource_present)
        File.read(input).should == File.read(my_fixture('sample.cfg'))
      end

      it "should modify attributes if not in sync" do
        run_in_catalog(resource_modify)
        File.read(input).should == File.read(my_fixture('output_modify.cfg'))
      end
    end
  end
end
