#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_user) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:password].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should allow present" do
        expect(described_class.new(:name => 'SAP_PROBE', :ensure => 'present')[:ensure]).to eq(:present)
      end

      it "should allow absent" do
        expect(described_class.new(:name => 'SAP_PROBE', :ensure => 'absent')[:ensure]).to eq(:absent)
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'SAP_PROBE', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for name" do
      [ 'FOOBAR', 'SAP_PROBE', 'PROBE001' ].each do |name|
        it "should accept a valid name like #{name}" do
          expect(described_class.new(:name => name, :ensure => 'present')[:name]).to eq(name)
        end
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'SAP PROBE', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end

      it "should not allow the first character to be a digit" do
        expect { described_class.new(:name => '1SAP_PROBE', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end

      it "should not allow lowercase letters" do
        expect { described_class.new(:name => 'sap_probe', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end

      it "should not allow hyphens" do
        expect { described_class.new(:name => 'SAP-PROBE', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end
    end
  end
end
