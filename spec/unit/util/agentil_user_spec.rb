#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil_user'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::AgentilUser do

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
    it "should return the systems subtree" do
      root = described_class.root
      root.name.should == 'USERS'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == config
    end

    it "should create the systems subtree if necessary" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      root = described_class.root
      root.name.should == 'USERS'
      root.parent.name.should == 'PROBE'
      root.parent.parent.should == empty_config
    end
  end

  describe "class method parse" do
    it "should create add a new object for each system" do
      config.parse
      described_class.expects(:add).with('SAP_PROBE', config.path('PROBE/USERS/USER1'))
      described_class.expects(:add).with('SAP_DEV_PROBE', config.path('PROBE/USERS/USER2'))
      described_class.expects(:add).with('DDIC', config.path('PROBE/USERS/USER3'))
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

  describe "class method users" do
    it "should return a hash of users" do
      h = described_class.users
      h.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC}
      h['SAP_PROBE'].should be_a Puppet::Util::AgentilUser
      h['SAP_DEV_PROBE'].should be_a Puppet::Util::AgentilUser
      h['DDIC'].should be_a Puppet::Util::AgentilUser
    end

    it "should return an empty hash if configuration is empty" do
      Puppet::Util::NimsoftConfig.expects(:add).with('/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg').returns empty_config
      described_class.users.keys.should be_empty
    end

    it "should only parse the config once" do
      config.expects(:parse).once
      described_class.users
      described_class.users
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
    it "should not add a user if already present" do
      existing_entry = described_class.users['SAP_DEV_PROBE']
      described_class.expects(:new).never
      described_class.add('SAP_DEV_PROBE').should == existing_entry
    end

    it "should create a new config entry if no existing element is provided" do
      described_class.users.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC}
      new_instance = described_class.add('AGENTIL_PROBE')

      described_class.users.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC AGENTIL_PROBE}
      new_instance.name.should == 'AGENTIL_PROBE'
      new_instance.id.should == 4

      new_instance.element.parent.should == config.path('PROBE/USERS')
      new_instance.element.name.should == 'USER4'
      new_instance.element[:ID].should == "4"
      new_instance.element[:TITLE].should == 'AGENTIL_PROBE'
    end

    it "should connect the new user object with an existing config entry if an element is provided" do
      described_class.users.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC}

      existing_element = config.path('PROBE/USERS/USER2')
      new_instance = described_class.add('AGENTIL_PROBE', existing_element)

      new_instance.name.should == 'AGENTIL_PROBE'
      new_instance.id.should == 2
      new_instance.element.should == existing_element

      new_instance.element.parent.should == config.path('PROBE/USERS')
      new_instance.element.name.should == 'USER2'
      new_instance.element[:ID].should == "2"
    end
  end

  describe "class method del" do
    it "should to nothing if user does not exist" do
      described_class.users.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC}
      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2 USER3}

      described_class.del 'NO_SUCH_USER'

      described_class.users.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC}
      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2 USER3}
    end

    it "should remove the system and the corresponding config section if user does exist" do
      described_class.users.keys.should == %w{SAP_PROBE SAP_DEV_PROBE DDIC}
      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2 USER3}

      described_class.del 'SAP_DEV_PROBE'

      described_class.users.keys.should == %w{SAP_PROBE DDIC}
      config.path('PROBE/USERS').children.map(&:name).should == %w{USER1 USER2}
    end

    it "should rename all user subsections" do
      described_class.users['SAP_PROBE'].element.name.should == 'USER1'
      described_class.users['SAP_PROBE'].element.should == config.path('PROBE/USERS/USER1')
      described_class.users['SAP_DEV_PROBE'].element.name.should == 'USER2'
      described_class.users['SAP_DEV_PROBE'].element.should == config.path('PROBE/USERS/USER2')
      described_class.users['DDIC'].element.name.should == 'USER3'
      described_class.users['DDIC'].element.should == config.path('PROBE/USERS/USER3')

      described_class.del 'SAP_DEV_PROBE'

      described_class.users['SAP_PROBE'].element.name.should == 'USER1'
      described_class.users['SAP_PROBE'].element.should == config.path('PROBE/USERS/USER1')
      described_class.users['DDIC'].element.name.should == 'USER2'
      described_class.users['DDIC'].element.should == config.path('PROBE/USERS/USER2')
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
      described_class.genid.should == 4
      described_class.add('NEW_USER_1')
      described_class.genid.should == 5
      described_class.add('NEW_USER_2')
      described_class.genid.should == 6
      described_class.del('NEW_USER_1')
      described_class.genid.should == 4
      described_class.add('NEW_USER_3')
      described_class.genid.should == 6
    end
  end

  describe "id" do
    it "should return the id as integer" do
      described_class.users['SAP_PROBE'].id.should == 1
      described_class.users['SAP_DEV_PROBE'].id.should == 2
      described_class.users['DDIC'].id.should == 3
    end
  end

  describe "handling properties" do

    let :new_user do
      described_class.parse
      described_class.add('NEW_USER')
    end

    let :user do
      described_class.parse
      described_class.users['SAP_DEV_PROBE']
    end

    {
      :password => :ENCRYPTED_PASSWD
    }.each_pair do |property, attribute|
      describe "getting password" do
        it "should return nil if attribute #{attribute} does not exist" do
          new_user.send(property).should be_nil
        end
        it "should return the value of attribute #{attribute}" do
          user.element.expects(:[]).with(attribute).returns 'foo'
          user.send(property).should == 'foo'
        end
      end
  
      describe "setting #{property}" do
        it "should modify attribute #{attribute}" do
          user.element.expects(:[]=).with(attribute, 'foo')
          user.send("#{property}=", 'foo')
        end
      end
    end
  end
end
