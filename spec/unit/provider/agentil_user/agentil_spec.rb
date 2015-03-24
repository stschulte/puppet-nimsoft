#! /usr/bin/env ruby

require 'spec_helper'

require 'puppet/util/agentil'
require 'puppet/util/nimsoft_section'

describe Puppet::Type.type(:agentil_user).provider(:agentil) do

  let :provider do
    described_class.new(
      :name         => 'SAP_PROBE',
      :ensure       => :present,
      :agentil_user => user
    )
  end

  let :user do
    Puppet::Util::AgentilUser.new(815, user_element)
  end

  let :user_element do
    {
      "ID"               => "815",
      "TITLE"            => "SAP_PROBE",
      "ENCRYPTED_PASSWD" => 'some_encrypted_stuff',
      "USER"             => "SAP_PROBE"
    }
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
        expect(instance).to be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'SAP_PROBE')
        expect(instance).to_not be_exists
      end
    end

    describe "create" do
      it "should add a new user" do
        resource
        Puppet::Util::Agentil.expects(:add_user).returns user
        user.expects(:name=).with 'SAP_PROBE'
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
        Puppet::Util::Agentil.expects(:del_user).with 815
        provider.destroy
      end

      it "should not complain about a missing password" do
        resource = Puppet::Type.type(:agentil_user).new(
          :name   => 'SAP_PROBE',
          :ensure => 'absent'
        )
        resource.provider = provider
        Puppet::Util::Agentil.expects(:del_user).with 815
        provider.destroy
      end
    end
  end

  [:password].each do |property|
    describe "when managing #{property}" do
      it "should delegate the getter method to the AgentilUser object" do
        user.expects(property).returns "value_for_#{property}"
        expect(provider.send(property)).to eq("value_for_#{property}")
      end

      it "should delegate the setter method to the AgentilUser object" do
        user.expects("#{property}=".intern).with "value_for_#{property}"
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
