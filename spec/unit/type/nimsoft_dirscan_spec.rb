#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_dirscan) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:active, :description, :directory, :pattern, :recurse, :direxists, :direxists_action, :nofiles, :nofiles_action, :size, :size_type, :size_action].each do |property|
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

    describe "for description" do
      it "should allow a single word" do
        expect(described_class.new(:name => 'foo', :description => 'FOO')[:description]).to eq('FOO')
      end

      it "should allow spaces" do
        expect(described_class.new(:name => 'foo', :description => 'Check alertlog size')[:description]).to eq('Check alertlog size')
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

    describe "for directory" do
      it "should allow an absolute path" do
        expect(described_class.new(:name => 'foo', :ensure => :present, :directory => '/var/log')[:directory]).to eq('/var/log')
      end
    end

    describe "for pattern" do
      it "should allow a single filename" do
        expect(described_class.new(:name => 'foo', :ensure => :present, :directory => '/var/log', :pattern => 'messages')[:pattern]).to eq('messages')
      end

      it "should allow a glob" do
        expect(described_class.new(:name => 'foo', :ensure => :present, :directory => '/var/log', :pattern => '*.log')[:pattern]).to eq('*.log')
      end
    end

    describe "for recurse" do
      it "should allow yes" do
        expect(described_class.new(:name => 'foo', :recurse => 'yes')[:recurse]).to eq(:yes)
      end
      
      it "should allow no" do
        expect(described_class.new(:name => 'foo', :recurse => 'no')[:recurse]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :recurse => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for direxists" do
      it "should allow yes" do
        expect(described_class.new(:name => 'foo', :direxists => 'yes')[:direxists]).to eq(:yes)
      end
      
      it "should allow no" do
        expect(described_class.new(:name => 'foo', :direxists => 'no')[:direxists]).to eq(:no)
      end

      it "should allow something else" do
        expect { described_class.new(:name => 'foo', :direxists => 'true') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    [:direxists_action, :nofiles_action, :size_action].each do |property|
      describe "for #{property}" do
        it "should allow a single command" do
          expect(described_class.new(:name => 'foo', property => '/sbin/boot-update')[property]).to eq('/sbin/boot-update')
        end

        it "should allow a command with arguments" do
          expect(described_class.new(:name => 'foo', property => '/bin/rm -f $file')[property]).to eq('/bin/rm -f $file')
        end
      end
    end

    describe "nofiles" do
      [ '100', '> 20', '< 40', '<= 23', '>= 9' ].each do |nofiles|
        it "should allow a value of #{nofiles}" do
          expect(described_class.new(:name => 'foo', :nofiles => nofiles)[:nofiles]).to eq(nofiles)
        end
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => 'foo', :nofiles => '-5') }.to raise_error Puppet::Error, /nofiles must be of the form.*not -5/
      end
      it "should not allow other prefixes than <, >, =, >=, and <=" do
        expect { described_class.new(:name => 'foo', :nofiles => '! 10') }.to raise_error Puppet::Error, /nofiles must be of the form.*not ! 10/
      end
    end

    describe "size" do
      ['', '> ', '< ', '>= ', '<= ' ].each do |prefix|
        [ '10G', '3M', '4K' ].each do |number|
          size = "#{prefix}#{number}"
          it "should allow a fixed number like \"#{size}\"" do
            expect(described_class.new(:name => 'foo', :size => size)[:size]).to eq(size)
          end
        end
      end

      it "should not allow a unit other than K, M, G" do
        expect { described_class.new(:name => 'foo', :size => '10B') }.to raise_error Puppet::Error, /size must be of the form.*not 10B/
      end

      it "should not allow a negative number" do
        expect { described_class.new(:name => 'foo', :size => '-5M') }.to raise_error Puppet::Error, /size must be of the form.*not -5M/
      end

      it "should not allow other prefixes than <, >, =, >=, and <=" do
        expect { described_class.new(:name => 'foo', :size => '! 5M') }.to raise_error Puppet::Error, /size must be of the form.*not ! 5M/
      end
    end

    describe "for size_type" do
      it "should allow individual" do
        expect(described_class.new(:name => 'foo', :size => '<10M', :size_type => 'individual')[:size_type]).to eq(:individual)
      end

      it "should allow smallest" do
        expect(described_class.new(:name => 'foo', :size => '<10M', :size_type => 'smallest')[:size_type]).to eq(:smallest)
      end

      it "should allow largest" do
        expect(described_class.new(:name => 'foo', :size => '<10M', :size_type => 'largest')[:size_type]).to eq(:largest)
      end

      it "should not allow other values" do
        expect { described_class.new(:name => 'foo', :size => '<10M', :size_type => 'biggest') }.to raise_error Puppet::Error, /Invalid value/
      end

      it "should default to individual if size is set" do
        expect(described_class.new(:name => 'foo', :size => '<10M')[:size_type]).to eq(:individual)
      end

      it "should not have a default if size is not set" do
        expect(described_class.new(:name => 'foo')[:size_type]).to be_nil
      end
    end
  end
end
