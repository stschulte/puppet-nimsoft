#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_oracle_connection) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :description, :user, :password, :retry, :retry_delay].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => 'FOO', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => 'FOO', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'FOO', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "description" do
      it "should allow a single word" do
        described_class.new(:name => 'FOO', :description => 'FOO')[:description].should == 'FOO'
      end

      it "should allow spaces" do
        described_class.new(:name => 'FOO', :description => 'Most critical database')[:description].should == 'Most critical database'
      end
    end

    describe "connection" do
      it "should accept a service name" do
        described_class.new(:name => 'FOO', :connection => 'BAR')[:connection].should == 'BAR'
      end

      [ 'host.example.com:1521/BAR', 'host:1521/BAR', 'host.example.com/BAR', 'host/BAR' ].each do |connect|
        it "should allow an easy connect string like #{connect}" do
          described_class.new(:name => 'FOO', :connection => connect)[:connection].should == connect
        end
      end
    end

    describe "user" do
      it "should allow simple usernames" do
        described_class.new(:name => 'FOO', :user => 'nmuser')[:user].should == 'nmuser'
      end
    end

    describe "password" do
      it "should allow simple passwords" do
        described_class.new(:name => 'FOO', :password => 'abc')[:password].should == 'abc'
      end

      it "should allow alphanumerical password" do
        described_class.new(:name => 'FOO', :password => 'J4Cv2jpk6OFIPYI7ObEBUecrdtqERC')[:password].should == 'J4Cv2jpk6OFIPYI7ObEBUecrdtqERC'
      end
    end

    describe "retry" do
      it "should  allow zero" do
        described_class.new(:name => 'FOO', :retry => '0')[:retry].should == '0'
      end

      it "should allow a positive number" do
        described_class.new(:name => 'FOO', :retry => '5')[:retry].should == '5'
        described_class.new(:name => 'FOO', :retry => '12')[:retry].should == '12'
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => 'FOO', :retry => '-5') }.to raise_error Puppet::Error, /retry must be a positive number, not "-5"/
      end

      it "should not allow a non numeric value" do
        expect { described_class.new(:name => 'FOO', :retry => '5s') }.to raise_error Puppet::Error, /retry must be a positive number, not "5s"/ 
      end
    end

    describe "retry delay" do
      it "should allow a timespan defined in seconds" do
        described_class.new(:name => 'FOO', :retry_delay => '10 sec')[:retry_delay].should == '10 sec'
      end

      it "should allow a timespan defined in minutes" do
        described_class.new(:name => 'FOO', :retry_delay => '5 min')[:retry_delay].should == '5 min'
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => 'FOO', :retry_delay => '-5 min') }.to raise_error Puppet::Error, /retry_delay must be a positive number and must be specified in "sec" or "min", not "-5 min"/
      end

      it "should not allow random text" do
        expect { described_class.new(:name => 'FOO', :retry_delay => '10 foo') }.to raise_error Puppet::Error, /retry_delay must be a positive number and must be specified in "sec" or "min", not "10 foo"/
      end
    end
  end
end
