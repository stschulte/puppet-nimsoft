#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_disk) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :description, :device, :missing, :active, :warning, :critical].each do |property|
      it "should have a #{property} property" do
        expect(described_class.attrtype(property)).to eq(:property)
      end
    end
  end

  describe "when validating values" do
    describe "for ensure" do
      it "should allow present" do
        expect(described_class.new(:name => '/foo', :ensure => 'present')[:ensure]).to eq(:present)
      end

      it "should allow absent" do
        expect(described_class.new(:name => '/foo', :ensure => 'absent')[:ensure]).to eq(:absent)
      end

      it "should not allow something else" do
        expect { described_class.new(:name => '/foo', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for active" do
      it "should allow yes" do
        expect(described_class.new(:name => '/foo', :active => 'yes')[:active]).to eq(:yes)
      end

      it "should allow no" do
        expect(described_class.new(:name => '/foo', :active => 'no')[:active]).to eq(:no)
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
        expect(described_class.new(:name => '/foo', :description => 'FOO')[:description]).to eq('FOO')
      end

      it "should allow spaces" do
        expect(described_class.new(:name => '/foo', :description => '/foo File System (managed by puppet)')[:description]).to eq('/foo File System (managed by puppet)')
      end
    end

   describe "for device" do
      it "should support normal /dev paths for device" do
        expect(described_class.new(:name => "/foo", :device => '/dev/hda1')[:device]).to eq('/dev/hda1')
        expect(described_class.new(:name => "/foo", :device => '/dev/dsk/c0d0s0')[:device]).to eq('/dev/dsk/c0d0s0')
      end

      it "should support labels for device" do
        expect(described_class.new(:name => "/foo", :device => 'LABEL=/boot')[:device]).to eq('LABEL=/boot')
        expect(described_class.new(:name => "/foo", :device => 'LABEL=SWAP-hda6')[:device]).to eq('LABEL=SWAP-hda6')
      end

      it "should support pseudo devices for device" do
        expect(described_class.new(:name => "/foo", :device => 'ctfs')[:device]).to eq('ctfs')
        expect(described_class.new(:name => "/foo", :device => 'swap')[:device]).to eq('swap')
        expect(described_class.new(:name => "/foo", :device => 'sysfs')[:device]).to eq('sysfs')
        expect(described_class.new(:name => "/foo", :device => 'proc')[:device]).to eq('proc')
      end
    end

    describe "for missing" do
      it "should allow yes" do
        expect(described_class.new(:name => '/foo', :missing => 'yes')[:missing]).to eq(:yes)
      end

      it "should allow no" do
        expect(described_class.new(:name => '/foo', :missing => 'no')[:missing]).to eq(:no)
      end

      it "should not allow anything else" do
        expect { described_class.new(:name => '/foo', :missing => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for warning" do
      it "should support absent" do
        expect(described_class.new(:name => '/foo', :warning => 'absent')[:warning]).to eq(:absent)
      end

      it "should allow a postive number" do
        expect(described_class.new(:name => '/foo', :warning => '0')[:warning]).to eq('0')
        expect(described_class.new(:name => '/foo', :warning => '1')[:warning]).to eq('1')
        expect(described_class.new(:name => '/foo', :warning => '22')[:warning]).to eq('22')
        expect(described_class.new(:name => '/foo', :warning => '99')[:warning]).to eq('99')
        expect(described_class.new(:name => '/foo', :warning => '100')[:warning]).to eq('100')
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
        expect(described_class.new(:name => '/foo', :critical => 'absent')[:critical]).to eq(:absent)
      end

      it "should allow a postive number" do
        expect(described_class.new(:name => '/foo', :critical => '0')[:critical]).to eq('0')
        expect(described_class.new(:name => '/foo', :critical => '1')[:critical]).to eq('1')
        expect(described_class.new(:name => '/foo', :critical => '22')[:critical]).to eq('22')
        expect(described_class.new(:name => '/foo', :critical => '99')[:critical]).to eq('99')
        expect(described_class.new(:name => '/foo', :critical => '100')[:critical]).to eq('100')
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
