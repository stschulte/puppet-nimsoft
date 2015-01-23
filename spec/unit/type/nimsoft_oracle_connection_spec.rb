#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_oracle_connection) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :description, :user, :password, :retry, :retry_delay].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should allow present" do
        expect(described_class.new(:name => 'FOO', :ensure => 'present')[:ensure]).to eq(:present)
      end

      it "should allow absent" do
        expect(described_class.new(:name => 'FOO', :ensure => 'absent')[:ensure]).to eq(:absent)
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'FOO', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "description" do
      it "should allow a single word" do
        expect(described_class.new(:name => 'FOO', :description => 'FOO')[:description]).to eq('FOO')
      end

      it "should allow spaces" do
        expect(described_class.new(:name => 'FOO', :description => 'Most critical database')[:description]).to eq('Most critical database')
      end
    end

    describe "connection" do
      it "should accept a service name" do
        expect(described_class.new(:name => 'FOO', :connection => 'BAR')[:connection]).to eq('BAR')
      end

      [ 'host.example.com:1521/BAR', 'host:1521/BAR', 'host.example.com/BAR', 'host/BAR' ].each do |connect|
        it "should allow an easy connect string like #{connect}" do
          expect(described_class.new(:name => 'FOO', :connection => connect)[:connection]).to eq(connect)
        end
      end
    end

    describe "user" do
      it "should allow simple usernames" do
        expect(described_class.new(:name => 'FOO', :user => 'nmuser')[:user]).to eq('nmuser')
      end
    end

    describe "password" do
      it "should allow simple passwords" do
        expect(described_class.new(:name => 'FOO', :password => 'abc')[:password]).to eq('abc')
      end

      it "should allow alphanumerical password" do
        expect(described_class.new(:name => 'FOO', :password => 'J4Cv2jpk6OFIPYI7ObEBUecrdtqERC')[:password]).to eq('J4Cv2jpk6OFIPYI7ObEBUecrdtqERC')
      end
    end

    describe "retry" do
      it "should  allow zero" do
        expect(described_class.new(:name => 'FOO', :retry => '0')[:retry]).to eq('0')
      end

      it "should allow a positive number" do
        expect(described_class.new(:name => 'FOO', :retry => '5')[:retry]).to eq('5')
        expect(described_class.new(:name => 'FOO', :retry => '12')[:retry]).to eq('12')
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
        expect(described_class.new(:name => 'FOO', :retry_delay => '10 sec')[:retry_delay]).to eq('10 sec')
      end

      it "should allow a timespan defined in minutes" do
        expect(described_class.new(:name => 'FOO', :retry_delay => '5 min')[:retry_delay]).to eq('5 min')
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
