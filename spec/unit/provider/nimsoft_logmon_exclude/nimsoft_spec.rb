#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_exclude).provider(:nimsoft) do

  let :config do
    config = Puppet::Util::NimsoftConfig.new('some_file')
    config.path('profiles/some_profile/excludes/some_exclude')
    config.stubs(:sync)
    config
  end

  let :excludes do
    config.child('profiles').child('some_profile').child('excludes')
  end

  let :element do
    element = Puppet::Util::NimsoftSection.new('foo', excludes)
    element[:active] = 'yes'
    element[:match] = '/FILE_SYSTEM_FULL/'
    element
  end

  let :provider do
    described_class.new(:name => element.name, :ensure => :present, :element => element)
  end

  let :provider_new do
    provider = described_class.new(:name => 'some_profile/new exclude')
    resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(
      :name          => 'some_profile/new exclude',
      :ensure        => 'present',
      :active        => 'no',
      :match         => 'INFO*'
    )
    resource.provider = provider
    provider
  end

  before :each do
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::NimsoftConfig.stubs(:add).with('/opt/nimsoft/probes/system/logmon/logmon.cfg').returns config
    described_class.initvars
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        provider.should be_exist
      end

      it "should return false if the instance is absent" do
        provider_new.should_not be_exist
      end
    end

    describe "create" do
      it "should add a new section" do
        excludes.children.map(&:name).should == [ 'some_exclude' ]
        provider_new.create
        excludes.children.map(&:name).should == [ 'some_exclude', 'new exclude' ]
      end

      it "should complain about a missing profile" do
        provider = described_class.new(:name => 'no_such_profile/new exclude')
        resource = Puppet::Type.type(:nimsoft_logmon_exclude).new(:name => 'no_such_profile/new exclude', :ensure => 'present')
        resource.provider = provider
        expect { provider.create }.to raise_error Puppet::Error, /Profile no_such_profile not found/
      end

      it "should add the correct attributes after adding the section" do
        provider_new.create

        child = excludes.child('new exclude')
        child.should_not be_nil
        child[:active].should == 'no'
        child[:match].should == 'INFO*'
      end
    end

    describe "destroy" do
      it "should destroy the specific section" do
        provider = described_class.new(:name => element.name, :ensure => :present, :element => element)

        excludes.children.map(&:name).should == [ 'some_exclude', 'foo' ]
        provider.destroy
        excludes.children.map(&:name).should == [ 'some_exclude' ]
      end
    end
  end

  describe "when managing active" do
    it "should return :yes when active" do
      element[:active] = 'yes'
      provider.active.should == :yes
    end

    it "should return :no when not active" do
      element[:active] = 'no'
      provider.active.should == :no
    end

    it "should set active to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:active, 'yes')
      provider.active = :yes
    end

    it "should set active to \"no\" when new value is :no" do
      element.expects(:[]=).with(:active, 'no')
      provider.active = :no
    end
  end

  describe "when managing pattern" do
    it "should get the match attribute" do
      element[:match] = '^DEBUG: .*$'
      provider.match.should == '^DEBUG: .*$'
    end

    it "should set the match attribute" do
      element.expects(:[]=).with(:match, 'DEBUG*')
      provider.match = 'DEBUG*'
    end
  end
end
