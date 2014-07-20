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
    {
      "ID"                 => "13",
      "JAVA_ENABLED"       => "false",
      "ABAP_ENABLED"       => "true",
      "NAME"               => "PRO_sap01",
      "GROUP"              => "1",
      "ACTIVE"             => "true",
      "USER_PROFILE"       => "1",
      "SYSTEM_ID"          => 'PRO',
      "MAX_INVALID_TIME"   => '180000',
      "MAX_RESPONSE_TIME"  => '30000',
      "HOST"               => 'sap01.example.com',
      "ABAP_CLIENT_NUMBER" => '000',
      "DEFAULT_TEMPLATE"   => '1000001',
      "PARENT_ID"          => '1',
      "TEMPLATES"          => [ 1, 1000000 ],
      "INSTANCE_IPS"       => [ '192.168.0.1' ]
    }
  end

  let :new_system_element do
    {
      "ID"     => '42',
      "ACTIVE" => 'true'
    }
  end

  describe "id" do
    it "should return the id as integer" do
      expect(system.id).to eq(13)
    end
  end

  {
    :sid         => "SYSTEM_ID",
    :host        => "HOST",
    :client      => "ABAP_CLIENT_NUMBER",
    :group       => "GROUP"
  }.each_pair do |property, attribute|
    describe "getting #{property}" do
      it "should return nil if attribute #{attribute} does not exist" do
        expect(new_system.send(property)).to be_nil
      end

      it "should return the value of attribute #{attribute}" do
        system.element.expects(:[]).with(attribute).returns 'foo'
        expect(system.send(property)).to eq('foo')
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
      system.element["ABAP_ENABLED"] = 'true'
      system.element["JAVA_ENABLED"] = 'false'
      expect(system.stack).to eq(:abap)
    end

    it "should return java if abap is disabled and java is enabled" do
      system.element["ABAP_ENABLED"] = 'false'
      system.element["JAVA_ENABLED"] = 'true'
      expect(system.stack).to eq(:java)
    end

    it "should return dual if abap und java are enabled" do
      system.element["ABAP_ENABLED"] = 'true'
      system.element["JAVA_ENABLED"] = 'true'
      expect(system.stack).to eq(:dual)
    end
  end

  describe "setting stack" do
    it "should enable abap and disable java if setting stack to abap" do
      system.element.expects(:[]=).with("ABAP_ENABLED", 'true')
      system.element.expects(:[]=).with("JAVA_ENABLED", 'false')
      system.stack = :abap
    end

    it "should disable abap and enable java if setting stack to java" do
      system.element.expects(:[]=).with("ABAP_ENABLED", 'false')
      system.element.expects(:[]=).with("JAVA_ENABLED", 'true')
      system.stack = :java
    end

    it "should enable abap and java if setting stack to dual" do
      system.element.expects(:[]=).with("ABAP_ENABLED", 'true')
      system.element.expects(:[]=).with("JAVA_ENABLED", 'true')
      system.stack = :dual
    end
  end

  describe "getting ip" do
    it "should return an empty array if INSTANCE_IPS is not present" do
      expect(new_system.ip).to be_empty
    end

    it "should return a single value if one INSTANCE_IP" do
      expect(system.ip).to eq([ '192.168.0.1' ])
    end

    it "should return a list of values if more than on INSTANCE_IP" do
      system.element['INSTANCE_IPS'] = %w{192.168.0.1 192.168.0.2 192.168.0.3}
      expect(system.ip).to eq([ '192.168.0.1', '192.168.0.2', '192.168.0.3' ])
    end
  end

  describe "setting ip" do
    it "should create an INSTANCE_IPS section if necessary" do
      expect(new_system.element).to_not have_key('INSTANCE_IPS')
      new_system.ip = [ '192.168.100.100' ]
      expect(new_system.element).to have_key('INSTANCE_IPS')
      expect(new_system.element['INSTANCE_IPS']).to eq(%w{192.168.100.100})
    end
    
    it "should delete an INSTANCE_IPS section if new value is empty" do
      expect(system.element).to have_key('INSTANCE_IPS')
      system.ip = []
      expect(system.element).to_not have_key('INSTANCE_IPS')
    end


    it "should overwrite any value with the new values" do
      system.ip = ['10.0.0.1', '10.0.0.2']
      expect(system.element['INSTANCE_IPS']).to eq(%w{10.0.0.1 10.0.0.2})
    end
  end

  describe "getting landscape" do
    it "should raise an error if PARENT_ID attribut is missing" do
      system.element.expects(:[]).with("PARENT_ID").returns nil
      expect { system.landscape }.to raise_error Puppet::Error, /System does not have a PARENT_ID attribute/
    end

    it "should raise an error if landscape cannot be found" do
      Puppet::Util::Agentil.landscapes.expects(:[]).with(1).returns nil
      expect { system.landscape }.to raise_error Puppet::Error, /Landscape with id=1 could not be found/
    end

    it "should return the landscape" do
      landscape = mock 'landscape'
      Puppet::Util::Agentil.landscapes.expects(:[]).with(1).returns landscape
      expect(system.landscape).to eq(landscape)
    end
  end

  describe "setting landscape" do
    it "should raise an error if landscape cannot be found" do
      expect { system.landscape = 'NO_SUCH_LANDSCAPE' }.to raise_error Puppet::Error, 'Landscape NO_SUCH_LANDSCAPE not found'
    end

    it "should add the system to the new landscape" do
      system.element.delete("PARENT_ID")
      new_landscape = mock 'new_landscape', :id => 5
      Puppet::Util::Agentil.landscapes.expects(:[]).with(5).returns new_landscape

      new_landscape.expects(:assign_system).with(13) #id of system
      system.landscape = 5
      expect(system.element["PARENT_ID"]).to eq('5')
    end

    it "should remove the system from the old landscape" do
      old_landscape = mock 'old_landscape'
      new_landscape = mock 'new_landscape', :id => 5
      Puppet::Util::Agentil.landscapes.expects(:[]).with(1).returns old_landscape
      Puppet::Util::Agentil.landscapes.expects(:[]).with(5).returns new_landscape
      old_landscape.expects(:deassign_system).with(13)
      new_landscape.expects(:assign_system).with(13)

      system.landscape = 5
      expect(system.element["PARENT_ID"]).to eq('5')
    end
  end

  describe "getting system_template" do
    it "should return nil if no template" do
      expect(new_system.system_template).to be_nil
    end

    it "should raise an error if template cannot be found" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000001).returns nil
      expect { system.system_template }.to raise_error Puppet::Error, /System template with id=1000001 not found/
    end

    it "should return the template" do
      template = mock 'template'
      Puppet::Util::Agentil.templates.expects(:[]).with(1000001).returns template
      expect(system.system_template).to eq(template)
    end
  end

  describe "setting system_template" do
    it "should raise an error if template cannot be found" do
      expect { system.system_template = 'no_such_template' }.to raise_error Puppet::Error, 'Template no_such_template not found'
    end

    it "should update the DEFAULT_TEMPLATE with the appropiate id" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000003).returns mock 'template', :id => 1000003
      system.element.expects(:[]=).with("DEFAULT_TEMPLATE", '1000003')
      system.system_template = 1000003
    end

  end

  describe "getting template" do
    it "should return an empty arrary if template section is absent" do
      expect(new_system.templates).to be_empty
    end

    it "should return the resolved templates" do
      t1 = mock 'template1'
      t2 = mock 'template2'
      Puppet::Util::Agentil.templates.expects(:[]).with(1).returns t1
      Puppet::Util::Agentil.templates.expects(:[]).with(1000000).returns t2
      expect(system.templates).to eq([ t1, t2 ])
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
      expect(system.element['TEMPLATES']).to eq([1000003, 1000004])
    end

    it "should create the template section first if necessary" do
      Puppet::Util::Agentil.templates.expects(:[]).with(1000005).returns mock 'template', :id => 1000005
      Puppet::Util::Agentil.templates.expects(:[]).with(1000004).returns mock 'template', :id => 1000004
      expect(new_system.element).to_not have_key('TEMPLATES')
      new_system.templates = [ 1000005, 1000004 ]
      expect(new_system.element['TEMPLATES']).to eq([1000005, 1000004])
    end

    it "should remove the template section if new value is an empty array" do
      expect(system.element).to have_key('TEMPLATES')
      system.templates = []
      expect(system.element).to_not have_key('TEMPLATES')
    end
  end

  describe "getting user" do
    it "should return nil if user attribute is absent" do
      expect(new_system.user).to be_nil
    end

    it "should raise an error if user cannot be found" do
      Puppet::Util::Agentil.users.expects(:[]).with(1).returns nil
      expect { system.user }.to raise_error Puppet::Error, "User with id=1 not found"
    end

    it "should return the user" do
      user = mock 'user'
      Puppet::Util::Agentil.users.expects(:[]).with(1).returns user
      expect(system.user).to eq(user)
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
      expect(system.element["USER_PROFILE"]).to eq("10")
    end
  end
end
