#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::AgentilSystem do

  before :each do
    Puppet::Util::Agentil.initvars
  end

  let :system do
    described_class.new(13, system_element)
  end

  let :new_system do
    described_class.new(42, new_system_element)
  end

  let :system_element do
    element = Puppet::Util::NimsoftSection.new('SYSTEM13')
    element[:SYSTEM_ID] = 'PRO'
    element[:MAX_INVALID_TIME] = '180000'
    element[:MAX_RESPONSE_TIME] = '30000'
    element[:USER_PROFILE] = '1'
    element[:HOST] = 'sap01.example.com'
    element[:ABAP_CLIENT_NUMBER] = '000'
    element[:DEFAULT_TEMPLATE] = '1000001'
    element[:ID] = '13'
    element[:JAVA_ENABLED] = 'false'
    element[:ABAP_ENABLED] = 'true'
    element[:NAME] = 'PRO_sap01'
    element[:GROUP] = '1'
    element[:ACTIVE] = 'true'
    element[:PARENT_ID] = '1'
    element.path('TEMPLATES')[:INDEX000] = '1'
    element.path('TEMPLATES')[:INDEX001] = '1000000'
    element.path('INSTANCE_IPS')[:INDEX000] = '192.168.0.1'
    element
  end

  let :new_system_element do
    element = Puppet::Util::NimsoftSection.new('SYSTEM42')
    element[:ID] = '42'
    element[:ACTIVE] = 'true'
    element
  end

  describe "id" do
    it "should return the id as integer" do
      system.id.should == 13
    end
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
      system.element[:ABAP_ENABLED] = 'true'
      system.element[:JAVA_ENABLED] = 'false'
      system.stack.should == :abap
    end

    it "should return java if abap is disabled and java is enabled" do
      system.element[:ABAP_ENABLED] = 'false'
      system.element[:JAVA_ENABLED] = 'true'
      system.stack.should == :java
    end

    it "should return dual if abap und java are enabled" do
      system.element[:ABAP_ENABLED] = 'true'
      system.element[:JAVA_ENABLED] = 'true'
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
      new_system.ip.should be_empty
    end

    it "should return a single value if one INSTANCE_IP" do
      system.ip.should == [ '192.168.0.1' ]
    end

    it "should return a list of values if more than on INSTANCE_IP" do
      system.element.path('INSTANCE_IPS')[:INDEX000] = '192.168.0.1'
      system.element.path('INSTANCE_IPS')[:INDEX001] = '192.168.0.2'
      system.element.path('INSTANCE_IPS')[:INDEX002] = '192.168.0.3'
      system.ip.should == [ '192.168.0.1', '192.168.0.2', '192.168.0.3' ]
    end
  end

  describe "setting ip" do
    it "should create an INSTANCE_IPS section if necessary" do
      new_system.element.child('INSTANCE_IPS').should be_nil
      new_system.ip = [ '192.168.100.100' ]
      new_system.element.child('INSTANCE_IPS').should_not be_nil
      new_system.element.child('INSTANCE_IPS').attributes.should == { :INDEX000 => '192.168.100.100' }
    end
    
    it "should delete an INSTANCE_IPS section if new value is empty" do
      system.element.child('INSTANCE_IPS').should_not be_nil
      system.ip = []
      system.element.child('INSTANCE_IPS').should be_nil
    end


    it "should overwrite any value with the new values" do
      system.ip = ['10.0.0.1', '10.0.0.2']
      system.element.child('INSTANCE_IPS').attributes.should == { :INDEX000 => '10.0.0.1', :INDEX001 => '10.0.0.2' }
    end
  end

  describe "getting landscape" do
    it "should raise an error if PARENT_ID attribut is missing" do
      system.element.expects(:[]).with(:PARENT_ID).returns nil
      expect { system.landscape }.to raise_error Puppet::Error, /System does not have a PARENT_ID attribute/
    end

    it "should raise an error if landscape cannot be found" do
      Puppet::Util::Agentil.landscapes.expects(:[]).with(1).returns nil
      expect { system.landscape }.to raise_error Puppet::Error, /Landscape with id=1 could not be found/
    end

    it "should return the landscape" do
      landscape = mock 'landscape'
      Puppet::Util::Agentil.landscapes.expects(:[]).with(1).returns landscape
      system.landscape.should == landscape
    end
  end

  describe "setting landscape" do
    it "should raise an error if landscape cannot be found" do
      expect { system.landscape = 'NO_SUCH_LANDSCAPE' }.to raise_error Puppet::Error, 'Landscape NO_SUCH_LANDSCAPE not found'
    end

    it "should add the system to the new landscape" do
      system.element.attributes.delete(:PARENT_ID)
      new_landscape = mock 'new_landscape', :id => 5
      Puppet::Util::Agentil.landscapes.expects(:[]).with(5).returns new_landscape
      new_landscape.expects(:assign_system).with(13)

      system.landscape = 5
      system.element[:PARENT_ID].should == '5'
    end

    it "should remove the system from the old landscape" do
      old_landscape = mock 'old_landscape'
      new_landscape = mock 'new_landscape', :id => 5
      Puppet::Util::Agentil.landscapes.expects(:[]).with(1).returns old_landscape
      Puppet::Util::Agentil.landscapes.expects(:[]).with(5).returns new_landscape
      old_landscape.expects(:deassign_system).with(13)
      new_landscape.expects(:assign_system).with(13)

      system.landscape = 5
      system.element[:PARENT_ID].should == '5'
    end
  end

  describe "getting system_template" do
    it "should return nil if no template" do
      new_system.system_template.should be_nil
    end

    it "should raise an error if template cannot be found" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000001).returns nil
      expect { system.system_template }.to raise_error Puppet::Error, /System template with id=1000001 not found/
    end

    it "should return the template" do
      template = mock 'template'
      Puppet::Util::Agentil.templates.expects(:[]).with(1000001).returns template
      system.system_template.should == template
    end
  end

  describe "setting system_template" do
    it "should raise an error if template cannot be found" do
      expect { system.system_template = 'no_such_template' }.to raise_error Puppet::Error, 'Template no_such_template not found'
    end

    it "should update the DEFAULT_TEMPLATE with the appropiate id" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000003).returns mock 'template', :id => 1000003
      system.element.expects(:[]=).with(:DEFAULT_TEMPLATE, '1000003')
      system.system_template = 1000003
    end

  end

  describe "getting template" do
    it "should return an empty arrary if template section is absent" do
      new_system.templates.should == []
    end

    it "should return the resolved templates" do
      t1 = mock 'template1'
      t2 = mock 'template2'
      Puppet::Util::Agentil.templates.expects(:[]).with(1).returns t1
      Puppet::Util::Agentil.templates.expects(:[]).with(1000000).returns t2
      system.templates.should =~ [ t1, t2 ]
    end

    it "should raise an error if template cannot be found" do
      t1 = mock 'template1'
      Puppet::Util::Agentil.templates.expects(:[]).with(1).returns t1
      Puppet::Util::Agentil.templates.expects(:[]).with(1000000).returns nil
      expect { system.templates }.to raise_error Puppet::Error, 'Template with id=1000000 could not be found'
    end
  end

  describe "setting template" do
    it "should raise an error if at least one template cannot be found" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000003).returns mock 'template', :id => 1000003
      Puppet::Util::Agentil.templates.expects(:[]).with(1000004).returns nil
      expect { system.templates = [ 1000003, 1000004 ] }.to raise_error Puppet::Error, 'Template 1000004 not found'
    end

    it "should update the template section with the appropiate ids" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000003).returns mock 'template', :id => 1000003
      Puppet::Util::Agentil.templates.expects(:[]).with(1000004).returns mock 'template', :id => 1000004
      system.templates = [ 1000003, 1000004 ]
      system.element.child('TEMPLATES').attributes.should == { :INDEX000 => '1000003', :INDEX001 => '1000004' }
    end

    it "should create the template section first if necessary" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000005).returns mock 'template', :id => 1000005
      Puppet::Util::Agentil.templates.expects(:[]).with(1000004).returns mock 'template', :id => 1000004
      new_system.element.child('TEMPLATES').should be_nil
      new_system.templates = [ 1000005, 1000004 ]
      new_system.element.child('TEMPLATES').attributes.should == { :INDEX000 => '1000005', :INDEX001 => '1000004' }
    end

    it "should remove the template section if new value is an empty array" do
      system.element.child('TEMPLATES').should_not be_nil
      system.templates = []
      system.element.child('TEMPLATES').should be_nil
    end
  end

  describe "getting user" do
    it "should return nil if user attribute is absent" do
      new_system.user.should be_nil
    end

    it "should raise an error if user cannot be found" do
      Puppet::Util::Agentil.users.expects(:[]).with(1).returns nil
      expect { system.user }.to raise_error Puppet::Error, "User with id=1 not found"
    end

    it "should return the user" do
      user = mock 'user'
      Puppet::Util::Agentil.users.expects(:[]).with(1).returns user
      system.user.should == user
    end
  end

  describe "setting user" do
    it "should raise an error if user cannot be found" do
      Puppet::Util::Agentil.users.expects(:[]).with(10).returns nil
      expect { system.user = 10 }.to raise_error Puppet::Error, 'Unable to find user 10'
    end

    it "should update the section with the appropiate user id" do
      Puppet::Util::Agentil.users.expects(:[]).with(10).returns mock 'user', :id => 10
      system.user = 10
      system.element[:USER_PROFILE].should == "10"
    end
  end
end
