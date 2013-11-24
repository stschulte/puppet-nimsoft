#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_profile).provider(:nimsoft) do

  let :config do
    config = Puppet::Util::NimsoftConfig.new('some_file')
    config.path('profiles/some_profile')
    config.stubs(:sync)
    config
  end

  let :profiles do
    config.child('profiles')
  end

  let :element do
    element = Puppet::Util::NimsoftSection.new('foo', profiles)
    element[:active] = 'yes'
    element[:scanfile] = '/var/log/messages'
    element[:scanmode] = 'updates'
    element[:interval] = '1 min'
    element[:alarm] = 'yes'
    element[:qos] = 'no'
    element[:max_alarm_sev] = '5'
    element.path('watchers/nfs_error')[:active] = 'yes'
    element.path('watchers/failed_login')[:active] = 'yes'
    element
  end

  let :provider do
    described_class.new(:name => element.name, :ensure => :present, :element => element)
  end

  let :provider_new do
    provider = described_class.new(:name => 'new profile')
    resource = Puppet::Type.type(:nimsoft_logmon_profile).new(
      :name          => 'new_profile',
      :ensure        => 'present',
      :active        => 'yes',
      :file          => '/var/log/secure',
      :mode          => 'updates',
      :interval      => '30 min',
      :qos           => 'no',
      :alarm         => 'yes',
      :alarm_maxserv => 'warning'
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
        described_class.root.children.map(&:name).should == [ 'some_profile' ]
        provider_new.create
        described_class.root.children.map(&:name).should == [ 'some_profile', 'new profile' ]
      end

      it "should add set the correct attributes after adding the section" do
        provider_new.create

        child = described_class.root.child('new profile')
        child.should_not be_nil
        child[:active].should == 'yes'
        child[:scanfile].should == '/var/log/secure'
        child[:scanmode].should == 'updates'
        child[:interval].should == '30 min'
        child[:qos].should == 'no'
        child[:alarm].should == 'yes'
        child[:max_alarm_sev].should == '2'
      end
    end

    describe "destroy" do
      it "should destroy the specific section" do
        provider = described_class.new(:name => element.name, :ensure => :present, :element => element)

        described_class.root.children.map(&:name).should == [ 'some_profile', 'foo' ]
        provider.destroy
        described_class.root.children.map(&:name).should == [ 'some_profile' ]
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

  describe "when managing file" do
    it "should get the scanfile attribute" do
      element[:scanfile] = '/var/log/boot.log'
      provider.file.should == '/var/log/boot.log'
    end

    it "should set the scanfile attribute" do
      element.expects(:[]=).with(:scanfile, '/var/log/kern.log')
      provider.file = '/var/log/kern.log'
    end
  end

  describe "when managing mode" do
    it "should get the symbolized scanmode attribute" do
      element[:scanmode] = 'cat'
      provider.mode.should == :cat
    end

    it "should set the scanmode attribute" do
      element.expects(:[]=).with(:scanmode, 'full_time')
      provider.mode = :full_time
    end
  end

  describe "when managing interval" do
    it "should get the interval attribute" do
      element[:interval] = '1 min'
      provider.interval.should == '1 min'
    end

    it "should set the interval attribute" do
      element.expects(:[]=).with(:interval, '30 sec')
      provider.interval = '30 sec'
    end
  end

  describe "when managing qos" do
    it "should return :yes when qos is enabled" do
      element[:qos] = 'yes'
      provider.qos.should == :yes
    end

    it "should return :no when qos is disabled" do
      element[:qos] = 'no'
      provider.qos.should == :no
    end

    it "should set qos to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:qos, 'yes')
      provider.qos = :yes
    end

    it "should set qos to \"no\" when new value is :no" do
      element.expects(:[]=).with(:qos, 'no')
      provider.qos = :no
    end
  end

  describe "when managing alarm" do
    it "should return :yes when alarm is enabled" do
      element[:alarm] = 'yes'
      provider.alarm.should == :yes
    end

    it "should return :no when alarm is disabled" do
      element[:alarm] = 'no'
      provider.alarm.should == :no
    end

    it "should set alarm to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:alarm, 'yes')
      provider.alarm = :yes
    end

    it "should set alarm to \"no\" when new value is :no" do
      element.expects(:[]=).with(:alarm, 'no')
      provider.alarm = :no
    end
  end

  describe "when managing alarm_maxserv" do
    it "should return :info when max_alarm_sev is 1" do
      element[:max_alarm_sev] = '1'
      provider.alarm_maxserv.should == :info
    end

    it "should return :warning when max_alarm_sev is 2" do
      element[:max_alarm_sev] = '2'
      provider.alarm_maxserv.should == :warning
    end

    it "should return :minor when max_alarm_sev is 3" do
      element[:max_alarm_sev] = '3'
      provider.alarm_maxserv.should == :minor
    end

    it "should return :major when max_alarm_sev is 4" do
      element[:max_alarm_sev] = '4'
      provider.alarm_maxserv.should == :major
    end

    it "should return :critical when max_alarm_sev is 5" do
      element[:max_alarm_sev] = '5'
      provider.alarm_maxserv.should == :critical
    end

    it "should set max_alarm_sev to 1 if new severity is :info" do
      element.expects(:[]=).with(:max_alarm_sev, '1')
      provider.alarm_maxserv = :info
    end

    it "should set max_alarm_sev to 2 if new severity is :warning" do
      element.expects(:[]=).with(:max_alarm_sev, '2')
      provider.alarm_maxserv = :warning
    end

    it "should set max_alarm_sev to 3 if new severity is :minor" do
      element.expects(:[]=).with(:max_alarm_sev, '3')
      provider.alarm_maxserv = :minor
    end

    it "should set max_alarm_sev to 4 if new severity is :major" do
      element.expects(:[]=).with(:max_alarm_sev, '4')
      provider.alarm_maxserv = :major
    end

    it "should set max_alarm_sev to 5 if new severity is :critical" do
      element.expects(:[]=).with(:max_alarm_sev, '5')
      provider.alarm_maxserv = :critical
    end
  end
end
