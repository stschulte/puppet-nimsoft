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
      described_class.should_not be_parsed
    end

    it "should return true if the configuration has been parsed" do
      described_class.parse
      described_class.should be_parsed
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
      landscapes.keys.should =~ [ 1, 2 ]
      landscapes.values.each { |v| v.should be_a Puppet::Util::AgentilLandscape }
      landscapes[1].element.should == described_class.config["SYSTEMS"][0]
      landscapes[2].element.should == described_class.config["SYSTEMS"][1]
    end

    it "should create a hash of users" do
      described_class.parse
      expect(described_class.users.size).to eq(3)

      users = described_class.users
      users.keys.should =~ [ 1, 2, 3]
      users.values.each { |v| v.should be_a Puppet::Util::AgentilUser }
      users[1].element.should == described_class.config["USER_PROFILES"][0]
      users[2].element.should == described_class.config["USER_PROFILES"][1]
      users[3].element.should == described_class.config["USER_PROFILES"][2]
    end

    it "should create a hash of systems" do
      described_class.parse
      expect(described_class.systems.size).to eq(3)

      systems = described_class.systems
      systems.keys.should =~ [ 1, 2, 3 ]
      systems.values.each { |v| v.should be_a Puppet::Util::AgentilSystem }
      systems[1].element.should == described_class.config["CONNECTORS"][0]
      systems[2].element.should == described_class.config["CONNECTORS"][1]
      systems[3].element.should == described_class.config["CONNECTORS"][2]
    end

    it "should create a hash of templates" do
      described_class.parse
      expect(described_class.templates.size).to eq(5)

      templates = described_class.templates
      templates.keys.should =~ [ 1, 1000000, 1000001, 1000002, 1000003 ]
      templates.values.each { |v| v.should be_a Puppet::Util::AgentilTemplate }
      templates[1].element.should ==       described_class.config["TEMPLATES"][0]
      templates[1000000].element.should == described_class.config["TEMPLATES"][1]
      templates[1000001].element.should == described_class.config["TEMPLATES"][2]
      templates[1000002].element.should == described_class.config["TEMPLATES"][3]
      templates[1000003].element.should == described_class.config["TEMPLATES"][4]
    end

    it "should assign systems to system templates" do
      described_class.parse
      described_class.templates[1].assigned_system.should be_nil
      described_class.templates[1000000].assigned_system.should be_nil
      described_class.templates[1000001].assigned_system.should == described_class.systems[1]
      described_class.templates[1000002].assigned_system.should == described_class.systems[2]
      described_class.templates[1000003].assigned_system.should be_nil
    end

    it "should leave hashes empty if configuration is empty" do
      described_class.stubs(:filename).returns my_fixture('empty.cfg')
      described_class.parse

      described_class.landscapes.should be_empty
      described_class.systems.should be_empty
      described_class.templates.should be_empty
      described_class.users.should be_empty
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
      new_landscape.element.should == existing_element

      # make sure we have not created a new system
      expect(described_class.config["SYSTEMS"].size).to eq(old_size)
    end
      
    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["SYSTEMS"].size
      new_landscape = described_class.add_landscape
      expect(described_class.config["SYSTEMS"].size).to eq(old_size+1)
      new_landscape.element.should == described_class.config["SYSTEMS"][-1]
    end

    it "should generate a valid ID for a new landscape" do
      new_landscape = described_class.add_landscape
      new_landscape.id.should == 3
      new_landscape.element["ID"].should == "3"
    end

    it "should set ACTIVE to true for a new landscape" do
      new_landscape = described_class.add_landscape
      new_landscape.element["ACTIVE"].should == "true"
    end
  end

  describe "add_system" do
    before { described_class.parse }

    it "should create a new system instance for an existing subtree" do
      old_size = described_class.config["CONNECTORS"].size
      existing_element = described_class.config["CONNECTORS"][2]

      new_system = described_class.add_system(existing_element)
      new_system.element.should == existing_element

      expect(described_class.config["CONNECTORS"].size).to eq(old_size)
    end
      
    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["CONNECTORS"].size
      new_system = described_class.add_system
      expect(described_class.config["CONNECTORS"].size).to eq(old_size+1)
      new_system.element.should == described_class.config["CONNECTORS"][-1]
    end

    it "should set ACTIVE to true for a new system" do
      new_system = described_class.add_system
      new_system.element["ACTIVE"].should == 'true'
    end

    it "should generate a valid ID for a new system" do
      new_system = described_class.add_system
      new_system.id.should == 4
      new_system.element["ID"].should == "4"
    end
  end

  describe "add_user" do
    before { described_class.parse }

    it "should create a new user instance for an existing subtree" do
      old_size = described_class.config["USER_PROFILES"].size
      existing_element = described_class.config["USER_PROFILES"][1]

      new_user = described_class.add_user(existing_element)
      new_user.element.should == existing_element

      expect(described_class.config["USER_PROFILES"].size).to eq(old_size)
    end
      
    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["USER_PROFILES"].size
      new_user = described_class.add_user
      expect(described_class.config["USER_PROFILES"].size).to eq(old_size+1)
      new_user.element.should == described_class.config["USER_PROFILES"][-1]
    end

    it "should generate a valid ID for a new user" do
      new_user = described_class.add_user
      new_user.id.should == 4
      new_user.element["ID"].should == "4"
    end
  end

  describe "add_template" do
    before { described_class.parse }

    it "should create a new template instance for an existing subtree" do
      old_size = described_class.config["TEMPLATES"].size
      existing_element = described_class.config["TEMPLATES"][3]

      new_template = described_class.add_template(existing_element)
      new_template.element.should == existing_element

      expect(described_class.config["TEMPLATES"].size).to eq(old_size)
    end
      
    it "should append a new subtree if no element is provided" do
      old_size = described_class.config["TEMPLATES"].size
      new_template = described_class.add_template
      expect(described_class.config["TEMPLATES"].size).to eq(old_size+1)
      new_template.element.should == described_class.config["TEMPLATES"][-1]
    end

    it "should generate a valid ID for a new template" do
      new_template = described_class.add_template
      new_template.id.should == 1000004
      new_template.element["ID"].should == "1000004"
    end

    it "should set VERSION to 2.0 for a new template" do
      new_template = described_class.add_template
      new_template.element["VERSION"].should == "2.0"
    end
  end

  describe "del_landscape" do
    it "should remove the landscape and the corresponding config section" do
      described_class.parse
      described_class.landscapes.keys.should =~ [ 1, 2 ]
      described_class.config["SYSTEMS"].map{|h| h["NAME"]}.should == %w{sap01.example.com sapdev.example.com}

      described_class.del_landscape 1

      described_class.landscapes.keys.should =~ [ 2 ]
      described_class.config["SYSTEMS"].map{|h| h["NAME"]}.should == %w{sapdev.example.com}
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
      described_class.systems.keys.should =~ [ 1, 2, 3 ]
      described_class.config["CONNECTORS"].map{|h| h["NAME"]}.should == %w{PRO_sap01 PRO_sap02 XXX_dummy}

      described_class.del_system 2

      described_class.systems.keys.should =~ [ 1, 3 ]
      described_class.config["CONNECTORS"].map{|h| h["NAME"]}.should == %w{PRO_sap01 XXX_dummy}
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
      described_class.templates.keys.should =~ [ 1, 1000000, 1000001, 1000002, 1000003 ]
      described_class.config["TEMPLATES"].map{|h| h["NAME"]}.should == [
        "Vendor template",
        "Custom Template",
        "System Template for system sap01_PRO",
        "System Template for system sap02_PRO",
        "System Template for system id 3"
      ]

      described_class.del_template 1000000

      described_class.templates.keys.should =~ [ 1, 1000001, 1000002, 1000003 ]
      described_class.config["TEMPLATES"].map{|h| h["NAME"]}.should == [
        "Vendor template",
        "System Template for system sap01_PRO",
        "System Template for system sap02_PRO",
        "System Template for system id 3"
      ]
    end

    it "should raise an error if template cannot be found" do
      described_class.parse
      expect { described_class.del_template 1000009 }.to raise_error Puppet::Error, "Template with id=1000009 could not be found"
    end
  end

  describe "del_user" do
    it "should remove the user and the corresponding config section" do
      described_class.parse
      described_class.users.keys.should =~ [ 1, 2, 3 ]
      described_class.config["USER_PROFILES"].map{|h| h["USER"]}.should == %w{SAP_PRO SAP_QAS SAP_DEV}

      described_class.del_user 3

      described_class.users.keys.should =~ [ 1, 2 ]
      described_class.config["USER_PROFILES"].map{|h| h["USER"]}.should == %w{SAP_PRO SAP_QAS}
    end

    it "should raise an error if user cannot be found" do
      described_class.parse
      expect { described_class.del_user 10 }.to raise_error Puppet::Error, "User with id=10 could not be found"
    end
  end
end
