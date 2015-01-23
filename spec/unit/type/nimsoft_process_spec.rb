#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_process) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :pattern, :active, :match, :trackpid, :count, :description, :alarm_on].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do
    describe "for pattern" do
      it "should allow a single command" do
        expect(described_class.new(:name => 'foo', :pattern => 'cron')[:pattern]).to eq('cron')
      end

      it "should allow an absolute path" do
        expect(described_class.new(:name => 'foo', :pattern => '/usr/sbin/cron')[:pattern]).to eq('/usr/sbin/cron')
      end

      it "should allow a process with arguments" do
        expect(described_class.new(:name => 'foo', :pattern => '/usr/sbin/rsyslogd -i /var/run/rsyslogd.pid -f /etc/rsyslog.conf')[:pattern]).to eq('/usr/sbin/rsyslogd -i /var/run/rsyslogd.pid -f /etc/rsyslog.conf')
      end
    end

    describe "for ensure" do
      it "should allow present" do
        expect(described_class.new(:name => 'foo', :ensure => 'present')[:ensure]).to eq(:present)
      end

      it "should allow absent" do
        expect(described_class.new(:name => 'foo', :ensure => 'absent')[:ensure]).to eq(:absent)
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for match" do
      it "should allow nameonly" do
        expect(described_class.new(:name => 'foo', :match => 'nameonly')[:match]).to eq(:nameonly)
      end

      it "should allow cmdline" do
        expect(described_class.new(:name => 'foo', :match => 'cmdline')[:match]).to eq(:cmdline)
      end

      it "should default to nameonly" do
        expect(described_class.new(:name => 'foo')[:match]).to eq(:nameonly)
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :match => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for trackpid" do
      it "should allow yes" do
        expect(described_class.new(:name => 'foo', :trackpid => 'yes')[:trackpid]).to eq(:yes)
      end

      it "should allow no" do
        expect(described_class.new(:name => 'foo', :trackpid => 'no')[:trackpid]).to eq(:no)
      end

      it "should not allow anything else" do
        expect { described_class.new(:name => 'foo', :trackpid => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for description" do
      it "should allow a single word" do
        expect(described_class.new(:name => 'foo', :description => 'FOO')[:description]).to eq('FOO')
      end

      it "should allow spaces" do
        expect(described_class.new(:name => 'foo', :description => 'Check alertlog size')[:description]).to eq('Check alertlog size')
      end
    end

    describe "for active" do
      it "should allow yes" do
        expect(described_class.new(:name => 'foo', :active => 'yes')[:active]).to eq(:yes)
      end

      it "should allow no" do
        expect(described_class.new(:name => 'foo', :active => 'no')[:active]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :active => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for alarm_on" do
      it "should allow up" do
        expect(described_class.new(:name => 'foo', :alarm_on => 'up')[:alarm_on]).to eq([ :up ])
      end

      it "should allow down" do
        expect(described_class.new(:name => 'foo', :alarm_on => 'down')[:alarm_on]).to eq([ :down ])
      end

      it "should allow restart" do
        expect(described_class.new(:name => 'foo', :alarm_on => 'restart')[:alarm_on]).to eq([ :restart ])
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :alarm_on => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end

      it "should allow multiple conditions" do
        expect(described_class.new(:name => 'foo', :alarm_on => [ 'up', 'down', 'restart' ])[:alarm_on]).to eq([ :up, :down, :restart ])
      end
    end

    describe "for count" do
      [ '100', '> 20', '< 40', '<= 23', '>= 9', '!= 20' ].each do |count|
        it "should allow a value of #{count}" do
          expect(described_class.new(:name => 'foo', :count => count)[:count]).to eq(count)
        end
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => 'foo', :count => '-5') }.to raise_error Puppet::Error, /count must be of the form.*not -5/
      end

      it "should not allow other prefixes than <, >, >=, <= and !=" do
        expect { described_class.new(:name => 'foo', :count => '= 10') }.to raise_error Puppet::Error, /count must be of the form.*not = 10/
      end
    end

  end
end
