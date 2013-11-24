#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_profile) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [ :ensure, :active, :file, :mode, :interval, :qos, :alarm, :alarm_maxserv ].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => 'foo', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => 'foo', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for active" do
      it "should allow yes" do
        described_class.new(:name => 'foo', :active => 'yes')[:active].should == :yes
      end
      
      it "should allow no" do
        described_class.new(:name => 'foo', :active => 'no')[:active].should == :no
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :active => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for file" do
      it "should allow an absolute path" do
        described_class.new(:name => 'foo', :ensure => :present, :file => '/var/log/messages')[:file].should == '/var/log/messages'
      end
      
      it "should allow time formatting primitives" do
        described_class.new(:name => 'foo', :ensure => :present, :file => '/var/log/messages-%Y-%m-%d')[:file].should == '/var/log/messages-%Y-%m-%d'
      end
    end

    describe "for mode" do
      it "should allow cat" do
        described_class.new(:name => 'foo', :mode => 'cat')[:mode].should == :cat
      end

      it "should allow full" do
        described_class.new(:name => 'foo', :mode => 'full')[:mode].should == :full
      end

      it "should allow full_time" do
        described_class.new(:name => 'foo', :mode => 'full_time')[:mode].should == :full_time
      end

      it "should allow updates" do
        described_class.new(:name => 'foo', :mode => 'updates')[:mode].should == :updates
      end

      # TODO: implement command, queue and URL which require additional
      # properties like user and password
      it "should not allow anything else" do
        expect { described_class.new(:name => 'foo', :mode => 'command') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for interval" do
      it "should allow a timespan defined in seconds" do
        described_class.new(:name => 'foo', :interval => '10 sec')[:interval].should == '10 sec'
      end

      it "should allow a timespan defined in minutes" do
        described_class.new(:name => 'foo', :interval => '5 min')[:interval].should == '5 min'
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
        described_class.new(:name => 'foo', :qos => 'yes')[:qos].should == :yes
      end
      
      it "should allow no" do
        described_class.new(:name => 'foo', :qos => 'no')[:qos].should == :no
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :qos => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for alarm" do
      it "should allow yes" do
        described_class.new(:name => 'foo', :alarm => 'yes')[:alarm].should == :yes
      end
      
      it "should allow no" do
        described_class.new(:name => 'foo', :alarm => 'no')[:alarm].should == :no
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :alarm => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for alarm_maxserv" do
      [ :info, :warning, :minor, :major, :critical ].each do |criticality|
        it "should support #{criticality}" do
          described_class.new(:name => 'foo', :alarm_maxserv => criticality.to_s)[:alarm_maxserv].should == criticality
        end
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :alarm_maxserv => 'fatal') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end
end
