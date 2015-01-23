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
        expect(provider).to be_exist
      end

      it "should return false if the instance is absent" do
        expect(provider_new).to_not be_exist
      end
    end

    describe "create" do
      it "should add a new section" do
        expect(described_class.root.children.map(&:name)).to eq([ 'bar' ])
        provider_new.create
        expect(described_class.root.children.map(&:name)).to eq([ 'bar', 'consolekit' ])
      end

      it "should set the correct attributes after adding the section" do
        provider_new.create

        child = described_class.root.child('consolekit')
        expect(child).to_not be_nil

        expect(child[:active]).to eq('yes')
        expect(child[:description]).to eq('a short test')
        expect(child[:process_count_type]).to eq('gte')
        expect(child[:process_count]).to eq('1')
        expect(child[:report]).to eq('down, restart')
        expect(child[:track_by_pid]).to eq('yes')
        expect(child[:proc_cmd_line]).to eq('/usr/sbin/console-kit-daemon --no-daemon')
        expect(child[:scan_proc_cmd_line]).to eq('yes')
      end
    end

    describe "destroy" do
      it "should destroy the specific section" do
        provider = described_class.new(:name => element.name, :ensure => :present, :element => element)

        expect(described_class.root.children.map(&:name)).to eq([ 'bar', 'cron' ])
        provider.destroy
        expect(described_class.root.children.map(&:name)).to eq([ 'bar' ])
      end
    end
  end

  describe "when managing active" do
    it "should return :yes when active" do
      element[:active] = 'yes'
      expect(provider.active).to eq(:yes)
    end

    it "should return :no when not active" do
      element[:active] = 'no'
      expect(provider.active).to eq(:no)
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
      expect(provider.description).to eq('old_description')
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
      expect(provider.pattern).to eq('cron')
    end

    it "should return the proc_cmd_line field when match is cmdline" do
      provider.resource[:match] = 'cmdline'
      element[:process] = 'cron'
      element[:proc_cmd_line] = '/usr/sbin/cron'
      expect(provider.pattern).to eq('/usr/sbin/cron')
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
      expect(provider.trackpid).to eq(:yes)
    end

    it "should return :no when track_by_pid is false" do
      element[:track_by_pid] = 'no'
      expect(provider.trackpid).to eq(:no)
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
    it "should return the correct value if type is equal" do
      element[:process_count_type] = 'equal'
      element[:process_count] = '10'
      expect(provider.count).to eq('10')
    end

    it "should return the correct value if type is gte" do
      element[:process_count_type] = 'gte'
      element[:process_count] = '1'
      expect(provider.count).to eq('>= 1')
    end

    it "should return the correct value if type is ge" do
      element[:process_count_type] = 'ge'
      element[:process_count] = '5'
      expect(provider.count).to eq('>= 5')
    end

    it "should return the correct value if type is gt" do
      element[:process_count_type] = 'gt'
      element[:process_count] = '21'
      expect(provider.count).to eq('> 21')
    end

    it "should return the correct value if type is lte" do
      element[:process_count_type] = 'lte'
      element[:process_count] = '9'
      expect(provider.count).to eq('<= 9')
    end

    it "should return the correct value if type is le" do
      element[:process_count_type] = 'le'
      element[:process_count] = '99'
      expect(provider.count).to eq('<= 99')
    end

    it "should return the correct value if type is lt" do
      element[:process_count_type] = 'lt'
      element[:process_count] = '2'
      expect(provider.count).to eq('< 2')
    end

    it "should set type to equal if new value has no prefix" do
      element.expects(:[]=).with(:process_count, '123')
      element.expects(:[]=).with(:process_count_type, 'equal')
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
      expect(provider.alarm_on).to eq([ :up ])
    end

    it "should return :down when report is \"down\"" do
      element[:report] = 'down'
      expect(provider.alarm_on).to eq([ :down ])
    end

    it "should return :restart when report is \"restart\"" do
      element[:report] = 'restart'
      expect(provider.alarm_on).to eq([ :restart ])
    end

    it "should split report and return an array" do
      element[:report] = 'up, down'
      expect(provider.alarm_on).to eq([ :up, :down ])
      element[:report] = 'up, restart, down'
      expect(provider.alarm_on).to eq([ :up, :restart, :down ])
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
      expect(provider.match).to eq(:nameonly)
    end

    it "should return cmdline when scan_proc_cmd_line is \"yes\"" do
      element[:scan_proc_cmd_line] = 'yes'
      expect(provider.match).to eq(:cmdline)
    end

    it "should return absent when scan_proc_cmd_line is absent" do
      element.del_attr(:scan_proc_cmd_line)
      expect(provider.match).to eq(:absent)
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
