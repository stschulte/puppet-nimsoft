#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_system).provider(:agentil) do

  let :provider do
    described_class.new(
      :name      => 'ABC_sap01',
      :ensure    => :present,
      :system    => system
    )
  end

  let :system do
    Puppet::Util::AgentilSystem.new('sap01.example.com', system_element)
  end

  let :system_element do
    element = Puppet::Util::NimsoftSection.new('SYSTEM5')
    element[:ID] = '5'
    element[:NAME] = 'ABC_sap01'
    element[:SYSTEM_ID] = 'ABC'
    element[:HOST] = 'sap01.example.com'
    element[:JAVA_ENABLED] = 'false'
    element[:ABAP_ENABLED] = 'true'
    element
  end

  let :resource do
    resource = Puppet::Type.type(:agentil_system).new(
      :name      => 'ABC_sap01',
      :ensure    => :present,
      :sid       => 'ABC',
      :landscape => 'ABC',
      :host      => 'sap01.example.com',
      :ip        => [ '192.168.0.1', '192.168.0.2' ],
      :stack     => 'abap',
      :client    => '000',
      :user      => 'SAP_PROBE',
      :group     => 'LOGON_GROUP_01',
      :template  => 'System Template for system ABC_sap01',
      :templates => [ 'Template 1', 'Template 2' ]
    )
    resource.provider = provider
    resource
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        instance = described_class.new(:name => 'foo', :ensure => :present)
        instance.should be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'foo')
        instance.should_not be_exists
      end
    end

    describe "create" do
      it "should add a new system" do
        resource
        Puppet::Util::AgentilSystem.expects(:add).with('ABC_sap01').returns system
        system.expects(:sid=).with 'ABC'
        system.expects(:host=).with 'sap01.example.com'
        system.expects(:ip=).with ['192.168.0.1', '192.168.0.2']
        system.expects(:stack=).with :abap
        system.expects(:user=).with 'SAP_PROBE'
        system.expects(:client=).with '000'
        system.expects(:group=).with 'LOGON_GROUP_01'
        system.expects(:landscape=).with 'ABC'
        system.expects(:template=).with 'System Template for system ABC_sap01'
        system.expects(:templates=).with [ 'Template 1', 'Template 2' ]

        provider.create
      end

      it "should raise an error if mandatory properties are missing" do
        resource = Puppet::Type.type(:agentil_system).new(
          :name        => 'ABC_sap01',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error Puppet::Error, 'Cannot create system with no sid'
      end
    end
    
    describe "destroy" do
      it "should delete a system" do
        resource
        Puppet::Util::AgentilSystem.expects(:del).with('ABC_sap01')
        provider.destroy
      end

      it "should not complain about missing fields" do
        resource = Puppet::Type.type(:agentil_system).new(
          :name        => 'ABC_sap01',
          :ensure      => :absent
        )
        resource.provider = provider
        Puppet::Util::AgentilSystem.expects(:del).with('ABC_sap01')
        provider.destroy
      end
    end
  end

  [:sid, :host, :ip, :stack, :user, :client, :group, :landscape, :template, :templates]. each do |property|
    describe "when managing #{property}" do
      it "should delegate the getter method to the AgentilLandscape class" do
        system.expects(property).returns "value_for_#{property}"
        provider.send(property).should == "value_for_#{property}"
      end

      it "should delegate the setter method to the AgentilLandscape class" do
        system.expects("#{property}=".intern).with "value_for_#{property}"
        provider.send("#{property}=","value_for_#{property}")
      end
    end
  end

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::AgentilSystem.expects(:sync)
      provider.flush
    end
  end
end
