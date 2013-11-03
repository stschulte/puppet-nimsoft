#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_template'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::AgentilTemplate do

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
    it "should return the templates subtree" do
      root = described_class.root
      root.name.should == 'TEMPLATES'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == config
    end

    it "should create the templates subtree if necessary" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      root = described_class.root
      root.name.should == 'TEMPLATES'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == empty_config
    end
  end

  describe "class method parse" do
    it "should create add a new object for each custom template but skip vendor templates" do
      config.parse
      described_class.expects(:add).with('Vendor template', config.path('PROBE/TEMPLATES/TEMPLATE1')).never
      described_class.expects(:add).with('Custom Template', config.path('PROBE/TEMPLATES/TEMPLATE1000000'))
      described_class.expects(:add).with('System Template for system id 1', config.path('PROBE/TEMPLATES/TEMPLATE1000001'))
      described_class.expects(:add).with('System Template for system id 2', config.path('PROBE/TEMPLATES/TEMPLATE1000002'))
      described_class.expects(:add).with('System Template for system id 3', config.path('PROBE/TEMPLATES/TEMPLATE1000003'))
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

      'Custom Template'
      'System Template for system id 1'
      'System Template for system id 2'
      'System Template for system id 3'

      [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]

  describe "class method templates" do
    it "should return a hash of templates" do
      h = described_class.templates
      h.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]
      h['Custom Template'].should be_a Puppet::Util::AgentilTemplate
      h['System Template for system id 1'].should be_a Puppet::Util::AgentilTemplate
      h['System Template for system id 2'].should be_a Puppet::Util::AgentilTemplate
      h['System Template for system id 3'].should be_a Puppet::Util::AgentilTemplate

    end

    it "should return an empty hash if configuration is empty" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      described_class.templates.keys.should be_empty
    end

    it "should only parse the config once" do
      config.expects(:parse).once
      described_class.templates
      described_class.templates
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
    it "should not add a template if already present" do
      existing_entry = described_class.templates['System Template for system id 2']
      described_class.expects(:new).never
      described_class.add('System Template for system id 2').should == existing_entry
    end

    it "should create a new config entry if no existing element is provided" do
      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]
      new_instance = described_class.add('New Template')

      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3', 'New Template' ]
      new_instance.name.should == 'New Template'
      new_instance.id.should == 1000004

      new_instance.element.parent.should == config.path('PROBE/TEMPLATES')
      new_instance.element.name.should == 'TEMPLATE1000004'
      new_instance.element[:ID].should == "1000004"
      new_instance.element[:NAME].should == 'New Template'
    end

    it "should connect the new template object with an existing config entry if an element is provided" do
      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]

      existing_element = config.path('PROBE/TEMPLATES/TEMPLATE1000001')
      new_instance = described_class.add('New Template', existing_element)

      new_instance.name.should == 'New Template'
      new_instance.id.should == 1000001
      new_instance.element.should == existing_element

      new_instance.element.parent.should == config.path('PROBE/TEMPLATES')
      new_instance.element.name.should == 'TEMPLATE1000001'
      new_instance.element[:ID].should == "1000001"
    end
  end

  describe "class method del" do
    it "should to nothing if template does not exist" do
      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]
      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002 TEMPLATE1000003}

      described_class.del 'no_such_template'

      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]
      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002 TEMPLATE1000003}
    end

    it "should remove the template and the corresponding config section if template does exist" do
      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 1', 'System Template for system id 2', 'System Template for system id 3' ]
      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002 TEMPLATE1000003}

      described_class.del 'System Template for system id 1'

      described_class.templates.keys.should == [ 'Custom Template', 'System Template for system id 2', 'System Template for system id 3' ]
      config.path('PROBE/TEMPLATES').children.map(&:name).should == %w{TEMPLATE1 TEMPLATE1000000 TEMPLATE1000001 TEMPLATE1000002}
    end

    it "should rename all template subsections" do
      described_class.templates['Custom Template'].element.name.should == 'TEMPLATE1000000'
      described_class.templates['Custom Template'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000000')
      described_class.templates['System Template for system id 1'].element.name.should == 'TEMPLATE1000001'
      described_class.templates['System Template for system id 1'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000001')
      described_class.templates['System Template for system id 2'].element.name.should == 'TEMPLATE1000002'
      described_class.templates['System Template for system id 2'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000002')
      described_class.templates['System Template for system id 3'].element.name.should == 'TEMPLATE1000003'
      described_class.templates['System Template for system id 3'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000003')

      described_class.del 'System Template for system id 1'

      described_class.templates['Custom Template'].element.name.should == 'TEMPLATE1000000'
      described_class.templates['Custom Template'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000000')
      described_class.templates['System Template for system id 1'].should be_nil
      described_class.templates['System Template for system id 2'].element.name.should == 'TEMPLATE1000001'
      described_class.templates['System Template for system id 2'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000001')
      described_class.templates['System Template for system id 3'].element.name.should == 'TEMPLATE1000002'
      described_class.templates['System Template for system id 3'].element.should == config.path('PROBE/TEMPLATES/TEMPLATE1000002')
    end
  end

  describe "class method genid" do
    it "should start with 1000000 on an empty config" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      described_class.parse
      described_class.genid.should == 1000000
    end

    it "should return the next free id" do
      described_class.parse
      described_class.genid.should == 1000004
      described_class.add('NEW_TEMPLATE1')
      described_class.genid.should == 1000005
      described_class.add('NEW_TEMPLATE2')
      described_class.genid.should == 1000006
      described_class.del('NEW_TEMPLATE1')
      described_class.genid.should == 1000004
      described_class.add('NEW_TEMPLATE3')
      described_class.genid.should == 1000006
    end
  end

  describe "id" do
    it "should return the id as integer" do
      described_class.templates['Custom Template'].id.should == 1000000
      described_class.templates['System Template for system id 1'].id.should == 1000001
      described_class.templates['System Template for system id 2'].id.should == 1000002
      described_class.templates['System Template for system id 3'].id.should == 1000003
    end
  end

  describe "handling properties" do

    let :new_template do
      described_class.parse
      described_class.add('NEW_TEMPLATE')
    end

    let :template do
      described_class.parse
      described_class.templates['System Template for system id 1']
    end

    describe "getting instances" do
      it "should return an empty array if no customization" do
        template.element.expects(:child).with('CUSTO').returns nil
        template.instances.should be_empty
      end

      it "should return an empty array if no customization for job 177" do
        template.element.child('CUSTO').expects(:child).with('JOB177').returns nil
        template.instances.should be_empty
      end

      it "should return an array of instances found in job177" do
        template.instances.should == [ 'sap01_PRO_00', 'sap01_PRO_01' ]
      end
    end

    describe "setting instances" do
      it "should remove the job177 customizations if empty" do
        template.element.child('CUSTO').children.expects(:delete).with template.element.path('CUSTO/JOB177')
        template.instances = []
      end

      it "should also remove the CUSTO section if job177 was the only customization" do
        template.element.children.expects(:delete).with template.element.child('CUSTO')
        template.instances = []
      end

      it "should modify MANDATORY_INSTANCES, CRITICITIES, AUTO_CLEARS and EXPECTED_INSTANCES for job177" do
        template.instances = [ 'instance_01', 'instance_02', 'instance_03' ]
        template.element.path('CUSTO/JOB177/MANDATORY_INSTANCES').attributes.should == {:INDEX000 => 'true', :INDEX001 => 'true', :INDEX002 => 'true' }
        template.element.path('CUSTO/JOB177/CRITICITIES').attributes.should == {:INDEX000 => '5', :INDEX001 => '5', :INDEX002 => '5' }
        template.element.path('CUSTO/JOB177/AUTO_CLEARS').attributes.should == {:INDEX000 => 'true', :INDEX001 => 'true', :INDEX002 => 'true' }
        template.element.path('CUSTO/JOB177/EXPECTED_INSTANCES').attributes.should == {:INDEX000 => 'instance_01', :INDEX001 => 'instance_02', :INDEX002 => 'instance_03' }
      end
        
      it "should add a CUSTO/JOB177 section first" do
        template.element.child('CUSTO').children.delete template.element.path('CUSTO/JOB177')
        template.element.child('CUSTO').child('JOB177').should be_nil

        template.instances = [ 'instance_01', 'instance_02', 'instance_03' ]

        template.element.path('CUSTO/JOB177')[:ID].should == '177'
        template.element.path('CUSTO/JOB177')[:CUSTOMIZED].should == 'true'
        template.element.path('CUSTO/JOB177/EXPECTED_INSTANCES').attributes.should == {:INDEX000 => 'instance_01', :INDEX001 => 'instance_02', :INDEX002 => 'instance_03' }
      end

      it "should add a CUSTO section first" do
        template.element.children.delete template.element.child('CUSTO')
        template.element.child('CUSTO').should be_nil

        template.instances = [ 'instance_01', 'instance_02', 'instance_03' ]

        template.element.path('CUSTO/JOB177')[:ID].should == '177'
        template.element.path('CUSTO/JOB177')[:CUSTOMIZED].should == 'true'
        template.element.path('CUSTO/JOB177/EXPECTED_INSTANCES').attributes.should == {:INDEX000 => 'instance_01', :INDEX001 => 'instance_02', :INDEX002 => 'instance_03' }
      end
    end

    describe "getting jobs" do
      it "should return an empty array if no jobs" do
        template.element.expects(:child).with('JOBS').returns nil
        template.jobs.should be_empty
      end

      it "should return an array of numeric job ids" do
        template.jobs.should == [ 79, 78, 600, 601 ]
      end
    end

    describe "setting jobs" do
      it "should remove the jobs section if new value is empty" do
        template.element.children.expects(:delete).with template.element.child('JOBS')
        template.jobs = []
      end

      it "should replace current job ids with new ones" do
        template.jobs = [ 10, 5, 23 ]
        template.element.child('JOBS').attributes.should == {:INDEX000 => '10', :INDEX001 => '5', :INDEX002 => '23' }
      end

      it "should create the jobs section first if necessary" do
        template.element.children.delete template.element.child('JOBS')
        template.element.child('JOBS').should be_nil

        template.jobs = [ 10, 5, 23 ]
        template.element.child('JOBS').attributes.should == {:INDEX000 => '10', :INDEX001 => '5', :INDEX002 => '23' }
      end
    end

    describe "getting monitors" do
      it "should return an empty array if no monitors" do
        template.element.expects(:child).with('MONITORS').returns nil
        template.monitors.should be_empty
      end

      it "should return an array of numeric monitor ids" do
        template.monitors.should == [ 1, 30 ]
      end
    end

    describe "setting monitors" do
      it "should remove the monitors section if new value is empty" do
        template.element.children.expects(:delete).with template.element.child('MONITORS')
        template.monitors = []
      end

      it "should replace current monitor ids with new ones" do
        template.monitors = [ 399 ]
        template.element.child('MONITORS').attributes.should == {:INDEX000 => '399' }
      end

      it "should create the monitors section first if necessary" do
        template.element.children.delete template.element.child('MONITORS')
        template.element.child('MONITORS').should be_nil

        template.monitors = [ 233, 41, 22, 55 ]
        template.element.child('MONITORS').attributes.should == {:INDEX000 => '233', :INDEX001 => '41', :INDEX002 => '22', :INDEX003 => '55' }
      end
    end

    describe "getting system" do
      it "should return :true if template is a system template" do
        template.element.expects(:[]).with(:SYSTEM_TEMPLATE).returns 'true'
        template.system.should == :true
      end

      it "should return :false if template is not a system template" do
        template.element.expects(:[]).with(:SYSTEM_TEMPLATE).returns 'false'
        template.system.should == :false
      end
    end

    describe "setting system" do
      it "should set SYSTEM_TEMPLATE to true if new value is :true" do
        template.element.expects(:[]=).with(:SYSTEM_TEMPLATE, 'true')
        template.system = :true
      end

      it "should set SYSTEM_TEMPLATE to false if new value is :false" do
        template.element.expects(:[]=).with(:SYSTEM_TEMPLATE, 'false')
        template.system = :false
      end
    end
     
  end
end
