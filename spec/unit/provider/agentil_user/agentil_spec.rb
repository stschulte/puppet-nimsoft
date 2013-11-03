#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_user).provider(:agentil) do

  let :provider do
    described_class.new(
      :name   => 'SAP_PROBE',
      :ensure => :present,
      :user   => user
    )
  end

  let :user do
    Puppet::Util::AgentilUser.new('SAP_PROBE', user_element)
  end

  let :user_element do
    element = Puppet::Util::NimsoftSection.new('USER1')
    element[:ID] = '1'
    element[:TITLE] = 'SAP_PROBE'
    element[:USER] = 'SAP_PROBE'
    element[:ENCRYPTED_PASSWD] = 'some_encrypted_stuff'
    element
  end

  let :resource do
    resource = Puppet::Type.type(:agentil_user).new(
      :name     => 'SAP_PROBE',
      :ensure   => 'present',
      :password => 'some_encrypted_stuff'
    )
    resource.provider = provider
    resource
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        instance = described_class.new(:name => 'SAP_PROBE', :ensure => :present)
        instance.should be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'SAP_PROBE')
        instance.should_not be_exists
      end
    end

    describe "create" do
      it "should add a new user" do
        resource
        Puppet::Util::AgentilUser.expects(:add).with('SAP_PROBE').returns user
        user.expects(:password=).with 'some_encrypted_stuff'
        provider.create
      end

      it "should raise an error if the password is missing" do
        resource = Puppet::Type.type(:agentil_user).new(
          :name        => 'FOOBAR',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error(Puppet::Error, 'Unable to create a new user without a password')
      end
    end
    
    describe "destroy" do
      it "should delete a user" do
        resource
        Puppet::Util::AgentilUser.expects(:del).with('SAP_PROBE')
        provider.destroy
      end

      it "should not complain about a missing password" do
        resource = Puppet::Type.type(:agentil_user).new(
          :name   => 'SAP_PROBE',
          :ensure => 'absent'
        )
        resource.provider = provider
        Puppet::Util::AgentilUser.expects(:del).with('SAP_PROBE')
        provider.destroy
      end
    end
  end

  [:password].each do |property|
    describe "when managing #{property}" do
      it "should delegate the getter method to the AgentilUser object" do
        user.expects(property).returns "value_for_#{property}"
        provider.send(property).should == "value_for_#{property}"
      end

      it "should delegate the setter method to the AgentilUser object" do
        user.expects("#{property}=".intern).with "value_for_#{property}"
        provider.send("#{property}=","value_for_#{property}")
      end
    end
  end

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::AgentilUser.expects(:sync)
      provider.flush
    end
  end
end
