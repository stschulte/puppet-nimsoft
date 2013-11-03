#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_template) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:system, :jobs, :monitors, :instances].each do |property|
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

    describe "for system" do
      it "should accept true" do
        described_class.new(:name => 'foo', :system => 'true')[:system].should == :true
      end

      it "should accept false" do
        described_class.new(:name => 'foo', :system => 'false')[:system].should == :false
      end
    end

    describe "for monitors" do
      it "should allow a single numeric monitor id" do
        described_class.new(:name => 'foo', :monitors => '20')[:monitors].should == %w{20}
      end

      it "should allow multiple numeric monitor ids as an array" do
        described_class.new(:name => 'foo', :monitors => [ '20', '4', '12' ])[:monitors].should == %w{20 4 12}
      end

      it "should not allow non numeric ids" do
        expect { described_class.new(:name => 'foo', :monitors => 'a12') }.to raise_error Puppet::Error, /monitor.*numeric/
        expect { described_class.new(:name => 'foo', :monitors => '12a') }.to raise_error Puppet::Error, /monitor.*numeric/
        expect { described_class.new(:name => 'foo', :monitors => '1a2') }.to raise_error Puppet::Error, /monitor.*numeric/
        expect { described_class.new(:name => 'foo', :monitors => [ '12', '1a2' ]) }.to raise_error Puppet::Error, /monitor.*numeric/
      end
    end

    describe "for jobs" do
      it "should allow a single numeric job id" do
        described_class.new(:name => 'foo', :jobs => '20')[:jobs].should == %w{20}
      end

      it "should allow multiple numeric job ids as an array" do
        described_class.new(:name => 'foo', :jobs => [ '20', '4', '12' ])[:jobs].should == %w{20 4 12}
      end

      it "should not allow non numeric ids" do
        expect { described_class.new(:name => 'foo', :jobs => 'a12') }.to raise_error Puppet::Error, /job.*numeric/
        expect { described_class.new(:name => 'foo', :jobs => '12a') }.to raise_error Puppet::Error, /job.*numeric/
        expect { described_class.new(:name => 'foo', :jobs => '1a2') }.to raise_error Puppet::Error, /job.*numeric/
        expect { described_class.new(:name => 'foo', :jobs => [ '12', '1a2' ]) }.to raise_error Puppet::Error, /job.*numeric/
      end
    end

    describe "instances" do
      it "should allow a single instance" do
        described_class.new(:name => 'foo', :instances => 'D00_sap01')[:instances].should == %w{D00_sap01}
      end

      it "should allow multiple instances as an array" do
        described_class.new(:name => 'foo', :instances => [ 'D00_sap01', 'D01_sap01'])[:instances].should == %w{D00_sap01 D01_sap01}
      end
    end
  end
end
