#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:agentil_template).provider(:agentil) do

  let :provider do
    described_class.new(
      :name             => 'NEW_TEMPLATE',
      :ensure           => :present,
      :agentil_template => template
    )
  end

  let :template do
    Puppet::Util::AgentilTemplate.new(1000001, template_element)
  end

  let :template_element do
    {
      'ID'   => '1000001',
      'NAME' => 'NEW_TEMPLATE'
    }
  end

  let :tablespace_element do
    {
      'ID'         => '166',
      'CUSTOMIZED' => 'true',
      'PARAMETERS' => [
        {
          'IDX'             => '0',
          'PARAMETER_VALUE' =>  '["TBL1","TBL2","TBL3"]'
        },
        {
          'IDX'             => '1',
          'PARAMETER_VALUE' => '[90,95,92]'
        },
        {
          'IDX'             => '2',
          'PARAMETER_VALUE' => '80'
        }
      ]
    }
  end

  let :instances_element do
    {
      'ID' =>  '177',
      'CUSTOMIZED' => 'true',
      'Default' =>  [
        {
          'IDX'                => '0',
          'SEVERITY'           => '5',
          'EXPECTED_INSTANCES' => 'sap01_PRO_00',
          'AUTOCLEAR'          => 'true',
          'MANDATORY'          => 'true'
        },
        {
          'IDX'                => '0',
          'SEVERITY'           => '5',
          'EXPECTED_INSTANCES' => 'sap01_PRO_01',
          'AUTOCLEAR'          => 'true',
          'MANDATORY'          => 'true'
        }
      ]
    }
  end

  let :resource do
    resource = Puppet::Type.type(:agentil_template).new(
      :name      => 'NEW_TEMPLATE',
      :ensure    => 'present',
      :system    => 'true',
      :jobs      => [ '122', '55' ],
    )
    resource.provider = provider
    resource
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        instance = described_class.new(:name => 'NEW_TEMPLATE', :ensure => :present)
        expect(instance).to be_exists
      end

      it "should return false otherwise" do
        instance = described_class.new(:name => 'NEW_TEMPLATE')
        expect(instance).to_not be_exists
      end
    end

    describe "create" do
      it "should add a new template" do
        resource
        Puppet::Util::Agentil.expects(:add_template).returns template
        template.expects(:name=).with('NEW_TEMPLATE')
        template.expects(:system_template=).with(:true)
        template.expects(:jobs=).with([ 122, 55 ])
        provider.create
      end

      it "should raise an error if the system is missing" do
        resource = Puppet::Type.type(:agentil_template).new(
          :name        => 'FOOBAR',
          :ensure      => :present
        )
        resource.provider = provider
        expect { provider.create }.to raise_error(Puppet::Error, 'Unable to create a new template without a system property')
      end
    end
    
    describe "destroy" do
      it "should delete a template" do
        resource
        Puppet::Util::Agentil.expects(:del_template).with(1000001)
        provider.destroy
      end

      it "should not complain about a missing system property" do
        resource = Puppet::Type.type(:agentil_user).new(
          :name   => 'NEW_TEMPLATE',
          :ensure => 'absent'
        )
        resource.provider = provider
        Puppet::Util::Agentil.expects(:del_template).with(1000001)
        provider.destroy
      end
    end
  end

  {:system => :system_template, :jobs => :jobs }.each_pair do |property, utilproperty|
    describe "when managing #{property}" do
      it "should delegate the getter method to the #{utilproperty} AgentilTemplate object" do
        template.expects(utilproperty).returns "value_for_#{property}"
        expect(provider.send(property)).to eq("value_for_#{property}")
      end

      it "should delegate the setter method to the #{utilproperty} AgentilTemplate object" do
        template.expects("#{utilproperty}=".intern).with "value_for_#{property}"
        provider.send("#{property}=","value_for_#{property}")
      end
    end
  end

  describe "when managing tablespace_used" do
    it "should return an empty hash if job 166 is not modified" do
      expect(provider.tablespace_used).to be_empty
    end

    it "should return a hash of the form { tablespace => value }" do
      template.expects(:custom_jobs).returns({ 166 => tablespace_element })
      expect(provider.tablespace_used).to eq({
        :TBL1 => 90,
        :TBL2 => 95,
        :TBL3 => 92
      })
    end

    it "should create a customization for job 166 if not already present" do
      provider.tablespace_used = { :TBLA => 10, :TBLB => 20 }
      expect(template.custom_jobs).to have_key(166)
      expect(template.custom_jobs[166]).to eq({
        'ID'         => '166',
        'CUSTOMIZED' => 'true',
        'PARAMETERS' => [
          {
            'IDX' => '0',
            'PARAMETER_VALUE' => '["TBLA","TBLB"]'
          },
          {
            'IDX' => '1',
            'PARAMETER_VALUE' => '[10,20]'
          }
        ]
      })
    end

    it "should update the parameters of job 166 if already present but out of sync" do
      template.stubs(:custom_jobs).returns({ 166 => tablespace_element })
      template.stubs(:add_custom_job).with(166).returns(tablespace_element)
      provider.tablespace_used = { :TBLA => 10, :TBLB => 20 }
      expect(template.custom_jobs[166]).to eq({
        'ID' => '166',
        'CUSTOMIZED' => 'true',
        'PARAMETERS' => [
          {
            'IDX' => '0',
            'PARAMETER_VALUE' => '["TBLA","TBLB"]'
          },
          {
            'IDX' => '1',
            'PARAMETER_VALUE' => '[10,20]'
          }
        ]
      })
    end
  end

  describe "when managing expected_instances" do
    it "should return an empty array if job 177 is not customized" do
      expect(provider.expected_instances).to be_empty
    end

    it "should return an array of expected instances if job 177 is customized" do
      template.expects(:custom_jobs).returns({ 177 => instances_element })
      expect(provider.expected_instances).to eq(%w{sap01_PRO_00 sap01_PRO_01})
    end

    it "should create a customization for job 177 if not already present" do
      provider.expected_instances = [ 'i00', 'i01', 'i02']
      expect(template.custom_jobs[177]).to eq({
        'ID'         => '177',
        'CUSTOMIZED' => 'true',
        'Default'    => [
          {
            'IDX'                => "0",
            'SEVERITY'           => "5",
            'EXPECTED_INSTANCES' => "i00",
            'AUTOCLEAR'          => "true",
            'MANDATORY'          => "true"
          },
          {
            'IDX'                => "1",
            'SEVERITY'           => "5",
            'EXPECTED_INSTANCES' => "i01",
            'AUTOCLEAR'          => "true",
            'MANDATORY'          => "true"
          },
          {
            'IDX'                => "2",
            'SEVERITY'           => "5",
            'EXPECTED_INSTANCES' => "i02",
            'AUTOCLEAR'          => "true",
            'MANDATORY'          => "true"
          }
        ]
      })
    end

    it "should update the customization for job 177 if already present but out of sync" do
      template.stubs(:custom_jobs).returns({ 177 => instances_element })
      template.stubs(:add_custom_job).with(177).returns(instances_element)
      provider.expected_instances = [ 'i00', 'i01', 'i02']

      expect(template.custom_jobs[177]).to eq({
        'ID'         => '177',
        'CUSTOMIZED' => 'true',
        'Default'    => [
          {
            'IDX'                => "0",
            'SEVERITY'           => "5",
            'EXPECTED_INSTANCES' => "i00",
            'AUTOCLEAR'          => "true",
            'MANDATORY'          => "true"
          },
          {
            'IDX'                => "1",
            'SEVERITY'           => "5",
            'EXPECTED_INSTANCES' => "i01",
            'AUTOCLEAR'          => "true",
            'MANDATORY'          => "true"
          },
          {
            'IDX'                => "2",
            'SEVERITY'           => "5",
            'EXPECTED_INSTANCES' => "i02",
            'AUTOCLEAR'          => "true",
            'MANDATORY'          => "true"
          }
        ]
      })
    end
  end

  describe "flush" do
    it "should sync the configuration file" do
      Puppet::Util::Agentil.expects(:sync)
      provider.flush
    end
  end
end
