#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_disk) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :description, :device, :missing, :active, :warning, :critical].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => '/foo', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => '/foo', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => '/foo', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for active" do
      it "should allow yes" do
        described_class.new(:name => '/foo', :active => 'yes')[:active].should == :yes
      end

      it "should allow no" do
        described_class.new(:name => '/foo', :active => 'no')[:active].should == :no
      end

      it "should not allow anything else" do
        expect { described_class.new(:name => '/foo', :active => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for nfs" do
      it "should allow yes" do
        expect(described_class.new(:name => '/foo', :nfs => 'yes')[:nfs]).to eq(:yes)
      end

      it "should allow no" do
        expect(described_class.new(:name => '/foo', :nfs => 'no')[:nfs]).to eq(:no)
      end

      it "should not allow anything else" do
        expect { described_class.new(:name => '/foo', :nfs => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for description" do
      it "should allow a single word" do
        described_class.new(:name => '/foo', :description => 'FOO')[:description].should == 'FOO'
      end

      it "should allow spaces" do
        described_class.new(:name => '/foo', :description => '/foo File System (managed by puppet)')[:description].should == '/foo File System (managed by puppet)'
      end
    end

   describe "for device" do
      it "should support normal /dev paths for device" do
        described_class.new(:name => "/foo", :device => '/dev/hda1')[:device].should == '/dev/hda1'
        described_class.new(:name => "/foo", :device => '/dev/dsk/c0d0s0')[:device].should == '/dev/dsk/c0d0s0'
      end

      it "should support labels for device" do
        described_class.new(:name => "/foo", :device => 'LABEL=/boot')[:device].should == 'LABEL=/boot'
        described_class.new(:name => "/foo", :device => 'LABEL=SWAP-hda6')[:device].should == 'LABEL=SWAP-hda6'
      end

      it "should support pseudo devices for device" do
        described_class.new(:name => "/foo", :device => 'ctfs')[:device].should == 'ctfs'
        described_class.new(:name => "/foo", :device => 'swap')[:device].should == 'swap'
        described_class.new(:name => "/foo", :device => 'sysfs')[:device].should == 'sysfs'
        described_class.new(:name => "/foo", :device => 'proc')[:device].should == 'proc'
      end
    end

    describe "for missing" do
      it "should allow yes" do
        described_class.new(:name => '/foo', :missing => 'yes')[:missing].should == :yes
      end

      it "should allow no" do
        described_class.new(:name => '/foo', :missing => 'no')[:missing].should == :no
      end

      it "should not allow anything else" do
        expect { described_class.new(:name => '/foo', :missing => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for warning" do
      it "should support absent" do
        described_class.new(:name => '/foo', :warning => 'absent')[:warning].should == :absent
      end

      it "should allow a postive number" do
        described_class.new(:name => '/foo', :warning => '0')[:warning].should == '0'
        described_class.new(:name => '/foo', :warning => '1')[:warning].should == '1'
        described_class.new(:name => '/foo', :warning => '22')[:warning].should == '22'
        described_class.new(:name => '/foo', :warning => '99')[:warning].should == '99'
        described_class.new(:name => '/foo', :warning => '100')[:warning].should == '100'
      end

      it "should not allow a non numeric value" do
        expect { described_class.new(:name => '/foo', :warning => '10a') }.to raise_error Puppet::Error, /threshold has to be numeric/
      end

      it "should not allow a number above 100" do
        expect { described_class.new(:name => '/foo', :warning => '101') }.to raise_error Puppet::Error, /between 0 and 100/
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => '/foo', :warning => '-3') }.to raise_error Puppet::Error, /threshold has to be numeric/
      end
    end

    describe "for critical" do
      it "should support absent" do
        described_class.new(:name => '/foo', :critical => 'absent')[:critical].should == :absent
      end

      it "should allow a postive number" do
        described_class.new(:name => '/foo', :critical => '0')[:critical].should == '0'
        described_class.new(:name => '/foo', :critical => '1')[:critical].should == '1'
        described_class.new(:name => '/foo', :critical => '22')[:critical].should == '22'
        described_class.new(:name => '/foo', :critical => '99')[:critical].should == '99'
        described_class.new(:name => '/foo', :critical => '100')[:critical].should == '100'
      end

      it "should not allow a non numeric value" do
        expect { described_class.new(:name => '/foo', :critical => '10a') }.to raise_error Puppet::Error, /threshold has to be numeric/
      end

      it "should not allow a number above 100" do
        expect { described_class.new(:name => '/foo', :critical => '101') }.to raise_error Puppet::Error, /between 0 and 100/
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => '/foo', :critical => '-3') }.to raise_error Puppet::Error, /threshold has to be numeric/
      end
    end
  end
end
