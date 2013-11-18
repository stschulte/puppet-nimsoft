#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_instance) do

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [ :name ]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :template, :mandatory, :criticality, :autoclear].each do |property|
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

    describe "for template" do
      it "should allow a simple word as a template" do
        described_class.new(:name => 'foo', :template => 'MyTemplate')[:template].should == 'MyTemplate'
      end

      it "should allow templates with spaces" do
        described_class.new(:name => 'foo', :template => 'Custom ABAP Production')[:template].should == 'Custom ABAP Production'
      end
    end

    describe "for mandatory" do
      it "should allow true" do
        described_class.new(:name => 'foo', :mandatory => 'true')[:mandatory].should == :true
      end

      it "should allow false" do
        described_class.new(:name => 'foo', :mandatory => 'false')[:mandatory].should == :false
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :mandatory => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for autoclear" do
      it "should allow true" do
        described_class.new(:name => 'foo', :autoclear => 'true')[:autoclear].should == :true
      end

      it "should allow false" do
        described_class.new(:name => 'foo', :autoclear => 'false')[:autoclear].should == :false
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :autoclear => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for criticality" do
      [ :info, :warning, :minor, :major, :critical ].each do |criticality|
        it "should support #{criticality}" do
          described_class.new(:name => 'foo', :criticality => criticality.to_s)[:criticality].should == criticality
        end
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'foo', :criticality => 'fatal') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

  end

  describe "autorequire" do
    let :instance_provider do
      Puppet::Type.type(:agentil_instance).provide(:fake_agentil_instance_provider) { mk_resource_methods }
    end

    let :template_provider do
      Puppet::Type.type(:agentil_template).provide(:fake_agentil_template_provider) { mk_resource_methods }
    end

    let :template do
      Puppet::Type.type(:agentil_template).new(:name => 'System template 1', :ensure => :present)
    end

    let :instance do
      described_class.new(:name => 'foo', :ensure => :present, :template => 'System template 1')
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:agentil_instance).stubs(:defaultprovider).returns instance_provider
      Puppet::Type.type(:agentil_template).stubs(:defaultprovider).returns template_provider
    end

    describe "template" do
      it "should not autorequire a template if none found" do
        catalog.add_resource instance
        instance.autorequire.should be_empty
      end

      it "should autorequire a matching template" do
        catalog.add_resource instance
        catalog.add_resource template

        reqs = instance.autorequire
        reqs.size.should == 1
        reqs[0].source.must == template
        reqs[0].target.must == instance
      end
    end
  end
end
