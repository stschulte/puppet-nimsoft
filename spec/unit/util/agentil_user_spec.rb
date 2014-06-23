#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil'
require 'puppet/util/agentil_user'
require 'puppet/util/nimsoft_section'

describe Puppet::Util::AgentilUser do

  before :each do
    Puppet::Util::Agentil.initvars
  end

  let :user do
    described_class.new(13, user_element)
  end

  let :new_user do
    described_class.new(42, new_user_element)
  end

  let :user_element do
    element = Puppet::Util::NimsoftSection.new('USER13')
    element[:ID] = '13'
    element[:ENCRYPTED_PASSWD] = 'some_encrypted_stuff'
    element[:TITLE] = 'SAP_PRO'
    element[:USER] = 'SAP_PRO'
    element
  end

  let :new_user_element do
    element = Puppet::Util::NimsoftSection.new('USER42')
    element[:ID] = '42'
    element
  end


  describe "id" do
    it "should return the id as integer" do
      user.id.should == 13
    end
  end

  describe "getting password" do
    it "should return nil if attribute ENCRYPTED_PASSWD does not exist" do
      new_user.password.should be_nil
    end

    it "should return the value of attribute ENCRYPTED_PASSWD" do
      user.password.should == 'some_encrypted_stuff'
    end
  end
  
  describe "setting password" do
    it "should modify attribute ENCRYPTED_PASSWD" do
      user.element.expects(:[]=).with(:ENCRYPTED_PASSWD, 'foo')
      user.password = 'foo'
    end
  end
end
