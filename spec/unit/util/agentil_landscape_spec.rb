#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_landscape'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::AgentilLandscape do

  before :each do
    described_class.initvars
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::NimsoftConfig.stubs(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns config
  end

  let :config do
    Puppet::Util::NimsoftConfig.new(my_fixture('sample.cfg'))
  end

  let :empty_config do
    Puppet::Util::NimsoftConfig.new(my_fixture('empty.cfg'))
  end

  describe "class method config" do
    it "should load the configuration if necessary" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').once.returns config
      described_class.config
    end

    it "should not load the configuration if already loaded" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').once.returns config
      described_class.config
      described_class.config
    end

    it "should use a tabsize of 4" do
      described_class.config.tabsize.should == 4
    end
  end

  describe "class method root" do
    it "should point to the landscape subtree" do
      root = described_class.root
      root.name.should == 'LANDSCAPES'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == config
    end

    it "should not fail but create the landscape subtree if necessary" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      root = described_class.root
      root.name.should == 'LANDSCAPES'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == empty_config
    end
  end

  describe "class method parse" do
    it "should create add a new object for each landscape" do
      config.parse
      described_class.expects(:add).with('sap01.example.com', config.path('PROBE/LANDSCAPES/LANDSCAPE1'))
      described_class.expects(:add).with('sapdev.example.com', config.path('PROBE/LANDSCAPES/LANDSCAPE2'))
      described_class.parse
    end

    it "should parse the configuration first if necessary" do
      config.expects(:parse)
      described_class.parse
    end

    it "should not parse the configuration if already loaded" do
      config.expects(:loaded?).returns true
      config.expects(:parse).never
      described_class.parse
    end
  end

  describe "class method sync" do
    it "should delegate to the config object" do
      config.expects(:sync)
      described_class.sync
    end
  end

  describe "class method landscapes" do
    it "should return a hash of landscapes" do
      h = described_class.landscapes
      h.keys.should == [ 'sap01.example.com', 'sapdev.example.com' ]
      h['sap01.example.com'].should be_a Puppet::Util::AgentilLandscape
      h['sapdev.example.com'].should be_a Puppet::Util::AgentilLandscape
    end

    it "should return an empty hash if configuration is empty" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      described_class.landscapes.keys.should be_empty
    end

    it "should only parse the config once" do
      config.expects(:parse).once
      described_class.landscapes
      described_class.landscapes
    end
  end

  describe "class method loaded?" do
    it "should be false before the configuration file has been parsed" do
      described_class.should_not be_loaded
    end

    it "should be true after the configuration file has been parsed" do
      described_class.parse
      described_class.should be_loaded
    end
  end


  describe "class method add" do
    it "should not add a landscape if already present" do
      existing_entry = described_class.landscapes['sap01.example.com']
      described_class.expects(:new).never
      described_class.add('sap01.example.com').should == existing_entry
    end

    it "should create a new config entry if no existing element is provided" do
      described_class.landscapes.keys.should == %w{sap01.example.com sapdev.example.com}
      new_instance = described_class.add('sap02.example.com')

      described_class.landscapes.keys.should == %w{sap01.example.com sapdev.example.com sap02.example.com}
      new_instance.name.should == 'sap02.example.com'
      new_instance.id.should == 3

      new_instance.element.parent.should == config.path('PROBE/LANDSCAPES')
      new_instance.element.name.should == 'LANDSCAPE3'
      new_instance.element[:ID].should == "3"
    end

    it "should connect the new landscape object with an existing config entry if an element is provided" do
      described_class.landscapes.keys.should == %w{sap01.example.com sapdev.example.com}

      existing_element = config.path('PROBE/LANDSCAPES/LANDSCAPE1')
      new_instance = described_class.add('sap02.example.com', existing_element)

      new_instance.name.should == 'sap02.example.com'
      new_instance.id.should == 1
      new_instance.element.should == existing_element

      new_instance.element.parent.should == config.path('PROBE/LANDSCAPES')
      new_instance.element.name.should == 'LANDSCAPE1'
      new_instance.element[:ID].should == "1"
    end
  end

  describe "class method del" do
    it "should to nothing if landscape does not exist" do
      described_class.landscapes.keys.should == %w{sap01.example.com sapdev.example.com}
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1 LANDSCAPE2}
      described_class.del 'sap02.example.com'
      described_class.landscapes.keys.should == %w{sap01.example.com sapdev.example.com}
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1 LANDSCAPE2}
    end

    it "should remove the landscape and the corresponding config section if landscape does exist" do
      described_class.landscapes.keys.should == %w{sap01.example.com sapdev.example.com}
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1 LANDSCAPE2}
      described_class.del 'sap01.example.com'
      described_class.landscapes.keys.should == %w{sapdev.example.com}
      config.path('PROBE/LANDSCAPES').children.map(&:name).should == %w{LANDSCAPE1}
    end

    it "should rename all landscape subsections" do
      described_class.landscapes['sapdev.example.com'].element.name.should == 'LANDSCAPE2'
      described_class.landscapes['sapdev.example.com'].element.should == config.path('PROBE/LANDSCAPES/LANDSCAPE2')
      described_class.del 'sap01.example.com'
      described_class.landscapes['sapdev.example.com'].element.name.should == 'LANDSCAPE1'
      described_class.landscapes['sapdev.example.com'].element.should == config.path('PROBE/LANDSCAPES/LANDSCAPE1')
    end
  end

  describe "class method genid" do
    it "should start with 1 on an empty config" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      described_class.parse
      described_class.genid.should == 1
    end

    it "should return the next free id" do
      described_class.parse
      described_class.genid.should == 3
      described_class.add('new_landscape_01')
      described_class.genid.should == 4
      described_class.add('new_landscape_02')
      described_class.genid.should == 5
      described_class.del('new_landscape_01')
      described_class.genid.should == 3
      described_class.add('new_landscape_03')
      described_class.genid.should == 5
    end
  end

  describe "id" do
    it "should return the id as integer" do
      described_class.landscapes['sap01.example.com'].id == 1
      described_class.landscapes['sapdev.example.com'].id == 2
    end
  end

  {
    :company     => :COMPANY,
    :sid         => :SYSTEM_ID,
    :description => :DESCRIPTION
  }.each_pair do |property, attribute|
    describe "getting #{property}" do
      it "should return nil if attribute #{attribute} does not exist" do
        described_class.parse
        landscape = described_class.add('new_landscape')
        landscape.send(property).should be_nil
      end
      it "should return the value of attribute #{attribute}" do
        described_class.parse
        landscape = described_class.landscapes['sap01.example.com']
        landscape.element.expects(:[]).with(attribute).returns 'foo'
        landscape.send(property).should == 'foo'
      end
    end

    describe "setting #{property}" do
      it "should modify attribute #{attribute}" do
        described_class.parse
        landscape = described_class.landscapes['sap01.example.com']
        landscape.element.expects(:[]=).with(attribute, 'foo')
        landscape.send("#{property}=", 'foo')
      end
    end
  end

  describe "assign_system" do
    it "should add new system to the internal array" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.assigned_systems.should == [1, 3]
      landscape.assign_system 10
      landscape.assigned_systems.should == [1, 3, 10]
    end

    it "should not assign a system twice" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.assigned_systems.should == [1, 3]
      landscape.assign_system 3
      landscape.assigned_systems.should == [1, 3]
    end

    it "should add the system to the appropiate systems section" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.element.child('SYSTEMS').attributes.should == { :INDEX000 => "1", :INDEX001 => "3" }
      landscape.assign_system 10
      landscape.element.child('SYSTEMS').attributes.should == { :INDEX000 => "1", :INDEX001 => "3", :INDEX002 => "10" }
    end

    it "should create the systems section first if necessary" do
      landscape = described_class.landscapes['sapdev.example.com']

      landscape.element.child('SYSTEMS').should be_nil
      landscape.assigned_systems.should be_empty

      landscape.assign_system 33

      landscape.assigned_systems.should == [ 33 ]
      landscape.element.child('SYSTEMS').attributes.should == { :INDEX000 => "33" }
    end
  end

  describe "deassign_system" do
    it "should delete the system from the internal array" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.assigned_systems.should == [1, 3]
      landscape.deassign_system 1
      landscape.assigned_systems.should == [3]
    end

    it "should do nothing if system is not assigned" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.assigned_systems.should == [1, 3]
      landscape.deassign_system 10
      landscape.assigned_systems.should == [1, 3]
    end

    it "should delete the system from the appropiate systems section" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.element.child('SYSTEMS').attributes.should == { :INDEX000 => "1", :INDEX001 => "3" }
      landscape.deassign_system 1
      landscape.element.child('SYSTEMS').attributes.should == { :INDEX000 => "3" }
    end

    it "should completly remove the systems section if last assignment was removed" do
      landscape = described_class.landscapes['sap01.example.com']
      landscape.deassign_system 1
      landscape.deassign_system 3

      landscape.assigned_systems.should be_empty
      landscape.element.child('SYSTEMS').should be_nil
    end
  end
end
