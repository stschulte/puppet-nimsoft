#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_queue) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :active, :type, :subject, :remote_queue, :address, :bulk_size].each do |property|
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

    describe "for type" do
      it "should allow attach" do
        expect(described_class.new(:name => 'foo', :type => 'attach')[:type]).to eq(:attach)
      end

      it "should allow get" do
        expect(described_class.new(:name => 'foo', :type => 'get')[:type]).to eq(:get)
      end

      it "should allow post" do
        expect(described_class.new(:name => 'foo', :type => 'post')[:type]).to eq(:post)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :type => 'set') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for subject" do
      it "should allow a value for an attach queue" do
        expect(described_class.new(:name => 'foo', :type => 'attach', :subject => 'alarm')[:subject]).to eq(['alarm'])
      end

      it "should allow a value for a post queue" do
        expect(described_class.new(:name => 'foo', :type => 'post', :subject => 'alarm')[:subject]).to eq(['alarm'])
      end

      it "should allow multiple values as an array" do
        expect(described_class.new(:name => 'foo', :type => 'attach', :subject => ['alarm', 'audit'])[:subject]).to eq(['alarm', 'audit'])
      end

      it "should not allow a comma separated list" do
        expect { described_class.new(:name => 'foo', :type => 'attach', :subject => 'alarm, audit') }.to raise_error Puppet::Error, /subject must be provided as an array/
      end

      it "should not allow a value for a get queue" do
        expect { described_class.new(:name => 'foo', :type => 'get', :subject => 'alarm') }.to raise_error Puppet::Error, /subject is invalid for get queues/
      end
    end

    describe "address" do
      it "should allow an address for a get queue" do
        expect(described_class.new(:name => 'foo', :type => 'get', :address => '/PRO/HUB/hub.example.com/hub')[:address]).to eq('/PRO/HUB/hub.example.com/hub')
      end

      it "should allow an address for a post queue" do
        expect(described_class.new(:name => 'foo', :type => 'post', :address => '/PRO/HUB/hub.example.com/hub')[:address]).to eq('/PRO/HUB/hub.example.com/hub')
      end

      it "should not allow an address for an attach queue" do
        expect { described_class.new(:name => 'foo', :type => 'attach', :address => '/PRO/HUB/hub.example.com/hub') }.to raise_error Puppet::Error, /address for an attach queue is invalid/
      end
    end

    describe "remote_queue" do
      it "should allow a queue name for a get queue" do
        expect(described_class.new(:name => 'foo', :type => 'get', :address => '/PRO/HUB/hub.example.com/hub', :remote_queue => 'FOO')[:remote_queue]).to eq('FOO')
      end

      it "should not allow a queue name for an attach queue" do
        expect { described_class.new(:name => 'foo', :type => 'attach', :address => '/PRO/HUB/hub.example.com/hub', :remote_queue => 'FOO') }.to raise_error Puppet::Error, /only valid for get queues/
      end

      it "should not allow a queue name for a post queue" do
        expect { described_class.new(:name => 'foo', :type => 'post', :address => '/PRO/HUB/hub.example.com/hub', :remote_queue => 'FOO') }.to raise_error Puppet::Error, /only valid for get queues/
      end
    end

    describe "bulk_size" do
    end
  end
end
