#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_landscape) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:sid, :description, :company, :description, :ensure].each do |property|
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

    describe "for sid" do
      ['PRO', 'S2E', 'X22', 'AK9'].each do |sid|
        it "should allow a valid sid like #{sid}" do
          expect(described_class.new(:name => 'foo', :sid => sid)[:sid]).to eq(sid)
        end
      end

      it "should not allow lowercase letters" do
        expect { described_class.new(:name => 'foo', :sid => 'SsS') }.to raise_error Puppet::Error, /SID SsS is invalid/
      end

      it "should not allow a digit at position 1" do
        expect { described_class.new(:name => 'foo', :sid => '9AK') }.to raise_error Puppet::Error, /SID 9AK is invalid/
      end
    end

    describe "for company" do
      it "should allow a single word" do
        expect(described_class.new(:name => 'foo', :company => 'Examplesoft')[:company]).to eq('Examplesoft')
      end

      it "should allow multiple words" do
        expect(described_class.new(:name => 'foo', :company => 'Examplesoft Inc')[:company]).to eq('Examplesoft Inc')
      end
    end

    describe "for description" do
      it "should allow a single word" do
        expect(described_class.new(:name => 'foo', :description => 'Puppet')[:description]).to eq('Puppet')
      end

      it "should allow multiple words" do
        expect(described_class.new(:name => 'foo', :description => 'managed by puppet')[:description]).to eq('managed by puppet')
      end

      it "should allow an url" do
        expect(described_class.new(:name => 'foo', :description => 'further information: http://example.com/foobar')[:description]).to eq('further information: http://example.com/foobar')
      end
    end
  end
end
