#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_queue).provider(:nimsoft), '(integration)' do
  include PuppetlabsSpec::Files

  let :resource_present do
    Puppet::Type.type(:nimsoft_queue).new(
      :name     => 'HUB-alarm',
      :ensure   => 'present',
      :active   => 'yes',
      :type     => 'attach',
      :subject  => 'alarm'
    )
  end

  # resource does not exist, so applying the resource should
  # change nothing
  let :resource_absent do
    Puppet::Type.type(:nimsoft_queue).new(
      :name   => 'no such queue',
      :ensure => 'absent'
    )
  end

  # resource does exist, applying should remove it
  let :resource_destroy do
    Puppet::Type.type(:nimsoft_queue).new(
      :name   => 'HUB-audit',
      :ensure => 'absent'
    )
  end

  let :resource_create do
    Puppet::Type.type(:nimsoft_queue).new(
      :name         => 'HUB-get',
      :ensure       => 'present',
      :active       => 'yes',
      :type         => 'get',
      :remote_queue => 'HUB-get',
      :address      => '/DOM/PRIM/hub.example.com/hub',
      :bulk_size    => '200'
    )
  end

  let :resource_modify do
    Puppet::Type.type(:nimsoft_queue).new(
      :name        => 'HUB-qos',
      :ensure      => 'present',
      :active      => 'yes',
      :subject     => [
        'QOS_DEFINITION',
        'QOS_MESSAGE'
      ]
    )
  end

  let :input do
    filename = tmpfilename('hub.cfg')
    FileUtils.cp(my_fixture('hub.cfg'), filename)
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


  before :each do
    Puppet::Util::NimsoftConfig.initvars
    described_class.initvars
    described_class.stubs(:config).returns Puppet::Util::NimsoftConfig.add(input)

    Puppet::Type.type(:nimsoft_queue).stubs(:defaultprovider).returns described_class
  end

  describe "ensure => absent" do
    describe "when resource is currently absent" do
      it "should do nothing" do
        run_in_catalog(resource_absent).changed?.should be_empty
        File.read(input).should == File.read(my_fixture('hub.cfg'))
      end
    end

    describe "when resource is currently present" do
      it "should remove the resource" do
        state = run_in_catalog(resource_destroy)
        File.read(input).should == File.read(my_fixture('output_remove.cfg'))
        expect(state.changed?).to eq([ resource_destroy ])
      end
    end
  end

  describe "ensure => present" do
    describe "when resource is currently absent" do
      it "should add the resource" do
        state = run_in_catalog(resource_create)
        File.read(input).should == File.read(my_fixture('output_add.cfg'))
        expect(state.changed?).to eq([ resource_create ])
      end
    end

    describe "when resource is currently present" do
      it "should do nothing if in sync" do
        state = run_in_catalog(resource_present)
        File.read(input).should == File.read(my_fixture('hub.cfg'))
        expect(state.changed?).to be_empty
      end

      it "should modify attributes if not in sync" do
        state = run_in_catalog(resource_modify)
        File.read(input).should == File.read(my_fixture('output_modify.cfg'))
        expect(state.changed?).to eq([ resource_modify ])
      end
    end
  end

  describe "adding multiple resources to the catalog" do
    it "should do the right thing" do
      run_in_catalog(resource_modify, resource_present, resource_create, resource_absent, resource_destroy)
      File.read(input).should == File.read(my_fixture('output_multiple_resources.cfg'))
    end
  end
end
