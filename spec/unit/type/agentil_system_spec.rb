#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_system) do

  it "should have name as its keyattribute" do
    expect(described_class.key_attributes).to eq([ :name ])
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should have a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:sid, :host, :stack, :user, :client, :group, :landscape, :system_template, :templates, :ccms_mode, :ensure].each do |property|
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

    describe "for host" do
      it "should accept a shortname" do
        expect(described_class.new(:name => 'foo', :host => 'sap01')[:host]).to eq('sap01')
      end

      it "should support an fqdn" do
        expect(described_class.new(:name => 'foo', :host => 'sap01.example.com')[:host]).to eq('sap01.example.com')
      end
    end

    describe "for ip" do
      it "should support an empty array" do
        expect(described_class.new(:name => 'foo', :ip => [])[:ip]).to be_empty
      end

      it "should support a single value" do
        expect(described_class.new(:name => 'foo', :ip => '192.168.0.1')[:ip]).to eq(['192.168.0.1'])
      end

      it "should support multiple values" do
        expect(described_class.new(:name => 'foo', :ip => [ '192.168.0.1', '192.168.0.2'])[:ip]).to eq(['192.168.0.1', '192.168.0.2'])
      end
    end

    describe "stack" do
      it "should support abap" do
        expect(described_class.new(:name => 'foo', :stack => 'abap')[:stack]).to eq(:abap)
      end

      it "should support java" do
        expect(described_class.new(:name => 'foo', :stack => 'java')[:stack]).to eq(:java)
      end

      it "should support dual" do
        expect(described_class.new(:name => 'foo', :stack => 'dual')[:stack]).to eq(:dual)
      end

      it "should not support anything else" do
        expect { described_class.new(:name => 'foo', :stack => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "user" do
      [ 'FOOBAR', 'SAP_PROBE', 'PROBE001' ].each do |user|
        it "should accept a valid name like #{name}" do
          expect(described_class.new(:name => 'foo', :user => user, :ensure => 'present')[:user]).to eq(user)
        end
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'foo', :user => 'SAP PROBE', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end

      it "should not allow the first character to be a digit" do
        expect { described_class.new(:name => 'foo', :user => '1SAP_PROBE', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end

      it "should not allow lowercase letters" do
        expect { described_class.new(:name => 'foo', :user => 'sap_probe', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end

      it "should not allow hyphens" do
        expect { described_class.new(:name => 'foo', :user => 'SAP-PROBE', :ensure => 'present') }.to raise_error Puppet::Error, /Username must only contain uppercase letters, digits and underscores/
      end
    end

    describe "client" do
      [ '000', '100', '021'].each do |client|
        it "should support a valid client like #{client}" do
          expect(described_class.new(:name => 'foo', :client => client)[:client]).to eq(client)
        end
      end

      it "should not support numbers with less than 3 digits" do
        expect { described_class.new(:name => 'foo', :client => "10") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "1") }.to raise_error Puppet::Error, /must consist of three digits/
      end

      it "should not support numbers with more than 3 digits" do
        expect { described_class.new(:name => 'foo', :client => "0100") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "1000") }.to raise_error Puppet::Error, /must consist of three digits/
      end

      it "should not support text" do
        expect { described_class.new(:name => 'foo', :client => "x000") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "x00") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "0x0") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "00x") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "000x") }.to raise_error Puppet::Error, /must consist of three digits/
        expect { described_class.new(:name => 'foo', :client => "xxx") }.to raise_error Puppet::Error, /must consist of three digits/
      end
    end

    describe "group" do
      it "should support a simple name" do
        expect(described_class.new(:name => 'foo', :group => 'SPACE')[:group]).to eq('SPACE')
      end

      it "should support underscores" do
        expect(described_class.new(:name => 'foo', :group => 'LOGON_GROUP')[:group]).to eq('LOGON_GROUP')
      end
    end

    describe "landscape" do
      it "should support a simple name" do
        expect(described_class.new(:name => 'foo', :landscape => 'ERP')[:landscape]).to eq('ERP')
      end

      it "should accept a shortname" do
        expect(described_class.new(:name => 'foo', :landscape => 'sap01')[:landscape]).to eq('sap01')
      end

      it "should support an fqdn" do
        expect(described_class.new(:name => 'foo', :landscape => 'sap01.example.com')[:landscape]).to eq('sap01.example.com')
      end
    end

    describe "system_template" do
      it "should allow a simple word as a system_template" do
        expect(described_class.new(:name => 'foo', :system_template => 'MyTemplate')[:system_template]).to eq('MyTemplate')
      end

      it "should allow system_template with spaces" do
        expect(described_class.new(:name => 'foo', :system_template => 'Custom ABAP Production')[:system_template]).to eq('Custom ABAP Production')
      end
    end

    describe "templates" do
      it "should allow an empty array" do
        expect(described_class.new(:name => 'foo', :templates => [])[:templates]).to be_empty
      end
      
      it "should allow a single template" do
        expect(described_class.new(:name => 'foo', :templates => 'Custom ABAP Production')[:templates]).to eq([ 'Custom ABAP Production' ])
      end

      it "should allow multiple templates as an array" do
        expect(described_class.new(:name => 'foo', :templates => [ 'Template 1', 'Template 2'])[:templates]).to eq([ 'Template 1', 'Template 2' ])
      end
    end

    describe "ccms_mode" do
      it "should allow strict" do
        expect(described_class.new(:name => 'foo', :ccms_mode => 'strict')[:ccms_mode]).to eq(:strict)
      end

      it "should allow aggregated" do
        expect(described_class.new(:name => 'foo', :ccms_mode => 'aggregated')[:ccms_mode]).to eq(:aggregated)
      end

      it "should not allow other values" do
        expect { described_class.new(:name => 'foo', :ccms_mode => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end

  describe "when checking insync" do
    describe "for ip" do
      it "should consider two emty arrays as insync" do
        expect(described_class.new(:name => 'foo', :ip => []).parameter(:ip)).to be_insync []
      end

      it "should consider insync if the order of ipaddresses is identical" do
        expect(described_class.new(:name => 'foo', :ip => %w{192.168.0.12 192.168.0.20 192.168.0.13}).parameter(:ip)).to be_insync %w{192.168.0.12 192.168.0.20 192.168.0.13}
      end

      it "should consider insync if the order of ipaddresses is different" do
        expect(described_class.new(:name => 'foo', :ip => %w{192.168.0.12 192.168.0.20 192.168.0.13}).parameter(:ip)).to be_insync %w{192.168.0.13 192.168.0.20 192.168.0.12}
      end

      it "should not be in sync if there is one ipaddresses too many" do
        expect(described_class.new(:name => 'foo', :ip => %w{192.168.0.12 192.168.0.20}).parameter(:ip)).to_not be_insync %w{192.168.0.12 192.168.0.20 192.168.0.13}
      end

      it "should not be in sync if there is one ipaddresses too less" do
        expect(described_class.new(:name => 'foo', :ip => %w{192.168.0.12 192.168.0.20 192.168.0.13}).parameter(:ip)).to_not be_insync %w{192.168.0.20 192.168.0.13}
      end
    end

    describe "for templates" do
      it "should consider two emty arrays as insync" do
        expect(described_class.new(:name => 'foo', :templates => []).parameter(:templates)).to be_insync []
      end

      it "should consider insync if the order of templates is identical" do
        expect(described_class.new(:name => 'foo', :templates => [ 't1', 't2', 't3']).parameter(:templates)).to be_insync %w{t1 t2 t3}
      end

      it "should consider insync if the order of templates is different" do
        expect(described_class.new(:name => 'foo', :templates => [ 't1', 't2', 't3']).parameter(:templates)).to be_insync %w{t3 t1 t2}
      end

      it "should not be in sync if there is one template too many" do
        expect(described_class.new(:name => 'foo', :templates => [ 't1', 't2', 't3']).parameter(:templates)).to_not be_insync %w{t1 t2 t3 t4}
      end

      it "should not be in sync if there is one template too less" do
        expect(described_class.new(:name => 'foo', :templates => [ 't1', 't2', 't3']).parameter(:templates)).to_not be_insync %w{t1 t2}
      end
    end
  end

  describe "autorequire" do
    let :landscape_provider do
      Puppet::Type.type(:agentil_landscape).provide(:fake_agentil_landscape_provider) { mk_resource_methods }
    end

    let :system_provider do
      Puppet::Type.type(:agentil_system).provide(:fake_agentil_system_provider) { mk_resource_methods }
    end

    let :template_provider do
      Puppet::Type.type(:agentil_template).provide(:fake_agentil_template_provider) { mk_resource_methods }
    end

    let :user_provider do
      Puppet::Type.type(:agentil_user).provide(:fake_agentil_user_provider) { mk_resource_methods }
    end

    let :landscape do
      Puppet::Type.type(:agentil_landscape).new(:name => 'landscape01', :ensure => :present)
    end

    let :system do
      described_class.new(
        :name             => 'sap01p.example.com',
        :ensure           => :present,
        :landscape        => 'landscape01',
        :user             => 'SAP_PROBE',
        :system_template  => 'Template 1',
        :templates        => [ 'Template 2', 'Template 3']
      )
    end

    let :user do
      Puppet::Type.type(:agentil_user).new(:name => 'SAP_PROBE', :ensure => :present)
    end

    let :template1 do
      Puppet::Type.type(:agentil_template).new(:name => 'Template 1', :ensure => :present)
    end

    let :template2 do
      Puppet::Type.type(:agentil_template).new(:name => 'Template 2', :ensure => :present)
    end

    let :template3 do
      Puppet::Type.type(:agentil_template).new(:name => 'Template 3', :ensure => :present)
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:agentil_landscape).stubs(:defaultprovider).returns landscape_provider
      Puppet::Type.type(:agentil_system).stubs(:defaultprovider).returns system_provider
      Puppet::Type.type(:agentil_user).stubs(:defaultprovider).returns user_provider
      Puppet::Type.type(:agentil_template).stubs(:defaultprovider).returns template_provider
    end

    describe "landscape" do
      it "should not autorequire a landscape when no matching landscape can be found" do
        catalog.add_resource system
        expect(system.autorequire).to be_empty
      end

      it "should autorequire a matching landscape" do
        catalog.add_resource system
        catalog.add_resource landscape
        reqs = system.autorequire
        expect(reqs.size).to eq(1)
        expect(reqs[0].source.ref).to eq(landscape.ref)
        expect(reqs[0].target.ref).to eq(system.ref)
      end
    end

    describe "user" do
      it "should not autorequire a user when no matching user can be found" do
        catalog.add_resource system
        expect(system.autorequire).to be_empty
      end

      it "should autorequire a matching user" do
        catalog.add_resource system
        catalog.add_resource user
        reqs = system.autorequire
        expect(reqs.size).to eq(1)
        expect(reqs[0].source.ref).to eq(user.ref)
        expect(reqs[0].target.ref).to eq(system.ref)
      end
    end

    describe "template" do
      it "should not autorequire a template when no matching tempate can be found" do
        catalog.add_resource system
        expect(system.autorequire).to be_empty
      end

      it "should autorequire the default template" do
        catalog.add_resource system
        catalog.add_resource template1
        reqs = system.autorequire
        expect(reqs.size).to eq(1)
        expect(reqs[0].source.ref).to eq(template1.ref)
        expect(reqs[0].target.ref).to eq(system.ref)
      end

      it "should autorequire the templates" do
        catalog.add_resource system
        catalog.add_resource template2
        reqs = system.autorequire
        expect(reqs.size).to eq(1)
        expect(reqs[0].source.ref).to eq(template2.ref)
        expect(reqs[0].target.ref).to eq(system.ref)
      end

      it "should autorequire both the default template and templates" do
        catalog.add_resource system
        catalog.add_resource template1
        catalog.add_resource template2
        catalog.add_resource template3
        reqs = system.autorequire
        expect(reqs.size).to eq(3)
        expect(reqs[0].source.ref).to eq(template1.ref)
        expect(reqs[0].target.ref).to eq(system.ref)
        expect(reqs[1].source.ref).to eq(template2.ref)
        expect(reqs[1].target.ref).to eq(system.ref)
        expect(reqs[2].source.ref).to eq(template3.ref)
        expect(reqs[2].target.ref).to eq(system.ref)
      end
    end
  end

end
