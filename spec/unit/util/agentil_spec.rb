#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::Agentil do

  before :each do
    described_class.initvars
    described_class.stubs(:filename).returns config
  end

  let :config do
    my_fixture('sample.cfg')
  end

  describe "parsed?" do
    it "should return false if the configuration is not yet parsed" do
      expect(described_class).to_not be_parsed
    end

    it "should return true if the configuration has been parsed" do
      described_class.parse
      expect(described_class).to be_parsed
    end
  end

  describe "parse" do
    it "should fail if json is not available" do
      Puppet.features.expects(:json?).returns false
      expect { described_class.parse }.to raise_error(Puppet::Error, /Please install json first/)
    end

    it "should create a hash of landscapes" do
      described_class.parse
      expect(described_class.landscapes.size).to eq(2)

      landscapes = described_class.landscapes
      expect(landscapes.keys).to contain_exactly(1, 2)
      landscapes.values.each { |v| expect(v).to be_a(Puppet::Util::AgentilLandscape) }
      expect(landscapes[1].element).to eq(described_class.config["SYSTEMS"][0])
      expect(landscapes[2].element).to eq(described_class.config["SYSTEMS"][1])
    end

    it "should create a hash of users" do
      described_class.parse
      expect(described_class.users.size).to eq(3)

      users = described_class.users
      expect(users.keys).to contain_exactly(1,2,3)
      users.values.each { |v| expect(v).to be_a(Puppet::Util::AgentilUser) }
      expect(users[1].element).to eq(described_class.config["USER_PROFILES"][0])
      expect(users[2].element).to eq(described_class.config["USER_PROFILES"][1])
      expect(users[3].element).to eq(described_class.config["USER_PROFILES"][2])
    end

    it "should create a hash of systems" do
      described_class.parse
      expect(described_class.systems.size).to eq(3)

      systems = described_class.systems
      expect(systems.keys).to contain_exactly(1,2,3)
      systems.values.each { |v| expect(v).to be_a(Puppet::Util::AgentilSystem) }
      expect(systems[1].element).to eq(described_class.config["CONNECTORS"][0])
      expect(systems[2].element).to eq(described_class.config["CONNECTORS"][1])
      expect(systems[3].element).to eq(described_class.config["CONNECTORS"][2])
    end

    it "should create a hash of templates" do
      described_class.parse
      expect(described_class.templates.size).to eq(5)

      templates = described_class.templates
      expect(templates.keys).to contain_exactly(1, 1000000, 1000001, 1000002, 1000003)
      templates.values.each { |v| expect(v).to be_a(Puppet::Util::AgentilTemplate) }
      expect(templates[1].element).to eq(described_class.config["TEMPLATES"][0])
      expect(templates[1000000].element).to eq(described_class.config["TEMPLATES"][1])
      expect(templates[1000001].element).to eq(described_class.config["TEMPLATES"][2])
      expect(templates[1000002].element).to eq(described_class.config["TEMPLATES"][3])
      expect(templates[1000003].element).to eq(described_class.config["TEMPLATES"][4])
    end

    it "should assign systems to system templates" do
      described_class.parse
      expect(described_class.templates[1].assigned_system).to be_nil
      expect(described_class.templates[1000000].assigned_system).to be_nil
      expect(described_class.templates[1000001].assigned_system).to eq(described_class.systems[1])
      expect(described_class.templates[1000002].assigned_system).to eq(described_class.systems[2])
      expect(described_class.templates[1000003].assigned_system).to be_nil
    end

    it "should leave hashes empty if configuration is empty" do
      described_class.stubs(:filename).returns my_fixture('empty.cfg')
      described_class.parse

      expect(described_class.landscapes).to be_empty
      expect(described_class.systems).to be_empty
      expect(described_class.templates).to be_empty
      expect(described_class.users).to be_empty
    end
  end

  describe "sync" do
    it "should fail if json is not available" do
      Puppet.features.expects(:json?).returns false
      expect { described_class.sync }.to raise_error(Puppet::Error, /Please install json first/)
    end

    it "should delegate to the config object" do
      File.expects(:open).with(config, 'w')
      described_class.sync
    end
  end

  describe "add_landscape" do
    before { described_class.parse }

    it "should create a new landscape instance for an existing subtree" do
      old_size = described_class.config["SYSTEMS"].size
      existing_element = described_class.config["SYSTEMS"][1]
      new_landscape = described_class.add_landscape(existing_element)
      expect(new_landscape.element).to eq(existing_element)

      # make sure we have not created a new system
      expect(described_class.config["SYSTEMS"].size).to eq(old_size)
    end

    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["SYSTEMS"].size
      new_landscape = described_class.add_landscape
      expect(described_class.config["SYSTEMS"].size).to eq(old_size+1)
      expect(new_landscape.element).to eq(described_class.config["SYSTEMS"][-1])
    end

    it "should generate a valid ID for a new landscape" do
      new_landscape = described_class.add_landscape
      expect(new_landscape.id).to eq(3)
      expect(new_landscape.element["ID"]).to eq("3")
    end

    it "should set ACTIVE to true for a new landscape" do
      new_landscape = described_class.add_landscape
      expect(new_landscape.element["ACTIVE"]).to eq("true")
    end
  end

  describe "add_system" do
    before { described_class.parse }

    it "should create a new system instance for an existing subtree" do
      old_size = described_class.config["CONNECTORS"].size
      existing_element = described_class.config["CONNECTORS"][2]

      new_system = described_class.add_system(existing_element)
      expect(new_system.element).to eq(existing_element)

      expect(described_class.config["CONNECTORS"].size).to eq(old_size)
    end

    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["CONNECTORS"].size
      new_system = described_class.add_system
      expect(described_class.config["CONNECTORS"].size).to eq(old_size+1)
      expect(new_system.element).to eq(described_class.config["CONNECTORS"][-1])
    end

    it "should set ACTIVE to true for a new system" do
      new_system = described_class.add_system
      expect(new_system.element["ACTIVE"]).to eq('true')
    end

    it "should generate a valid ID for a new system" do
      new_system = described_class.add_system
      expect(new_system.id).to eq(4)
      expect(new_system.element["ID"]).to eq("4")
    end
  end

  describe "add_user" do
    before { described_class.parse }

    it "should create a new user instance for an existing subtree" do
      old_size = described_class.config["USER_PROFILES"].size
      existing_element = described_class.config["USER_PROFILES"][1]

      new_user = described_class.add_user(existing_element)
      expect(new_user.element).to eq(existing_element)

      expect(described_class.config["USER_PROFILES"].size).to eq(old_size)
    end

    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["USER_PROFILES"].size
      new_user = described_class.add_user
      expect(described_class.config["USER_PROFILES"].size).to eq(old_size+1)
      expect(new_user.element).to eq(described_class.config["USER_PROFILES"][-1])
    end

    it "should generate a valid ID for a new user" do
      new_user = described_class.add_user
      expect(new_user.id).to eq(4)
      expect(new_user.element["ID"]).to eq("4")
    end
  end

  describe "add_template" do
    before { described_class.parse }

    it "should create a new template instance for an existing subtree" do
      old_size = described_class.config["TEMPLATES"].size
      existing_element = described_class.config["TEMPLATES"][3]

      new_template = described_class.add_template(existing_element)
      expect(new_template.element).to eq(existing_element)

      expect(described_class.config["TEMPLATES"].size).to eq(old_size)
    end

    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["TEMPLATES"].size
      new_template = described_class.add_template
      expect(described_class.config["TEMPLATES"].size).to eq(old_size+1)
      expect(new_template.element).to eq(described_class.config["TEMPLATES"][-1])
    end

    it "should generate a valid ID for a new template" do
      new_template = described_class.add_template
      expect(new_template.id).to eq(1000004)
      expect(new_template.element["ID"]).to eq("1000004")
    end

    it "should set VERSION to 1 for a new template" do
      new_template = described_class.add_template
      expect(new_template.element["VERSION"]).to eq("1")
    end
  end

  describe "del_landscape" do
    it "should remove the landscape and the corresponding config section" do
      described_class.parse
      expect(described_class.landscapes.keys).to contain_exactly(1, 2)
      expect(described_class.config["SYSTEMS"].map{|h| h["NAME"]}).to eq(%w{sap01.example.com sapdev.example.com})

      described_class.del_landscape 1

      expect(described_class.landscapes.keys).to contain_exactly(2)
      expect(described_class.config["SYSTEMS"].map{|h| h["NAME"]}).to eq(%w{sapdev.example.com})
    end

    it "should remove dependent systems" do
      described_class.parse
      described_class.expects(:del_system).with(1)
      described_class.expects(:del_system).with(3)
      described_class.del_landscape 1
    end

    it "should raise an error if landsscape cannot be found" do
      described_class.parse
      expect { described_class.del_landscape 5 }.to raise_error Puppet::Error, "Landscape with id=5 could not be found"
    end
  end

  describe "del_system" do
    it "should remove the system and the corresponding config section" do
      described_class.parse
      expect(described_class.systems.keys).to contain_exactly(1, 2, 3)
      expect(described_class.config["CONNECTORS"].map{|h| h["NAME"]}).to eq(%w{PRO_sap01 PRO_sap02 XXX_dummy})

      described_class.del_system 2

      expect(described_class.systems.keys).to contain_exactly(1, 3)
      expect(described_class.config["CONNECTORS"].map{|h| h["NAME"]}).to eq(%w{PRO_sap01 XXX_dummy})
    end

    it "should remove dependent templates" do
      described_class.parse
      described_class.expects(:del_template).with(1000002)
      described_class.del_system 2
    end

    it "should raise an error if system cannot be found" do
      described_class.parse
      expect { described_class.del_system 5 }.to raise_error Puppet::Error, "System with id=5 could not be found"
    end
  end

  describe "del_template" do
    it "should remove the template and the corresponding config section" do
      described_class.parse
      expect(described_class.templates.keys).to contain_exactly(1, 1000000, 1000001, 1000002, 1000003)
      expect(described_class.config["TEMPLATES"].map{|h| h["NAME"]}).to eq([
        "Vendor template",
        "Custom Template",
        "System Template for system sap01_PRO",
        "System Template for system sap02_PRO",
        "System Template for system id 3"
      ])

      described_class.del_template 1000000

      expect(described_class.templates.keys).to contain_exactly(1, 1000001, 1000002, 1000003)
      expect(described_class.config["TEMPLATES"].map{|h| h["NAME"]}).to eq([
        "Vendor template",
        "System Template for system sap01_PRO",
        "System Template for system sap02_PRO",
        "System Template for system id 3"
      ])
    end

    it "should raise an error if template cannot be found" do
      described_class.parse
      expect { described_class.del_template 1000009 }.to raise_error Puppet::Error, "Template with id=1000009 could not be found"
    end
  end

  describe "del_user" do
    it "should remove the user and the corresponding config section" do
      described_class.parse
      expect(described_class.users.keys).to contain_exactly(1,2,3)
      expect(described_class.config["USER_PROFILES"].map{|h| h["USER"]}).to eq(%w{SAP_PRO SAP_QAS SAP_DEV})

      described_class.del_user 3

      expect(described_class.users.keys).to contain_exactly(1,2)
      expect(described_class.config["USER_PROFILES"].map{|h| h["USER"]}).to eq(%w{SAP_PRO SAP_QAS})
    end

    it "should raise an error if user cannot be found" do
      described_class.parse
      expect { described_class.del_user 10 }.to raise_error Puppet::Error, "User with id=10 could not be found"
    end
  end
end
