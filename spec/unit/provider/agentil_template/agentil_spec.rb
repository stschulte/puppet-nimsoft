#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_template).provider(:agentil) do

  let :provider do
    described_class.new(
      :name     => 'NEW_TEMPLATE',
      :ensure   => :present,
      :template => template
    )
  end

  let :template do
    Puppet::Util::AgentilTemplate.new('NEW_TEMPLATE', template_element)
  end

  let :template_element do
    element = Puppet::Util::NimsoftSection.new('TEMPLATE1000000')
    element[:ID] = '1000001'
    element[:NAME] = 'NEW_TEMPLATE'
    element
  end

  let :resource do
    resource = Puppet::Type.type(:agentil_template).new(
      :name      => 'NEW_TEMPLATE',
      :ensure    => 'present',
      :system    => 'true',
      :jobs      => [ '122', '55' ],
      :monitors  => [ '22', '33' ],
      :instances => [ 'sap_inst00' ]
    )
    resource.provider = provider
    resource
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        instance = described_class.new(:name => 'NEW_TEMPLATE', :ensure => :present)
        instance.should be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'NEW_TEMPLATE')
        instance.should_not be_exists
      end
    end

    describe "create" do
      it "should add a new template" do
        resource
        Puppet::Util::AgentilTemplate.expects(:add).with('NEW_TEMPLATE').returns template
        template.expects(:system=).with(:true)
        template.expects(:jobs=).with([ '122', '55' ])
        template.expects(:monitors=).with([ '22', '33' ])
        template.expects(:instances=).with(['sap_inst00' ])
        provider.create
      end

      it "should raise an error if the system is missing" do
        resource = Puppet::Type.type(:agentil_template).new(
          :name        => 'FOOBAR',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error(Puppet::Error, 'Unable to create a new template without a system property')
      end
    end
    
    describe "destroy" do
      it "should delete a template" do
        resource
        Puppet::Util::AgentilTemplate.expects(:del).with('NEW_TEMPLATE')
        provider.destroy
      end

      it "should not complain about a missing system property" do
        resource = Puppet::Type.type(:agentil_user).new(
          :name   => 'NEW_TEMPLATE',
          :ensure => 'absent'
        )
        resource.provider = provider
        Puppet::Util::AgentilTemplate.expects(:del).with('NEW_TEMPLATE')
        provider.destroy
      end
    end
  end

  [:system, :jobs, :monitors, :instances].each do |property|
    describe "when managing #{property}" do
      it "should delegate the getter method to the AgentilUser object" do
        template.expects(property).returns "value_for_#{property}"
        provider.send(property).should == "value_for_#{property}"
      end

      it "should delegate the setter method to the AgentilUser object" do
        template.expects("#{property}=".intern).with "value_for_#{property}"
        provider.send("#{property}=","value_for_#{property}")
      end
    end
  end

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::AgentilTemplate.expects(:sync)
      provider.flush
    end
  end
end
