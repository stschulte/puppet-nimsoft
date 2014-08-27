#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_template) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:system, :jobs, :tablespace_used, :expected_instances, :rfc_destinations ].each do |property|
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

    describe "for system" do
      it "should accept true" do
        expect(described_class.new(:name => 'foo', :system => 'true')[:system]).to eq(:true)
      end

      it "should accept false" do
        expect(described_class.new(:name => 'foo', :system => 'false')[:system]).to eq(:false)
      end
    end

    describe "for jobs" do
      it "should allow a single numeric job id" do
        expect(described_class.new(:name => 'foo', :jobs => '20')[:jobs]).to eq([ 20 ])
      end

      it "should allow multiple numeric job ids as an array" do
        expect(described_class.new(:name => 'foo', :jobs => [ '20', '4', '12' ])[:jobs]).to eq([ 20, 4, 12 ])
      end

      it "should not allow non numeric ids" do
        expect { described_class.new(:name => 'foo', :jobs => 'a12') }.to raise_error Puppet::Error, /job.*numeric/
        expect { described_class.new(:name => 'foo', :jobs => '12a') }.to raise_error Puppet::Error, /job.*numeric/
        expect { described_class.new(:name => 'foo', :jobs => '1a2') }.to raise_error Puppet::Error, /job.*numeric/
        expect { described_class.new(:name => 'foo', :jobs => [ '12', '1a2' ]) }.to raise_error Puppet::Error, /job.*numeric/
      end
    end

    describe "for tablespace_used" do
      it "should not allow a single value" do
        expect { described_class.new(:name => 'foo', :tablespace_used => 'PSAPSR3') }.to raise_error Puppet::Error, /Hash required/
      end

      it "should not allow an array" do
        expect { described_class.new(:name => 'foo', :tablespace_used => [ 'PSAPSR3', 10 ]) }.to raise_error Puppet::Error, /Hash required/
      end


      it "should allow a hash of the form :tablespace_name => :used_in_percent" do
        expect(described_class.new(
          :name            => 'foo',
          :tablespace_used => {
            'PSAPSR3'  => '90',
            'PSAPUNDO' => '50'
          }
        )[:tablespace_used]).to eq({
            :PSAPSR3  => 90,
            :PSAPUNDO => 50
        })
      end

      it "should should complain about a non numeric percentage value" do
        expect { described_class.new(
          :name            => 'foo',
          :tablespace_used => {
            'PSAPSR3'  => '90',
            'PSAPUNDO' => '10%'
          }
        )}.to raise_error Puppet::Error, /The tablespace PSAPUNDO has an invalid should value of 10%\. Must be an Integer/
      end
    end

    describe "for expected_instances" do
      it "should allow a single value" do
        expect(described_class.new(:name => 'foo', :expected_instances => 'sap01_PRO_00')[:expected_instances]).to eq(['sap01_PRO_00'])
      end

      it "should allow an array of instances names" do
        expect(described_class.new(:name => 'foo', :expected_instances => [ 'sap01_PRO_00', 'sap01_PRO_01'])[:expected_instances]).to eq(['sap01_PRO_00', 'sap01_PRO_01'])
      end

      it "should not allow whitespaces" do
        expect { described_class.new(:name => 'foo', :expected_instances => 'sap01 PRO')}.to raise_error Puppet::Error, /instance.*must not contain any whitespace/
      end
    end

    describe "for rfc_destinations" do
      it "should allow a single value" do
        expect(described_class.new(:name => 'foo', :rfc_destinations => 'B2B')[:rfc_destinations]).to eq(['B2B'])
      end

      it "should allow an array of destinations" do
        expect(described_class.new(:name => 'foo', :rfc_destinations => ['FOO', 'BAR'])[:rfc_destinations]).to eq(['FOO', 'BAR'])
      end
    end
  end
end
