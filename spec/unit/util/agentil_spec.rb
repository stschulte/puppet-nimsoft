#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::Agentil do

  before :each do
    described_class.initvars
    Puppet::Util::NimsoftConfig.initvars
    described_class.stubs(:filename).returns filename
    Puppet::Util::NimsoftConfig.stubs(:add).with(filename).returns config
  end

  let :filename do
    my_fixture('sample.cfg')
  end

  let :config do
     Puppet::Util::NimsoftConfig.new(filename)
  end

  let :empty_config do
    Puppet::Util::NimsoftConfig.new(my_fixture('empty.cfg'))
  end

  describe "config" do
    it "should return the configuration" do
      described_class.config.should == config
    end

    it "should use a tabsize of 4" do
      described_class.config.tabsize.should == 4
    end
  end

  describe "parsed?" do
    it "should return false if the configuration is not yet parsed" do
      described_class.expects(:parse).never
      described_class.should_not be_parsed
    end

    it "should return true if the configuration has been parsed" do
      described_class.parse
      described_class.should be_parsed
    end
  end

  describe "parse" do
    it "should parse the configuration first if necessary" do
      config.expects(:parse)
      described_class.parse
    end

    it "should not parse the configuration if already loaded" do
      config.expects(:loaded?).returns true
      config.expects(:parse).never
      described_class.parse
    end

    it "should create a hash of landscapes" do
      described_class.parse
      expect(described_class.landscapes.size).to eq(2)

      landscapes = described_class.landscapes
      landscapes.keys.should =~ [ 1, 2 ]
      landscapes.values.each { |v| v.should be_a Puppet::Util::AgentilLandscape }
      landscapes[1].element.should == config.path('PROBE/LANDSCAPES/LANDSCAPE1')
      landscapes[2].element.should == config.path('PROBE/LANDSCAPES/LANDSCAPE2')
    end

    it "should create a hash of users" do
      described_class.parse
      expect(described_class.users.size).to eq(3)

      users = described_class.users
      users.keys.should =~ [ 1, 2, 3]
      users.values.each { |v| v.should be_a Puppet::Util::AgentilUser }
      users[1].element.should == config.path('PROBE/USERS/USER1')
      users[2].element.should == config.path('PROBE/USERS/USER2')
      users[3].element.should == config.path('PROBE/USERS/USER3')
    end

    it "should create a hash of systems" do
      described_class.parse
      expect(described_class.systems.size).to eq(3)

      systems = described_class.systems
      systems.keys.should =~ [ 1, 2, 3 ]
      systems.values.each { |v| v.should be_a Puppet::Util::AgentilSystem }
      systems[1].element.should == config.path('PROBE/SYSTEMS/SYSTEM1')
      systems[2].element.should == config.path('PROBE/SYSTEMS/SYSTEM2')
      systems[3].element.should == config.path('PROBE/SYSTEMS/SYSTEM3')
    end

    it "should create a hash of templates" do
      described_class.parse
      expect(described_class.templates.size).to eq(5)

      templates = described_class.templates
      templates.keys.should =~ [ 1, 1000000, 1000001, 1000002, 1000003 ]
      templates.values.each { |v| v.should be_a Puppet::Util::AgentilTemplate }
      templates[1].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1')
      templates[1000000].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000000')
      templates[1000001].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000001')
      templates[1000002].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000002')
      templates[1000003].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000003')
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
      Puppet::Util::NimsoftConfig.expects(:add).with(filename).returns empty_config
      described_class.parse

      described_class.landscapes.should be_empty
      described_class.systems.should be_empty
      described_class.templates.should be_empty
      described_class.users.should be_empty
    end
  end

  describe "sync" do
    it "should delegate to the config object" do
      config.expects(:sync)
      described_class.sync
    end
  end

  describe "add_landscape" do
    before { described_class.parse }

    it "should create a new landscape instance for an existing subtree" do
      expect(config.path('PROBE/LANDSCAPES').children.size).to eq(2)
      subtree = config.path('PROBE/LANDSCAPES/LANDSCAPE2')
      new_landscape = described_class.add_landscape(subtree)
      new_landscape.element.should == subtree
      expect(config.path('PROBE/LANDSCAPES').children.size).to eq(2)
    end
      
    it "should create a new subtree if no element is provided" do
      expect(config.path('PROBE/LANDSCAPES').children.size).to eq(2)
      new_landscape = described_class.add_landscape
      expect(config.path('PROBE/LANDSCAPES').children.size).to eq(3)
      new_landscape.element.should == config.path('PROBE/LANDSCAPES/LANDSCAPE3')
    end

    it "should generate a valid ID for a new landscape" do
      new_landscape = described_class.add_landscape
      new_landscape.id.should == 3
      new_landscape.element[:ID].should == "3"
    end

    it "should set ACTIVE to true for a new landscape" do
      new_landscape = described_class.add_landscape
      new_landscape.element[:ACTIVE].should == "true"
    end
  end

  describe "add_system" do
    before { described_class.parse }

    it "should create a new system instance for an existing subtree" do
      expect(config.path('PROBE/SYSTEMS').children.size).to eq(3)
      subtree = config.path('PROBE/SYSTEMS/SYSTEM3')

      new_system = described_class.add_system(subtree)

      new_system.element.should == subtree
      expect(config.path('PROBE/SYSTEMS').children.size).to eq(3)
    end
      
    it "should create a new subtree if no element is provided" do
      expect(config.path('PROBE/SYSTEMS').children.size).to eq(3)
      new_system = described_class.add_system
      expect(config.path('PROBE/SYSTEMS').children.size).to eq(4)
      new_system.element.should == config.path('PROBE/SYSTEMS/SYSTEM4')
    end

    it "should set ACTIVE to true for a new system" do
      new_system = described_class.add_system
      new_system.element[:ACTIVE].should == 'true'
    end

    it "should generate a valid ID for a new system" do
      new_system = described_class.add_system
      new_system.id.should == 4
      new_system.element[:ID].should == "4"
    end
  end

  describe "add_user" do
    before { described_class.parse }

    it "should create a new user instance for an existing subtree" do
      expect(config.path('PROBE/USERS').children.size).to eq(3)
      subtree = config.path('PROBE/SYSTEMS/USERS2')

      new_user = described_class.add_user(subtree)

      new_user.element.should == subtree
      expect(config.path('PROBE/USERS').children.size).to eq(3)
    end
      
    it "should create a new subtree if no element is provided" do
      expect(config.path('PROBE/USERS').children.size).to eq(3)
      new_user = described_class.add_user
      expect(config.path('PROBE/USERS').children.size).to eq(4)
      new_user.element.should == config.path('PROBE/USERS/USER4')
    end

    it "should generate a valid ID for a new user" do
      new_user = described_class.add_user
      new_user.id.should == 4
      new_user.element[:ID].should == "4"
    end
  end

  describe "add_template" do
    before { described_class.parse }

    it "should create a new template instance for an existing subtree" do
      expect(config.path('PROBE/TEMPLATES').children.size).to eq(5)
      subtree = config.path('PROBE/TEMPLATES/TEMPLATE1000003')

      new_template = described_class.add_template(subtree)

      new_template.element.should == subtree
      expect(config.path('PROBE/TEMPLATES').children.size).to eq(5)
    end
      
    it "should create a new subtree if no element is provided" do
      expect(config.path('PROBE/TEMPLATES').children.size).to eq(5)
      new_template = described_class.add_template
      expect(config.path('PROBE/TEMPLATES').children.size).to eq(6)
      new_template.element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000004')
    end

    it "should generate a valid ID for a new template" do
      new_template = described_class.add_template
      new_template.id.should == 1000004
      new_template.element[:ID].should == "1000004"
    end

    it "should set VERSION to 1 for a new template" do
      new_template = described_class.add_template
      new_template.element[:VERSION].should == "1"
    end
  end

  describe "del_landscape" do
    it "should remove the landscape and the corresponding config section" do
      described_class.parse
      described_class.landscapes.keys.should =~ [ 1, 2 ]
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1 LANDSCAPE2}

      described_class.del_landscape 2

      described_class.landscapes.keys.should =~ [ 1 ]
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1}
    end

    it "should rename all remaining landscapes" do
      described_class.parse
      described_class.landscapes.keys.should =~ [ 1, 2 ]
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1 LANDSCAPE2}
      described_class.del_landscape 1
      described_class.landscapes.keys.should =~ [ 2 ]
      described_class.landscapes[2].element.should == config.path('PROBE/LANDSCAPES/LANDSCAPE1')
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
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2 SYSTEM3}

      described_class.del_system 3

      described_class.systems.keys.should =~ [ 1, 2 ]
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2}
    end

    it "should rename all remaining systems" do
      described_class.parse
      described_class.systems.keys.should =~ [ 1, 2, 3 ]
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2 SYSTEM3}
      described_class.del_system 1
      described_class.systems.keys.should =~ [ 2, 3 ]
      described_class.systems[2].element.should == config.path('PROBE/SYSTEMS/SYSTEM1')
      described_class.systems[3].element.should == config.path('PROBE/SYSTEMS/SYSTEM2')
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
      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002 TEMPLATE1000003}

      described_class.del_template 1000003

      described_class.templates.keys.should =~ [ 1, 1000000, 1000001, 1000002 ]
      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002}
    end

    it "should rename all remaining templates" do
      described_class.parse
      described_class.templates.keys.should =~ [ 1, 1000000, 1000001, 1000002, 1000003 ]

      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002 TEMPLATE1000003}
      described_class.del_template 1000000
      described_class.templates.keys.should =~ [ 1, 1000001, 1000002, 1000003 ]
      described_class.templates[1].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1')
      described_class.templates[1000001].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000000')
      described_class.templates[1000002].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000001')
      described_class.templates[1000003].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000002')
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
      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2 USER3}

      described_class.del_user 3

      described_class.users.keys.should =~ [ 1, 2 ]
      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2}
    end

    it "should rename all remaining users" do
      described_class.parse
      described_class.users.keys.should =~ [ 1, 2, 3 ]

      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2 USER3}
      described_class.del_user 1
      described_class.users.keys.should =~ [ 2, 3 ]
      described_class.users[2].element.should == config.path('PROBE/USERS/USER1')
      described_class.users[3].element.should == config.path('PROBE/USERS/USER2')
    end

    it "should raise an error if user cannot be found" do
      described_class.parse
      expect { described_class.del_user 10 }.to raise_error Puppet::Error, "User with id=10 could not be found"
    end
  end
end
