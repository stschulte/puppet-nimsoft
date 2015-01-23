#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_logmon_watcher) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :active, :match, :severity, :subsystem, :message, :suppkey, :source].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do

    describe "for name" do
      it "should allow something like \"my profile/my watcher rule\"" do
        expect(described_class.new(:name => 'my profile/my watcher rule', :ensure => :present)[:name]).to eq('my profile/my watcher rule')
      end
      
      it "should raise an error of no profile is specified" do
        expect { described_class.new(:name => 'my watcher rule', :ensure => :present) }.to raise_error Puppet::Error, /missing profile name/
      end
    end

    describe "for ensure" do
      it "should allow present" do
        expect(described_class.new(:name => 'profile/watcher', :ensure => 'present')[:ensure]).to eq(:present)
      end

      it "should allow absent" do
        expect(described_class.new(:name => 'profile/watcher', :ensure => 'absent')[:ensure]).to eq(:absent)
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'profile/watcher', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for active" do
      it "should allow yes" do
        expect(described_class.new(:name => 'profile/watcher', :active => 'yes')[:active]).to eq(:yes)
      end
      
      it "should allow no" do
        expect(described_class.new(:name => 'profile/watcher', :active => 'no')[:active]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'profile/watcher', :active => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for match" do
      it "should allow an simple word" do
        expect(described_class.new(:name => 'profile/watcher', :ensure => :present, :match => 'ERROR')[:match]).to eq('ERROR')
      end

      it "should allow a simple pattern" do
        expect(described_class.new(:name => 'profile/watcher', :ensure => :present, :match => '*ERROR*')[:match]).to eq('*ERROR*')
      end

      it "should allow a regular expression" do
        expect(described_class.new(:name => 'profile/watcher', :ensure => :present, :match => '/ERROR\s*(.*)/')[:match]).to eq('/ERROR\s*(.*)/')
      end
    end

    describe "for severity" do
      [ :clear, :info, :warning, :minor, :major, :critical ].each do |criticality|
        it "should support #{criticality}" do
          expect(described_class.new(:name => 'profile/watcher', :severity => criticality.to_s)[:severity]).to eq(criticality)
        end
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'profile/watcher', :severity => 'fatal') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for subsystem" do
      it "should allow a string" do
        expect(described_class.new(:name => 'profile/watcher', :subsystem => 'disk')[:subsystem]).to eq('disk')
      end

      it "should allow an id" do
        expect(described_class.new(:name => 'profile/watcher', :subsystem => '1.5.23.7')[:subsystem]).to eq('1.5.23.7')
      end
    end

    describe "for message" do
      it "should allow a word" do
        expect(described_class.new(:name => 'profile/watcher', :message => 'fatal')[:message]).to eq('fatal')
      end

      it "should allow spaces" do
        expect(described_class.new(:name => 'profile/watcher', :message => 'something bad happened')[:message]).to eq('something bad happened')
      end

      it "should allwo variables" do
        expect(described_class.new(:name => 'profile/watcher', :message => '${WATCHER}, ${PROFILE}, ${msg}')[:message]).to eq('${WATCHER}, ${PROFILE}, ${msg}')
      end
    end

    describe "for suppkey" do
      it "should allow a simple word" do
        expect(described_class.new(:name => 'profile/watcher', :suppkey => 'cpu.util.bad')[:suppkey]).to eq('cpu.util.bad')
      end

      it "should allow variables" do
        expect(described_class.new(:name => 'profile/watcher', :suppkey => '${PROFILE}.${WATCHER}')[:suppkey]).to eq('${PROFILE}.${WATCHER}')
      end
    end

    describe "source" do
      it "should allow a short hostname" do
        expect(described_class.new(:name => 'profile/watcher', :source => 'host')[:source]).to eq('host')
      end

      it "should allow a fqdn" do
        expect(described_class.new(:name => 'profile/watcher', :source => 'host.example.com')[:source]).to eq('host.example.com')
      end
    end
  end
end
