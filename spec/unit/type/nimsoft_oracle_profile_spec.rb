#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_oracle_profile) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :description, :active, :connection, :source, :interval, :heartbeat, :clear_msg, :sql_timeout_msg, :profile_timeout_msg, :severity, :profile_timeout, :sql_timeout, :connection_failed_msg].each do |property|
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

    describe "for active" do
      it "should allow yes" do
        expect(described_class.new(:name => 'FOO', :active => 'yes')[:active]).to eq(:yes)
      end
      
      it "should allow no" do
        expect(described_class.new(:name => 'FOO', :active => 'no')[:active]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'FOO', :active => 'true') }.to raise_error Puppet::Error, /Invalid value/
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
      it "should accept a simple name" do
        expect(described_class.new(:name => 'FOO', :connection => 'BAR')[:connection]).to eq('BAR')
      end
    end

    describe "source" do
      it "should allow a hostname" do
        expect(described_class.new(:name => 'FOO', :source => 'host01')[:source]).to eq('host01')
      end

      it "should allow a fqdn" do
        expect(described_class.new(:name => 'FOO', :source => 'host01.example.com')[:source]).to eq('host01.example.com')
      end
    end

    [:interval, :heartbeat, :profile_timeout, :sql_timeout].each do |time_property|
      describe time_property.to_s do
        it "should allow a timespan defined in seconds" do
          expect(described_class.new(:name => 'FOO', time_property => '10 sec')[time_property]).to eq('10 sec')
        end

        it "should allow a timespan defined in minutes" do
          expect(described_class.new(:name => 'FOO', time_property => '5 min')[time_property]).to eq('5 min')
        end

        it "should not allow a negative number" do
          expect { described_class.new(:name => 'FOO', time_property => '-5 min') }.to raise_error Puppet::Error, /#{time_property} must be a positive number and must be specified in "sec" or "min", not "-5 min"/
        end

        it "should not allow random text" do
          expect { described_class.new(:name => 'FOO', time_property => '10 foo') }.to raise_error Puppet::Error, /#{time_property} must be a positive number and must be specified in "sec" or "min", not "10 foo"/
        end
      end
    end

    [:clear_msg, :profile_timeout_msg, :sql_timeout_msg, :connection_failed_msg].each do |msg_property|
      describe msg_property.to_s do
        it "should allow a message pool name" do
          expect(described_class.new(:name => 'FOO', msg_property => 'foo_timeout_1')[msg_property]).to eq('foo_timeout_1')
        end
      end
    end

    describe "severity" do
      [ :info, :warning, :minor, :major, :critical ].each do |criticality|
        it "should support #{criticality}" do
          expect(described_class.new(:name => 'FOO', :severity => criticality.to_s)[:severity]).to eq(criticality)
        end
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'FOO', :severity => 'fatal') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end

  describe "autorequire" do
    let :connection_provider do
      Puppet::Type.type(:nimsoft_oracle_connection).provide(:fake_connection_provider) { mk_resource_methods }
    end

    let :profile_provider do
      described_class.provide(:fake_profile_provider) { mk_resource_methods }
    end

    let :connection do
      Puppet::Type.type(:nimsoft_oracle_connection).new(:name => 'FOO', :ensure => :present)
    end

    let :instance do
      described_class.new(:name => 'BAR', :ensure => :present, :connection => 'FOO')
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:nimsoft_oracle_connection).stubs(:defaultprovider).returns connection_provider
      Puppet::Type.type(:nimsoft_oracle_profile).stubs(:defaultprovider).returns profile_provider
    end

    describe "connection" do
      it "should not autorequire a connection if none found" do
        catalog.add_resource instance
        expect(instance.autorequire).to be_empty
      end

      it "should autorequire a matching connection" do
        catalog.add_resource instance
        catalog.add_resource connection

        reqs = instance.autorequire
        expect(reqs.size).to eq(1)
        expect(reqs[0].source).to eq(connection)
        expect(reqs[0].target).to eq(instance)
      end
    end
  end
end
