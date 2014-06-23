#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_landscape).provider(:agentil) do

  let :provider do
    described_class.new(
      :name              => 'sap01.example.com',
      :ensure            => :present,
      :agentil_landscape => landscape,
    )
  end

  let :landscape do
    Puppet::Util::AgentilLandscape.new(43, landscape_element)
  end

  let :landscape_element do
    element = Puppet::Util::NimsoftSection.new('LANDSCAPE43')
    element[:ID] = 43
    element[:NAME] = 'sap01.example.com'
    element[:SYSTEM_ID] = 'PRO'
    element[:MONITORTREE_MAXAGE] = '480'
    element[:COMPANY] = 'examplesoft'
    element[:ACTIVE] = 'true'
    element[:DESCRIPTION] = 'managed by puppet'
    element
  end

  let :resource do
    resource = Puppet::Type.type(:agentil_landscape).new(
      :name        => 'sap01.example.com',
      :ensure      => :present,
      :sid         => 'PRO',
      :company     => 'examplesoft',
      :description => 'managed by puppet'
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
      it "should add a new landscape" do
        resource
        Puppet::Util::Agentil.expects(:add_landscape).returns landscape
        landscape.expects(:name=).with 'sap01.example.com'
        landscape.expects(:sid=).with 'PRO'
        landscape.expects(:company=).with 'examplesoft'
        landscape.expects(:description=).with 'managed by puppet'
        provider.create
      end

      it "should raise an error if resource has not specified a sid" do
        resource = Puppet::Type.type(:agentil_landscape).new(
          :name        => 'sap01.example.com',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error(Puppet::Error, 'Unable to create a new landscape with no sid beeing specified')
      end
    end
    
    describe "destroy" do
      it "should delete a landscape" do
        resource
        Puppet::Util::Agentil.expects(:del_landscape).with(43)
        provider.destroy
      end

      it "should not complain about a missing sid" do
        resource = Puppet::Type.type(:agentil_landscape).new(
          :name        => 'sap01.example.com',
          :ensure      => :present
        )
        resource.provider = provider
        Puppet::Util::Agentil.expects(:del_landscape).with 43
        provider.destroy
      end
    end
  end

  [:sid, :description, :company].each do |property|
    describe "when managing #{property}" do
      it "should delegate the getter method to the AgentilLandscape class" do
        landscape.expects(property).returns "value_for_#{property}"
        provider.send(property).should == "value_for_#{property}"
      end

      it "should delegate the setter method to the AgentilLandscape class" do
        landscape.expects("#{property}=".intern).with "value_for_#{property}"
        provider.send("#{property}=","value_for_#{property}")
      end
    end
  end

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::Agentil.expects(:sync)
      provider.flush
    end
  end
end
