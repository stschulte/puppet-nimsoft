#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_system'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::AgentilSystem do

  before :each do
    described_class.initvars
    Puppet::Util::AgentilLandscape.initvars
    Puppet::Util::AgentilUser.initvars
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
    it "should return the systems subtree" do
      root = described_class.root
      root.name.should == 'SYSTEMS'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == config
    end

    it "should create the systems subtree if necessary" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      root = described_class.root
      root.name.should == 'SYSTEMS'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == empty_config
    end
  end

  describe "class method parse" do
    it "should create add a new object for each system" do
      config.parse
      described_class.expects(:add).with('PRO_sap01', config.path('PROBE/SYSTEMS/SYSTEM1'))
      described_class.expects(:add).with('PRO_sap01-2', config.path('PROBE/SYSTEMS/SYSTEM2'))
      described_class.expects(:add).with('DEV_sapdev', config.path('PROBE/SYSTEMS/SYSTEM3'))
      described_class.expects(:add).with('DEAD', config.path('PROBE/SYSTEMS/SYSTEM4'))
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

  describe "class method systems" do
    it "should return a hash of systems" do
      h = described_class.systems
      h.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD}
      h['PRO_sap01'].should be_a Puppet::Util::AgentilSystem
      h['PRO_sap01-2'].should be_a Puppet::Util::AgentilSystem
      h['DEV_sapdev'].should be_a Puppet::Util::AgentilSystem
      h['DEAD'].should be_a Puppet::Util::AgentilSystem
    end

    it "should return an empty hash if configuration is empty" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      described_class.systems.keys.should be_empty
    end

    it "should only parse the config once" do
      config.expects(:parse).once
      described_class.systems
      described_class.systems
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
    it "should not add a system if already present" do
      existing_entry = described_class.systems['PRO_sap01-2']
      described_class.expects(:new).never
      described_class.add('PRO_sap01-2').should == existing_entry
    end

    it "should create a new config entry if no existing element is provided" do
      described_class.systems.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD}
      new_instance = described_class.add('QAS_sapqas')

      described_class.systems.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD QAS_sapqas}
      new_instance.name.should == 'QAS_sapqas'
      new_instance.id.should == 5

      new_instance.element.parent.should == config.path('PROBE/SYSTEMS')
      new_instance.element.name.should == 'SYSTEM5'
      new_instance.element[:ID].should == "5"
    end

    it "should connect the new system object with an existing config entry if an element is provided" do
      described_class.systems.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD}

      existing_element = config.path('PROBE/SYSTEMS/SYSTEM1')
      new_instance = described_class.add('QAS_sapqas', existing_element)

      new_instance.name.should == 'QAS_sapqas'
      new_instance.id.should == 1
      new_instance.element.should == existing_element

      new_instance.element.parent.should == config.path('PROBE/SYSTEMS')
      new_instance.element.name.should == 'SYSTEM1'
      new_instance.element[:ID].should == "1"
    end
  end

  describe "class method del" do
    it "should to nothing if system does not exist" do
      described_class.systems.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD}
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2 SYSTEM3 SYSTEM4}
      described_class.del 'QAS_sapqas'
      described_class.systems.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD}
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2 SYSTEM3 SYSTEM4}
    end

    it "should remove the system and the corresponding config section if system does exist" do
      described_class.systems.keys.should == %w{PRO_sap01 PRO_sap01-2 DEV_sapdev DEAD}
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2 SYSTEM3 SYSTEM4}
      described_class.del 'PRO_sap01-2'
      described_class.systems.keys.should == %w{PRO_sap01 DEV_sapdev DEAD}
      config.path('PROBE/SYSTEMS').children.map(&:name).should == %w{SYSTEM1 SYSTEM2 SYSTEM3}
    end

    it "should rename all system subsections" do
      described_class.systems['PRO_sap01'].element.name.should == 'SYSTEM1'
      described_class.systems['PRO_sap01'].element.should == config.path('PROBE/SYSTEMS/SYSTEM1')
      described_class.systems['DEV_sapdev'].element.name.should == 'SYSTEM3'
      described_class.systems['DEV_sapdev'].element.should == config.path('PROBE/SYSTEMS/SYSTEM3')
      described_class.systems['DEAD'].element.name.should == 'SYSTEM4'
      described_class.systems['DEAD'].element.should == config.path('PROBE/SYSTEMS/SYSTEM4')

      described_class.del 'PRO_sap01-2'

      described_class.systems['PRO_sap01'].element.name.should == 'SYSTEM1'
      described_class.systems['PRO_sap01'].element.should == config.path('PROBE/SYSTEMS/SYSTEM1')
      described_class.systems['DEV_sapdev'].element.name.should == 'SYSTEM2'
      described_class.systems['DEV_sapdev'].element.should == config.path('PROBE/SYSTEMS/SYSTEM2')
      described_class.systems['DEAD'].element.name.should == 'SYSTEM3'
      described_class.systems['DEAD'].element.should == config.path('PROBE/SYSTEMS/SYSTEM3')
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
      described_class.genid.should == 5
      described_class.add('new_system_01')
      described_class.genid.should == 6
      described_class.add('new_system_02')
      described_class.genid.should == 7
      described_class.del('new_system_01')
      described_class.genid.should == 5
      described_class.add('new_system_03')
      described_class.genid.should == 7
    end
  end

  describe "id" do
    it "should return the id as integer" do
      described_class.systems['PRO_sap01'].id.should == 1
      described_class.systems['PRO_sap01-2'].id.should == 2
      described_class.systems['DEV_sapdev'].id.should == 3
    end
  end

  describe "handling properties" do

    let :new_system do
      described_class.parse
      described_class.add('new_system')
    end

    let :system do
      described_class.parse
      described_class.systems['DEV_sapdev']
    end

    {
      :sid         => :SYSTEM_ID,
      :host        => :HOST,
      :client      => :ABAP_CLIENT_NUMBER,
      :group       => :GROUP
    }.each_pair do |property, attribute|
      describe "getting #{property}" do
        it "should return nil if attribute #{attribute} does not exist" do
          new_system.send(property).should be_nil
        end
        it "should return the value of attribute #{attribute}" do
          system.element.expects(:[]).with(attribute).returns 'foo'
          system.send(property).should == 'foo'
        end
      end
  
      describe "setting #{property}" do
        it "should modify attribute #{attribute}" do
          system.element.expects(:[]=).with(attribute, 'foo')
          system.send("#{property}=", 'foo')
        end
      end
    end

    describe "getting stack" do
      it "should return abap if abap is enabled and java is disabled" do
        system.element.stubs(:[]).with(:ABAP_ENABLED).returns 'true'
        system.element.stubs(:[]).with(:JAVA_ENABLED).returns 'false'
        system.stack.should == :abap
      end

      it "should return java if abap is disabled and java is enabled" do
        system.element.stubs(:[]).with(:ABAP_ENABLED).returns 'false'
        system.element.stubs(:[]).with(:JAVA_ENABLED).returns 'true'
        system.stack.should == :java
      end

      it "should return dual if abap und java are enabled" do
        system.element.stubs(:[]).with(:ABAP_ENABLED).returns 'true'
        system.element.stubs(:[]).with(:JAVA_ENABLED).returns 'true'
        system.stack.should == :dual
      end
    end

    describe "setting stack" do
      it "should enable abap and disable java if setting stack to abap" do
        system.element.expects(:[]=).with(:ABAP_ENABLED, 'true')
        system.element.expects(:[]=).with(:JAVA_ENABLED, 'false')
        system.stack = :abap
      end

      it "should disable abap and enable java if setting stack to java" do
        system.element.expects(:[]=).with(:ABAP_ENABLED, 'false')
        system.element.expects(:[]=).with(:JAVA_ENABLED, 'true')
        system.stack = :java
      end

      it "should enable abap and java if setting stack to dual" do
        system.element.expects(:[]=).with(:ABAP_ENABLED, 'true')
        system.element.expects(:[]=).with(:JAVA_ENABLED, 'true')
        system.stack = :dual
      end
    end

    describe "getting ip" do
      it "should return an empty array if INSTANCE_IPS is not present" do
        described_class.systems['DEV_sapdev'].ip.should be_empty
      end

      it "should return a single value if one INSTANCE_IP" do
        described_class.systems['PRO_sap01-2'].ip.should == [ '192.168.0.3' ]
      end

      it "should return a list of values if more than on INSTANCE_IP" do
        described_class.systems['PRO_sap01'].ip.should == [ '192.168.0.1', '192.168.0.2' ]
      end
    end

    describe "setting ip" do
      it "should create an INSTANCE_IPS section if necessary" do
        described_class.systems['DEV_sapdev'].element.child('INSTANCE_IPS').should be_nil
        described_class.systems['DEV_sapdev'].ip = [ '192.168.100.100' ]
        described_class.systems['DEV_sapdev'].element.child('INSTANCE_IPS').should_not be_nil
        described_class.systems['DEV_sapdev'].element.child('INSTANCE_IPS').attributes.should == { :INDEX000 => '192.168.100.100' }
      end
      
      it "should delete an INSTANCE_IPS section if new value is empty" do
        described_class.systems['PRO_sap01'].element.child('INSTANCE_IPS').should_not be_nil
        described_class.systems['PRO_sap01'].ip = []
        described_class.systems['PRO_sap01'].element.child('INSTANCE_IPS').should be_nil
      end


      it "should overwrite any value with the new values" do
        described_class.systems['PRO_sap01-2'].ip = ['10.0.0.1', '10.0.0.2']
        described_class.systems['PRO_sap01-2'].element.child('INSTANCE_IPS').attributes.should == { :INDEX000 => '10.0.0.1', :INDEX001 => '10.0.0.2' }
      end
    end

    describe "getting landscape" do
      it "should return nil if landscape cannot be found" do
        described_class.systems['DEAD'].landscape.should be_nil
      end

      it "should return the name of the landscape" do
        described_class.systems['PRO_sap01-2'].landscape == 'PRO'
      end
    end

    describe "setting landscape" do
      it "should raise an error if landscape cannot be found" do
        system = described_class.systems['DEAD']
        expect { system.landscape = 'NO_SUCH_LANDSCAPE' }.to raise_error Puppet::Error, 'Landscape NO_SUCH_LANDSCAPE not found'
      end

      it "should add the system to the new landscape" do
        system = described_class.systems['DEAD']
        config.path('PROBE/LANDSCAPES/LANDSCAPE1/SYSTEMS').attributes.should == {:INDEX000 => '1', :INDEX001 => '2'}
        system.landscape = 'PRO'
        system.element[:PARENT_ID].should == "1"
        config.path('PROBE/LANDSCAPES/LANDSCAPE1/SYSTEMS').attributes.should == {:INDEX000 => '1', :INDEX001 => '2', :INDEX002 => '4'}
      end

      it "should remove the system from the old landscape" do
        system = described_class.systems['PRO_sap01']
        system.element[:PARENT_ID].should == "1"
        config.path('PROBE/LANDSCAPES/LANDSCAPE1/SYSTEMS').attributes.should == {:INDEX000 => '1', :INDEX001 => '2'}
        config.path('PROBE/LANDSCAPES/LANDSCAPE2/SYSTEMS').attributes.should be_empty

        system.landscape = 'DEV'

        system.element[:PARENT_ID].should == "2"
        config.path('PROBE/LANDSCAPES/LANDSCAPE1/SYSTEMS').attributes.should == {:INDEX000 => '2'}
        config.path('PROBE/LANDSCAPES/LANDSCAPE2/SYSTEMS').attributes.should == {:INDEX000 => '1'}
      end
    end

    describe "getting default" do
      it "should return nil if no template" do
        system = described_class.systems['DEAD']
        system.element.expects(:[]).with(:DEFAULT_TEMPLATE).returns nil
        system.default.should be_nil
      end

      it "should return nil if template cannot be found" do
        system = described_class.systems['DEAD']
        system.default.should be_nil
      end

      it "should return the template name" do
        system = described_class.systems['DEV_sapdev']
        system.default.should == 'System Template for system id 3'
      end
    end

    describe "setting default" do
      it "should raise an error if template cannot be found" do
        system = described_class.systems['DEAD']
        expect { system.default = 'no_such_template' }.to raise_error Puppet::Error, 'Template no_such_template not found'
      end

      it "should update the DEFAULT_TEMPLATE with the appropiate id" do
        system = described_class.systems['DEAD']
        system.element.expects(:[]=).with(:DEFAULT_TEMPLATE, '1000003')
        system.default = 'System Template for system id 3'
      end

    end

    describe "getting template" do
      it "should return an empty arrary if template section is absent" do
        system = described_class.systems['DEV_sapdev']
        system.templates.should == []
      end

      it "should return an empty array if no template" do
        system = described_class.systems['DEAD']
        system.element.child('TEMPLATES').clear_attr
        system.templates.should == []
      end

      it "should only return resolveable templates" do
        system = described_class.systems['DEAD']
        system.templates.should == [ 'Custom Template', 'Another custom template' ]
      end
    end

    describe "setting template" do
      it "should raise an error if at least one template cannot be found" do
        system = described_class.systems['DEAD']
        expect { system.templates = [ 'Another custom template', 'No Such Template', 'Third custom template' ] }.to raise_error Puppet::Error, 'Template No Such Template cannot be found'
      end

      it "should update the template section with the appropiate ids" do
        system = described_class.systems['DEAD']
        system.templates = [ 'Third custom template', 'Another custom template' ]
        system.element.child('TEMPLATES').attributes.should == { :INDEX000 => '1000005', :INDEX001 => '1000004' }
      end

      it "should create the template section first if necessary" do
        system = described_class.systems['DEV_sapdev']
        system.element.child('TEMPLATES').should be_nil
        system.templates = [ 'Third custom template', 'Another custom template' ]
        system.element.child('TEMPLATES').attributes.should == { :INDEX000 => '1000005', :INDEX001 => '1000004' }
      end

      it "should remove the template section if new value is an empty array" do
        system = described_class.systems['DEAD']

        system.element.child('TEMPLATES').should_not be_nil
        system.templates = []
        system.element.child('TEMPLATES').should be_nil
      end
    end

    describe "getting user" do
      it "should return nil if user cannot be found" do
        described_class.systems['DEAD'].user.should be_nil
      end

      it "should return the name of the user" do
        described_class.systems['PRO_sap01-2'].user == 'SAP_PROBE'
      end
    end

    describe "setting user" do
      it "should raise an error if user cannot be found" do
        system = described_class.systems['DEAD']
        expect { system.user = 'NO_SUCH_USER' }.to raise_error Puppet::Error, 'User NO_SUCH_USER not found'
      end

      it "should update the section with the appropiate user id" do
        system = described_class.systems['PRO_sap01']
        system.element[:USER_PROFILE].should == "1"

        system.user = 'DEV_PROBE'
        system.element[:USER_PROFILE].should == "2"
      end
    end

  end
end
