#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_user'

describe Puppet::Type.type(:agentil_user).provider(:agentil), '(integration)' do
  include PuppetlabsSpec::Files

  let :resource_present do
    Puppet::Type.type(:agentil_user).new(
      :name     => 'SAP_PROBE',
      :ensure   => 'present',
      :password => 'some_encrypted_stuff'
    )
  end

  # resource does not exist, so applying the resource should
  # change nothing
  let :resource_absent do
    Puppet::Type.type(:agentil_user).new(
      :name   => 'NO_SUCH_USER',
      :ensure => 'absent'
    )
  end

  # resource does exist, applying should remove it
  let :resource_destroy do
    Puppet::Type.type(:agentil_user).new(
      :name   => 'SAP_DEV_PROBE',
      :ensure => 'absent'
    )
  end

  let :resource_create do
    Puppet::Type.type(:agentil_user).new(
      :name        => 'QAS_PROBE',
      :ensure      => 'present',
      :password    => 'password_in_qas'
    )
  end

  let :resource_modify do
    Puppet::Type.type(:agentil_user).new(
      :name     => 'DDIC',
      :ensure   => 'present',
      :password => 'new_pw'
    )
  end

  let :input do
    filename = tmpfilename('sapbasis_agentil.cfg')
    FileUtils.cp(my_fixture('sample.cfg'), filename)
    filename
  end

  let :catalog do
    Puppet::Resource::Catalog.new
  end

  def run_in_catalog(*resources)
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply
  end

  def config_should_match_fixture(filename)
    expect(JSON.parse(File.read(input))).to eq(JSON.parse(File.read(my_fixture(filename))))
  end


  before :each do
    Puppet::Util::Agentil.initvars
    Puppet::Util::Agentil.stubs(:filename).returns input
    Puppet::Type.type(:agentil_user).stubs(:defaultprovider).returns described_class
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        state = run_in_catalog(resource_absent)
        config_should_match_fixture('sample.cfg')
        expect(state.changed?).to be_empty
      end
    end

    describe "when resource is currently present" do
      it "should remove the resource" do
        state = run_in_catalog(resource_destroy)
        config_should_match_fixture('output_remove.cfg')
        expect(state.changed?).to eq([ resource_destroy ])
      end
    end
  end

  describe "ensure => present" do
    describe "when resource is currently absent" do
      it "should add the resource" do
        state = run_in_catalog(resource_create)
        config_should_match_fixture('output_add.cfg')
        expect(state.changed?).to eq([ resource_create ])
      end
    end

    describe "when resource is currently present" do
      it "should do nothing if in sync" do
        state = run_in_catalog(resource_present)
        config_should_match_fixture('sample.cfg')
        expect(state.changed?).to be_empty
      end

      it "should modify attributes if not in sync" do
        state = run_in_catalog(resource_modify)
        config_should_match_fixture('output_modify.cfg')
        expect(state.changed?).to eq([ resource_modify ])
      end
    end
  end
end
