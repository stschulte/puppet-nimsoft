#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_disk).provider(:nimsoft) do

  let :config do
    config = Puppet::Util::NimsoftConfig.new('some_file')
    Puppet::Util::NimsoftSection.new('/var/lib/mysql', config.path('disk/alarm/fixed'))
    config.stubs(:sync)
    config
  end

  let :fixed do
    config.path('disk/alarm/fixed')
  end

  let :element do
    element = Puppet::Util::NimsoftSection.new('/var', fixed)
    element[:active] = 'yes'
    element[:description] = 'sample description'
    element[:disk] = '/dev/sda2'
    element[:percent] = 'yes'
    error = element.path('error')
    error[:active] = 'yes'
    error[:threshold] = '10'
    error[:message] = 'DiskError'
    warning = element.path('warning')
    warning[:active] = 'yes'
    warning[:threshold] = '20'
    warning[:message] = 'DiskWarning'
    element
  end

  let :provider do
    provider = described_class.new(:name => '/var', :ensure => :present, :element => element)
    resource = Puppet::Type.type(:nimsoft_disk).new(
      :name => '/var'
    )
    resource.provider = provider
    provider
  end

  let :provider_new do
    provider = described_class.new(:name => '/opt')
    resource = Puppet::Type.type(:nimsoft_disk).new(
      :name        => '/opt',
      :ensure      => 'present',
      :active      => 'yes',
      :nfs         => 'yes',
      :device      => '//some_server/some_share',
      :description => 'a short test',
      :warning     => 'absent',
      :critical    => '40'
    )
    resource.provider = provider
    provider
  end

  before :each do
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::NimsoftConfig.stubs(:add).with('/opt/nimsoft/probes/system/cdm/cdm.cfg').returns config
    described_class.initvars
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        expect(provider).to be_exist
      end

      it "should return false if the instance is absent" do
        expect(provider_new).to_not be_exist
      end
    end

    describe "create" do
      it "should add a new section" do
        expect(described_class.root.children.map(&:name)).to eq([ '/var/lib/mysql' ])
        provider_new.create
        expect(described_class.root.children.map(&:name)).to eq([ '/var/lib/mysql', '/opt' ])
      end

      it "should set the correct attributes after adding the section" do
        provider_new.create

        child = described_class.root.child('/opt')
        expect(child).to_not be_nil

        expect(child[:active]).to eq('yes')
        expect(child[:description]).to eq('a short test')
        expect(child[:disk]).to eq('//some_server/some_share')
        expect(child[:nfs_space_check]).to eq('yes')

        error_element = child.child('error')
        expect(error_element).to_not be_nil
        expect(error_element[:active]).to eq('yes')
        expect(error_element[:threshold]).to eq('40')
        warning_element = child.child('warning')
        expect(warning_element[:active]).to eq('no')
      end
    end

    describe "destroy" do
      it "should destroy the specific section" do
        provider = described_class.new(:name => element.name, :ensure => :present, :element => element)

        expect(described_class.root.children.map(&:name)).to eq([ '/var/lib/mysql', '/var' ])
        provider.destroy
        expect(described_class.root.children.map(&:name)).to eq([ '/var/lib/mysql' ])
      end
    end
  end

  describe "when managing active" do
    it "should return :yes when active" do
      element[:active] = 'yes'
      expect(provider.active).to eq(:yes)
    end

    it "should return :no when not active" do
      element[:active] = 'no'
      expect(provider.active).to eq(:no)
    end

    it "should set active to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:active, 'yes')
      provider.active = :yes
    end

    it "should set active to \"no\" when new value is :no" do
      element.expects(:[]=).with(:active, 'no')
      provider.active = :no
    end
  end

  describe "when managing nfs" do
    it "should return :yes when active" do
      element[:nfs_space_check] = 'yes'
      expect(provider.nfs).to eq(:yes)
    end

    it "should return :no when not active" do
      element[:nfs_space_check] = 'no'
      expect(provider.nfs).to eq(:no)
    end

    it "should set active to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:nfs_space_check, 'yes')
      provider.nfs = :yes
    end

    it "should set active to \"no\" when new value is :no" do
      element.expects(:[]=).with(:nfs_space_check, 'no')
      provider.nfs = :no
    end
  end

  describe "when managing description" do
    it "should return the description field" do
      element[:description] = 'old_description'
      expect(provider.description).to eq('old_description')
    end

    it "should update the description field with the new value" do
      element.expects(:[]=).with(:description, 'new_description')
      provider.description = 'new_description'
    end
  end

  describe "when managing device" do
    it "should return the disk field" do
      element[:disk] = '/foo/bar'
      expect(provider.device).to eq('/foo/bar')
    end

    it "should update the disk field with the new value" do
      element.expects(:[]=).with(:disk, '/foo/baz')
      provider.device = '/foo/baz'
    end
  end


  describe "when managing missing" do
    it "should return :absent when undefined" do
      expect(element.child('missing')).to be_nil
      expect(provider.missing).to eq(:absent)
    end

    it "should return :yes when missing/active is \"yes\"" do
      element.path('missing')[:active] = 'yes'
      expect(provider.missing).to eq(:yes)
    end

    it "should return :no when missing/active is \"no\"" do
      element.path('missing')[:active] = 'no'
      expect(provider.missing).to eq(:no)
    end

    it "should set missing/active to \"yes\" when new value is :yes" do
      provider.missing = :yes
      expect(element.child('missing')[:active]).to eq('yes')
    end

    it "should set missing/active to \"no\" when new value is :no" do
      provider.missing = :no
      expect(element.child('missing')[:active]).to eq('no')
    end
  end

  describe "when managing warning" do
    it "should return :absent when no warning section is present" do
      if child = element.child('warning')
        element.children.delete child
      end
      expect(provider.warning).to eq(:absent)
    end

    it "should return :absent when no threshold is present" do
      element.path('warning')[:active] = 'yes'
      element.path('warning').del_attr(:threshold)
      expect(provider.warning).to eq(:absent)
    end

    it "should return :absent when active is set to \"no\"" do
      element.path('warning')[:active] = 'no'
      element.path('warning')[:threshold] = '20'
      expect(provider.warning).to eq(:absent)
    end

    it "should return the correct threshold otherwise" do
      element.path('warning')[:active] = 'yes'
      element.path('warning')[:threshold] = '20'
      expect(provider.warning).to eq('20')
    end

    it "should update active to \"no\" if new value is absent" do
      warning_section = element.path('warning')
      warning_section.expects(:[]=).with(:active, 'no')
      provider.warning = :absent
    end

    it "should set active to \"yes\" and set threshold otherwise" do
      warning_section = element.path('warning')
      warning_section.expects(:[]=).with(:active, 'yes')
      warning_section.expects(:[]=).with(:threshold, '35')
      provider.warning = '35'
    end
  end

  describe "when managing critical" do
    it "should return :absent when no error section is present" do
      if child = element.child('error')
        element.children.delete child
      end
      expect(provider.critical).to eq(:absent)
    end

    it "should return :absent when no threshold is present" do
      element.path('error')[:active] = 'yes'
      element.path('error').del_attr(:threshold)
      expect(provider.critical).to eq(:absent)
    end

    it "should return :absent when active is set to \"no\"" do
      element.path('error')[:active] = 'no'
      element.path('error')[:threshold] = '20'
      expect(provider.critical).to eq(:absent)
    end

    it "should return the correct threshold otherwise" do
      element.path('error')[:active] = 'yes'
      element.path('error')[:threshold] = '20'
      expect(provider.critical).to eq('20')
    end

    it "should update active to \"no\" if new value is absent" do
      error_section = element.path('error')
      error_section.expects(:[]=).with(:active, 'no')
      provider.critical = :absent
    end

    it "should set active to \"yes\" and set threshold otherwise" do
      error_section = element.path('error')
      error_section.expects(:[]=).with(:active, 'yes')
      error_section.expects(:[]=).with(:threshold, '35')
      provider.critical = '35'
    end
  end
end
