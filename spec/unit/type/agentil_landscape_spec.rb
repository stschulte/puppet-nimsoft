#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_landscape) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:sid, :description, :company, :description, :ensure].each do |property|
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

    describe "for sid" do
      ['PRO', 'S2E', 'X22', 'AK9'].each do |sid|
        it "should allow a valid sid like #{sid}" do
            described_class.new(:name => 'foo', :sid => sid)[:sid].should == sid
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
        described_class.new(:name => 'foo', :company => 'Examplesoft')[:company].should == 'Examplesoft'
      end

      it "should allow multiple words" do
        described_class.new(:name => 'foo', :company => 'Examplesoft Inc')[:company].should == 'Examplesoft Inc'
      end
    end

    describe "for description" do
      it "should allow a single word" do
        described_class.new(:name => 'foo', :description => 'Puppet')[:description].should == 'Puppet'
      end

      it "should allow multiple words" do
        described_class.new(:name => 'foo', :description => 'managed by puppet')[:description].should == 'managed by puppet'
      end

      it "should allow an url" do
        described_class.new(:name => 'foo', :description => 'further information: http://example.com/foobar')[:description].should == 'further information: http://example.com/foobar'
      end
    end
  end

end
