#! /usr/bin/env ruby

require 'spec_helper'

require 'puppet/util/agentil'
require 'puppet/util/nimsoft_section'

describe Puppet::Type.type(:agentil_system).provider(:agentil) do

  let :provider do
    described_class.new(
      :name           => 'ABC_sap01',
      :ensure         => :present,
      :agentil_system => system
    )
  end

  let :system do
    Puppet::Util::AgentilSystem.new(5, system_element)
  end

  let :system_element do
    {
      'ID'           => '5',
      'NAME'         => 'ABC_sap01',
      'SYSTEM_ID'    => 'ABC',
      'HOST'         => 'sap01.example.com',
      'JAVA_ENABLED' => 'false',
      'ABAP_ENABLED' => 'true'
    }
  end

  let :users do
    {
      1 => mock {
        stubs(:id).returns 1
        stubs(:name).returns 'SAP_DEV'
      },
      2 => mock {
        stubs(:id).returns 2
        stubs(:name).returns 'SAP_QAS'
      },
      3 => mock {
        stubs(:id).returns 3
        stubs(:name).returns 'SAP_PRO'
      }
    }
  end

  let :templates do
    {
      1 => mock {
        stubs(:id).returns 1
        stubs(:name).returns 'Vendor template'
        stubs(:system_template?).returns false
      },
      1000001 => mock {
        stubs(:id).returns 1000001
        stubs(:name).returns 'Systemtemplate for PRO'
        stubs(:system_template?).returns true
      },
      1000002 => mock {
        stubs(:id).returns 1000002
        stubs(:name).returns 'Systemtemplate for QAS'
        stubs(:system_template?).returns true
      }
    }
  end

  let :resource do
    Puppet::Type.type(:agentil_system).new(
      :name             => 'ABC_sap01',
      :ensure           => :present,
      :sid              => 'ABC',
      :landscape        => 'ABC',
      :host             => 'sap01.example.com',
      :ip               => [ '192.168.0.1', '192.168.0.2' ],
      :stack            => 'abap',
      :client           => '000',
      :ccms_mode        => 'aggregated',
      :user             => 'SAP_PRO',
      :group            => 'LOGON_GROUP_01',
      :system_template  => 'Systemtemplate for PRO',
      :templates        => [ 'Vendor template' ]
    )
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        instance = described_class.new(:name => 'foo', :ensure => :present)
        expect(instance).to be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'foo')
        expect(instance).to_not be_exists
      end
    end

    describe "create" do
      it "should add a new system" do
        resource.provider = provider
        Puppet::Util::Agentil.expects(:users).returns users
        Puppet::Util::Agentil.expects(:templates).twice.returns templates
        Puppet::Util::Agentil.expects(:add_system).returns system

        system.expects(:name=).with 'ABC_sap01'
        system.expects(:sid=).with 'ABC'
        system.expects(:host=).with 'sap01.example.com'
        system.expects(:ip=).with ['192.168.0.1', '192.168.0.2']
        system.expects(:stack=).with :abap
        system.expects(:user=).with users[3]
        system.expects(:ccms_mode=).with :aggregated
        system.expects(:client=).with '000'
        system.expects(:group=).with 'LOGON_GROUP_01'
        system.expects(:landscape=).with 'ABC'
        system.expects(:system_template=).with templates[1000001]
        system.expects(:templates=).with [ templates[1] ]

        provider.create
      end

      it "should raise an error if the user cannot be found" do
        resource.provider = provider
        Puppet::Util::Agentil.stubs(:users).returns({})
        Puppet::Util::Agentil.stubs(:templates).returns templates
        Puppet::Util::Agentil.stubs(:add_system).never
        expect { provider.create }.to raise_error Puppet::Error, 'User "SAP_PRO" not found'
      end

      it "should raise an error if the system template cannot be found" do
        resource.provider = provider
        Puppet::Util::Agentil.stubs(:users).returns users
        Puppet::Util::Agentil.stubs(:templates).returns(1 => templates[1])
        Puppet::Util::Agentil.stubs(:add_system).never
        expect { provider.create }.to raise_error Puppet::Error, 'Template "Systemtemplate for PRO" not found'
      end

      it "should raise an error if a template cannot be found" do
        resource.provider = provider
        Puppet::Util::Agentil.stubs(:users).returns users
        Puppet::Util::Agentil.stubs(:templates).returns(1000001 => templates[1000001])
        Puppet::Util::Agentil.stubs(:add_system).never
        expect { provider.create }.to raise_error Puppet::Error, 'Template "Vendor template" not found'
      end

      it "should raise an error if mandatory properties are missing" do
        resource = Puppet::Type.type(:agentil_system).new(
          :name        => 'ABC_sap01',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error Puppet::Error, 'Cannot create system with no sid'
      end
    end
    
    describe "destroy" do
      it "should delete a system" do
        resource.provider = provider
        Puppet::Util::Agentil.expects(:del_system).with 5
        provider.destroy
      end

      it "should not complain about missing fields" do
        resource = Puppet::Type.type(:agentil_system).new(
          :name        => 'ABC_sap01',
          :ensure      => :absent
        )
        resource.provider = provider
        Puppet::Util::Agentil.expects(:del_system).with 5
        provider.destroy
      end
    end
  end

  describe "when managing sid" do
    it "should delegate the getter method to the AgentilLandscape class" do
      system.expects(:sid).returns 'PRO'
      expect(provider.sid).to eq('PRO')
    end

    it "should delegate the setter method to the AgentilLandscape class" do
      system.expects(:sid=).with('QAS')
      provider.sid = 'QAS'
    end
  end

  describe "when managing host" do
    it "should delegate the getter method to the AgentilLandscape class" do
      system.expects(:host).returns 'sappro01.example.com'
      expect(provider.host).to eq('sappro01.example.com')
    end

    it "should delegate the setter method to the AgentilLandscape class" do
      system.expects(:host=).with('sapdev01.example.com')
      provider.host = 'sapdev01.example.com'
    end
  end

  describe "when managing ip" do
    it "should delegate the getter method to the AgentilLandscape class" do
      system.expects(:ip).returns ['10.0.0.1']
      expect(provider.ip).to eq([ '10.0.0.1' ])
    end

    it "should delegate the setter method to the AgentilLandscape class" do
      system.expects(:ip=).with([ '10.0.0.2', '10.0.0.3'] )
      provider.ip = [ '10.0.0.2', '10.0.0.3' ]
    end
  end

  describe "when managing stack" do
    it "should delegate the getter method to the AgentilLandscape class" do
      system.expects(:stack).returns :abap
      expect(provider.stack).to eq(:abap)
    end

    it "should delegate the setter method to the AgentilLandscape class" do
      system.expects(:stack=).with(:java)
      provider.stack = :java
    end
  end

  describe "when managing client" do
    it "should delegate the getter method to the AgentilLandscape class" do
      system.expects(:client).returns '066'
      expect(provider.client).to eq('066')
    end

    it "should delegate the setter method to the AgentilLandscape class" do
      system.expects(:client=).with('000')
      provider.client = '000'
    end
  end

  describe "when managing group" do
    it "should delegate the getter method to the AgentilLandscape class" do
      system.expects(:group).returns 'SPACE'
      expect(provider.group).to eq('SPACE')
    end

    it "should delegate the setter method to the AgentilLandscape class" do
      system.expects(:group=).with('SPACE')
      provider.group = 'SPACE'
    end
  end

  describe "when managing user" do
    it "should return nil when no user assigned" do
      system.expects(:user).returns nil
      expect(provider.user).to be_nil
    end

    it "should return the user's name" do
      system.expects(:user).returns users[3]
      expect(provider.user).to eq('SAP_PRO')
    end

    it "should look up the user name when assigning a new user" do
      Puppet::Util::Agentil.expects(:users).returns users
      system.expects(:user=).with users[2]
      provider.user = 'SAP_QAS'
    end

    it "should raise an error when the user cannot be found" do
      Puppet::Util::Agentil.expects(:users).returns users
      expect { provider.user = 'NO_SUCH_USER' }.to raise_error Puppet::Error, 'User "NO_SUCH_USER" not found'
    end
  end

  describe "when managing landscape"
  describe "when managing system_template"
  describe "when managing templates"

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::Agentil.expects(:sync)
      provider.flush
    end
  end
end
