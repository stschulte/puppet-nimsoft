#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_watcher) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :active, :match, :severity, :subsystem, :message, :suppkey, :source].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do

    describe "for name" do
      it "should allow something like \"my profile/my watcher rule\"" do
        described_class.new(:name => 'my profile/my watcher rule', :ensure => :present)[:name].should == 'my profile/my watcher rule'
      end
      
      it "should raise an error of no profile is specified" do
        expect { described_class.new(:name => 'my watcher rule', :ensure => :present) }.to raise_error Puppet::Error, /missing profile name/
      end
    end

    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => 'profile/watcher', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => 'profile/watcher', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'profile/watcher', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for active" do
      it "should allow yes" do
        described_class.new(:name => 'profile/watcher', :active => 'yes')[:active].should == :yes
      end
      
      it "should allow no" do
        described_class.new(:name => 'profile/watcher', :active => 'no')[:active].should == :no
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'profile/watcher', :active => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for match" do
      it "should allow an simple word" do
        described_class.new(:name => 'profile/watcher', :ensure => :present, :match => 'ERROR')[:match].should == 'ERROR'
      end

      it "should allow a simple pattern" do
        described_class.new(:name => 'profile/watcher', :ensure => :present, :match => '*ERROR*')[:match].should == '*ERROR*'
      end

      it "should allow a regular expression" do
        described_class.new(:name => 'profile/watcher', :ensure => :present, :match => '/ERROR\s*(.*)/')[:match].should == '/ERROR\s*(.*)/'
      end
    end

    describe "for severity" do
      [ :clear, :info, :warning, :minor, :major, :critical ].each do |criticality|
        it "should support #{criticality}" do
          described_class.new(:name => 'profile/watcher', :severity => criticality.to_s)[:severity].should == criticality
        end
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'profile/watcher', :severity => 'fatal') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for subsystem" do
      it "should allow a string" do
        described_class.new(:name => 'profile/watcher', :subsystem => 'disk')[:subsystem].should == 'disk'
      end

      it "should allow an id" do
        described_class.new(:name => 'profile/watcher', :subsystem => '1.5.23.7')[:subsystem].should == '1.5.23.7'
      end
    end

    describe "for message" do
      it "should allow a word" do
        described_class.new(:name => 'profile/watcher', :message => 'fatal')[:message].should == 'fatal'
      end

      it "should allow spaces" do
        described_class.new(:name => 'profile/watcher', :message => 'something bad happened')[:message].should == 'something bad happened'
      end

      it "should allwo variables" do
        described_class.new(:name => 'profile/watcher', :message => '${WATCHER}, ${PROFILE}, ${msg}')[:message].should == '${WATCHER}, ${PROFILE}, ${msg}'
      end
    end

    describe "for suppkey" do
      it "should allow a simple word" do
        described_class.new(:name => 'profile/watcher', :suppkey => 'cpu.util.bad')[:suppkey].should == 'cpu.util.bad'
      end

      it "should allow variables" do
        described_class.new(:name => 'profile/watcher', :suppkey => '${PROFILE}.${WATCHER}')[:suppkey].should == '${PROFILE}.${WATCHER}'
      end
    end

    describe "source" do
      it "should allow a short hostname" do
        described_class.new(:name => 'profile/watcher', :source => 'host')[:source].should == 'host'
      end

      it "should allow a fqdn" do
        described_class.new(:name => 'profile/watcher', :source => 'host.example.com')[:source].should == 'host.example.com'
      end
    end
  end
end
