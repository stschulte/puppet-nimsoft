#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_exclude) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :active, :match ].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do

    describe "for name" do
      it "should allow something like \"my profile/my exclude rule\"" do
        described_class.new(:name => 'my profile/my exclude rule', :ensure => :present)[:name].should == 'my profile/my exclude rule'
      end
      
      it "should raise an error of no profile is specified" do
        expect { described_class.new(:name => 'my exclude rule', :ensure => :present) }.to raise_error Puppet::Error, /missing profile name/
      end
    end

    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => 'profile/exclude', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => 'profile/exclude', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'profile/exclude', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for active" do
      it "should allow yes" do
        described_class.new(:name => 'profile/exclude', :active => 'yes')[:active].should == :yes
      end
      
      it "should allow no" do
        described_class.new(:name => 'profile/exclude', :active => 'no')[:active].should == :no
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'profile/exclude', :active => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for match" do
      it "should allow an simple word" do
        described_class.new(:name => 'profile/exclude', :ensure => :present, :match => 'ERROR')[:match].should == 'ERROR'
      end

      it "should allow a simple pattern" do
        described_class.new(:name => 'profile/exclude', :ensure => :present, :match => '*ERROR*')[:match].should == '*ERROR*'
      end

      it "should allow a regular expression" do
        described_class.new(:name => 'profile/exclude', :ensure => :present, :match => '/ERROR\s*(.*)/')[:match].should == '/ERROR\s*(.*)/'
      end
    end
  end
end
