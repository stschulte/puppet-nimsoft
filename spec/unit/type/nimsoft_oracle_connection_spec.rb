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

    [:ensure, :description, :user, :password].each do |property|
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
  end
end
