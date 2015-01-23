#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_profile) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [ :ensure, :active, :file, :mode, :interval, :qos, :alarm, :alarm_maxserv ].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do
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

    describe "for file" do
      it "should allow an absolute path" do
        expect(described_class.new(:name => 'foo', :ensure => :present, :file => '/var/log/messages')[:file]).to eq('/var/log/messages')
      end
      
      it "should allow time formatting primitives" do
        expect(described_class.new(:name => 'foo', :ensure => :present, :file => '/var/log/messages-%Y-%m-%d')[:file]).to eq('/var/log/messages-%Y-%m-%d')
      end
    end

    describe "for mode" do
      it "should allow cat" do
        expect(described_class.new(:name => 'foo', :mode => 'cat')[:mode]).to eq(:cat)
      end

      it "should allow full" do
        expect(described_class.new(:name => 'foo', :mode => 'full')[:mode]).to eq(:full)
      end

      it "should allow full_time" do
        expect(described_class.new(:name => 'foo', :mode => 'full_time')[:mode]).to eq(:full_time)
      end

      it "should allow updates" do
        expect(described_class.new(:name => 'foo', :mode => 'updates')[:mode]).to eq(:updates)
      end

      # TODO: implement command, queue and URL which require additional
      # properties like user and password
      it "should not allow anything else" do
        expect { described_class.new(:name => 'foo', :mode => 'command') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for interval" do
      it "should allow a timespan defined in seconds" do
        expect(described_class.new(:name => 'foo', :interval => '10 sec')[:interval]).to eq('10 sec')
      end

      it "should allow a timespan defined in minutes" do
        expect(described_class.new(:name => 'foo', :interval => '5 min')[:interval]).to eq('5 min')
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => 'foo', :interval => '-5 min') }.to raise_error Puppet::Error, /interval must be a positive number and must be specified in "sec" or "min", not "-5 min"/
      end

      it "should not allow random text" do
        expect { described_class.new(:name => 'foo', :interval => '10 foo') }.to raise_error Puppet::Error, /interval must be a positive number and must be specified in "sec" or "min", not "10 foo"/
      end
    end

    describe "for qos" do
      it "should allow yes" do
        expect(described_class.new(:name => 'foo', :qos => 'yes')[:qos]).to eq(:yes)
      end
      
      it "should allow no" do
        expect(described_class.new(:name => 'foo', :qos => 'no')[:qos]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :qos => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for alarm" do
      it "should allow yes" do
        expect(described_class.new(:name => 'foo', :alarm => 'yes')[:alarm]).to eq(:yes)
      end
      
      it "should allow no" do
        expect(described_class.new(:name => 'foo', :alarm => 'no')[:alarm]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :alarm => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for alarm_maxserv" do
      [ :info, :warning, :minor, :major, :critical ].each do |criticality|
        it "should support #{criticality}" do
          expect(described_class.new(:name => 'foo', :alarm_maxserv => criticality.to_s)[:alarm_maxserv]).to eq(criticality)
        end
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :alarm_maxserv => 'fatal') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end
end
