#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_instance).provider(:agentil), '(integration)' do
  include PuppetlabsSpec::Files

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

  let :input do
    filename = tmpfilename('sapbasis_agentil.cfg')
    FileUtils.cp(my_fixture('sample.cfg'), filename)
    filename
  end

  before :each do
    Puppet::Util::AgentilJob177.initvars
    Puppet::Util::AgentilTemplate.initvars
    Puppet::Util::NimsoftConfig.initvars

    Puppet::Type.type(:agentil_instance).stubs(:defaultprovider).returns described_class

    described_class.stubs(:filename).returns input
    Puppet::Util::AgentilTemplate.stubs(:filename).returns input
  end

  describe "adding a resource" do
    it "should add a new instance to the job 177 customization" do
      resource = Puppet::Type.type(:agentil_instance).new(
        :name        => 'sap01_PRO_02',
        :ensure      => 'present',
        :mandatory   => 'true',
        :criticality => 'warning',
        :autoclear   => 'false',
        :template    => 'System Template for system id 1'
      )

      run_in_catalog(resource)
      File.read(input).should == File.read(my_fixture('add_to_existing.cfg'))
    end

    it "should use default values for all properties" do
      resource = Puppet::Type.type(:agentil_instance).new(
        :name     => 'sap01_PRO_10',
        :ensure   => 'present',
        :template => 'System Template for system id 1'
      )

      run_in_catalog(resource)
      File.read(input).should == File.read(my_fixture('add_to_existing_default.cfg'))
    end

    it "should create the job 177 customization if not customized before" do
      resource = Puppet::Type.type(:agentil_instance).new(
        :name     => 'sap01_DEV_01',
        :ensure   => 'present',
        :template => 'System Template for system id 4'
      )

      run_in_catalog(resource)
      File.read(input).should == File.read(my_fixture('create_new.cfg'))
    end
  end

  describe "when modifying a resource" do
    it "should do nothing if in sync" do
      resource = Puppet::Type.type(:agentil_instance).new(
        :name        => 'sap01_PRO_01',
        :ensure      => 'present',
        :mandatory   => 'true',
        :criticality => 'critical',
        :autoclear   => 'true',
        :template    => 'System Template for system id 1'
      )
      run_in_catalog(resource)

      File.read(input).should == File.read(my_fixture('sample.cfg'))
    end

    it "should modify autoclear if autoclear is out of sync" do
      resource = Puppet::Type.type(:agentil_instance).new(
        :name        => 'sap01_PRO_01',
        :ensure      => 'present',
        :mandatory   => 'true',
        :criticality => 'critical',
        :autoclear   => 'false',
        :template    => 'System Template for system id 1'
      )
      run_in_catalog(resource)

      File.read(input).should == File.read(my_fixture('mod_autoclear.cfg'))
    end

    it "should modify mutliple out-of-sync attributes" do
      resource = Puppet::Type.type(:agentil_instance).new(
        :name        => 'sap01_PRO_00',
        :ensure      => 'present',
        :mandatory   => 'true',
        :criticality => 'major',
        :autoclear   => 'true',
        :template    => 'System Template for system id 1'
      )
      run_in_catalog(resource)

      File.read(input).should == File.read(my_fixture('mod_multiple.cfg'))
    end

    describe "when template is out of sync" do
      it "should remove the instance from the old job customization" do
        resource = Puppet::Type.type(:agentil_instance).new(
          :name        => 'sap01_PRO_00',
          :ensure      => 'present',
          :criticality => 'info',
          :template    => 'System Template for system id 2'
        )
        run_in_catalog(resource)
        File.read(input).should == File.read(my_fixture('move_different_template.cfg'))
      end

      it "should remove the customization if this was the last instance" do
        resource = Puppet::Type.type(:agentil_instance).new(
          :name     => 'sap01-2_PRO_00',
          :ensure   => :present,
          :template => 'System Template for system id 4'
        )
        run_in_catalog(resource)
        File.read(input).should == File.read(my_fixture('move_different_template_and_delete.cfg'))
      end
    end
  end
end
