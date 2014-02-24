#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_process).provider(:nimsoft) do

  let :config do
    config = Puppet::Util::NimsoftConfig.new('some_file')
    config.path('watchers/bar')
    config.stubs(:sync)
    config
  end

  let :watchers do
    config.child('watchers')
  end

  let :element do
    element = Puppet::Util::NimsoftSection.new('cron', watchers)
    element[:active] = 'yes'
    element[:process] = 'cron'
    element[:description] = 'foo profile'
    element[:process_count_type] = 'gte'
    element[:process_count] = 1
    element[:report] = 'up, down'
    element[:track_by_pid] = 'no'
    element[:process_restart] = 'no'
    element[:proc_cmd_line] = '/usr/sbin/cron'
    element[:scan_proc_cmd_line] = 'no'
    element
  end

  let :provider do
    provider = described_class.new(:name => 'cron', :ensure => :present, :element => element)
    resource = Puppet::Type.type(:nimsoft_process).new(
      :name => 'cron'
    )
    resource.provider = provider
    provider
  end

  let :provider_new do
    provider = described_class.new(:name => 'consolekit')
    resource = Puppet::Type.type(:nimsoft_process).new(
      :name        => 'consolekit',
      :ensure      => 'present',
      :active      => 'yes',
      :trackpid    => 'yes',
      :description => 'a short test',
      :pattern     => '/usr/sbin/console-kit-daemon --no-daemon',
      :match       => 'cmdline',
      :count       => '>= 1',
      :alarm_on    => [ 'down', 'restart' ]
    )
    resource.provider = provider
    provider
  end

  before :each do
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::NimsoftConfig.stubs(:add).with('/opt/nimsoft/probes/system/processes/processes.cfg').returns config
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
        described_class.root.children.map(&:name).should == [ 'bar' ]
        provider_new.create
        described_class.root.children.map(&:name).should == [ 'bar', 'consolekit' ]
      end

      it "should set the correct attributes after adding the section" do
        provider_new.create

        child = described_class.root.child('consolekit')
        child.should_not be_nil

        child[:active].should == 'yes'
        child[:description].should == 'a short test'
        child[:process_count_type].should == 'gte'
        child[:process_count].should == '1'
        child[:report].should == 'down, restart'
        child[:track_by_pid].should == 'yes'
        child[:proc_cmd_line].should == '/usr/sbin/console-kit-daemon --no-daemon'
        child[:scan_proc_cmd_line].should == 'yes'
      end
    end

    describe "destroy" do
      it "should destroy the specific section" do
        provider = described_class.new(:name => element.name, :ensure => :present, :element => element)

        described_class.root.children.map(&:name).should == [ 'bar', 'cron' ]
        provider.destroy
        described_class.root.children.map(&:name).should == [ 'bar' ]
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

  describe "when managing description" do
    it "should return the description field" do
      element[:description] = 'old_description'
      provider.description.should == 'old_description'
    end

    it "should update the description field with the new value" do
      element.expects(:[]=).with(:description, 'new_description')
      provider.description = 'new_description'
    end
  end

  describe "when managing pattern" do
    it "should return the process field when match is nameonly" do
      provider.resource[:match] = 'nameonly'
      element[:process] = 'cron'
      element[:proc_cmd_line] = '/usr/sbin/cron'
      provider.pattern.should == 'cron'
    end

    it "should return the proc_cmd_line field when match is cmdline" do
      provider.resource[:match] = 'cmdline'
      element[:process] = 'cron'
      element[:proc_cmd_line] = '/usr/sbin/cron'
      provider.pattern.should == '/usr/sbin/cron'
    end

    it "should update the process field when match is nameonly" do
      provider.resource[:match] = 'nameonly'
      element.expects(:[]=).with(:process, 'foo')
      element.expects(:[]=).with(:proc_cmd_line, 'foo').never
      provider.pattern = 'foo'
    end

    it "should update the proc_cmd_line field when match is cmdline" do
      provider.resource[:match] = 'cmdline'
      element.expects(:[]=).with(:process, 'foo').never
      element.expects(:[]=).with(:proc_cmd_line, 'foo')
      provider.pattern = 'foo'
    end
  end

  describe "when managing trackpid" do
    it "should return :yes when track_by_pid is true" do
      element[:track_by_pid] = 'yes'
      provider.trackpid.should == :yes
    end

    it "should return :no when track_by_pid is false" do
      element[:track_by_pid] = 'no'
      provider.trackpid.should == :no
    end

    it "should set track_by_pid to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:track_by_pid, 'yes')
      provider.trackpid = :yes
    end

    it "should set track_by_pid to \"no\" when new value is :no" do
      element.expects(:[]=).with(:track_by_pid, 'no')
      provider.trackpid = :no
    end
  end

  describe "when managing count" do
    it "should return the correct value if type is eq" do
      element[:process_count_type] = 'eq'
      element[:process_count] = '10'
      provider.count.should == '10'
    end

    it "should return the correct value if type is gte" do
      element[:process_count_type] = 'gte'
      element[:process_count] = '1'
      provider.count.should == '>= 1'
    end

    it "should return the correct value if type is ge" do
      element[:process_count_type] = 'ge'
      element[:process_count] = '5'
      provider.count.should == '>= 5'
    end

    it "should return the correct value if type is gt" do
      element[:process_count_type] = 'gt'
      element[:process_count] = '21'
      provider.count.should == '> 21'
    end

    it "should return the correct value if type is lte" do
      element[:process_count_type] = 'lte'
      element[:process_count] = '9'
      provider.count.should == '<= 9'
    end

    it "should return the correct value if type is le" do
      element[:process_count_type] = 'le'
      element[:process_count] = '99'
      provider.count.should == '<= 99'
    end

    it "should return the correct value if type is lt" do
      element[:process_count_type] = 'lt'
      element[:process_count] = '2'
      provider.count.should == '< 2'
    end

    it "should set type to eq if new value has no prefix" do
      element.expects(:[]=).with(:process_count, '123')
      element.expects(:[]=).with(:process_count_type, 'eq')
      provider.count = '123'
    end

    it "should set type to lt if new value has prefix <" do
      element.expects(:[]=).with(:process_count, '40')
      element.expects(:[]=).with(:process_count_type, 'lt')
      provider.count = '< 40'
    end
    
    it "should set type to lte if new value has prefix <=" do
      element.expects(:[]=).with(:process_count, '2')
      element.expects(:[]=).with(:process_count_type, 'lte')
      provider.count = '<= 2'
    end
    
    it "should set type to gt if new value has prefix >" do
      element.expects(:[]=).with(:process_count, '23')
      element.expects(:[]=).with(:process_count_type, 'gt')
      provider.count = '> 23'
    end
    
    it "should set type to gte if new value as prefix >=" do
      element.expects(:[]=).with(:process_count, '29')
      element.expects(:[]=).with(:process_count_type, 'gte')
      provider.count = '>= 29'
    end
  end

  describe "alarm_on" do
    it "should return :up when report is \"up\"" do
      element[:report] = 'up'
      provider.alarm_on.should == [ :up ]
    end

    it "should return :down when report is \"down\"" do
      element[:report] = 'down'
      provider.alarm_on.should == [ :down ]
    end

    it "should return :restart when report is \"restart\"" do
      element[:report] = 'restart'
      provider.alarm_on.should == [ :restart ]
    end

    it "should split report and return an array" do
      element[:report] = 'up, down'
      provider.alarm_on.should == [ :up, :down ]
      element[:report] = 'up, restart, down'
      provider.alarm_on.should == [ :up, :restart, :down ]
    end

    it "should update report when setting to a single value" do
      element.expects(:[]=).with(:report, 'up')
      provider.alarm_on = [ :up ]
    end

    it "should update report with the joined array when setting to an array"  do
      element.expects(:[]=).with(:report, 'down, restart')
      provider.alarm_on = [ :down, :restart ]
    end
  end

  describe "match" do
    it "should return nameonly when scan_proc_cmd_line is \"no\"" do
      element[:scan_proc_cmd_line] = 'no'
      provider.match.should == :nameonly
    end

    it "should return cmdline when scan_proc_cmd_line is \"yes\"" do
      element[:scan_proc_cmd_line] = 'yes'
      provider.match.should == :cmdline
    end

    it "should return absent when scan_proc_cmd_line is absent" do
      element.del_attr(:scan_proc_cmd_line)
      provider.match.should == :absent
    end

    it "should update scan_proc_cmd_line to \"no\" when setting to nameonly" do
      element.expects(:[]=).with(:scan_proc_cmd_line, 'no')
      provider.match = :nameonly
    end

    it "should update scan_proc_cmd_line to \"yes\" when setting to cmdline" do
      element.expects(:[]=).with(:scan_proc_cmd_line, 'yes')
      provider.match = :cmdline
    end
  end
end
