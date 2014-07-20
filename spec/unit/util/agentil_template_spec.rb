#!/usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/agentil'
require 'puppet/util/nimsoft_config'

describe Puppet::Util::AgentilTemplate do

  before :each do
    Puppet::Util::Agentil.initvars
  end

  let :template do
    described_class.new(1000002, template_element)
  end

  let :new_template do
    described_class.new(1000004, new_template_element)
  end

  let :template_element do
    {
      'NAME'            => 'System Template for system id 2',
      'VERSION'         => '2.0',
      'ID'              => '1000002',
      'SYSTEM_TEMPLATE' => 'true',
      'JOBS'            => [ 79, 78, 600, 601 ],
      'CUSTOMIZATION'   => {
        177 => {
          'ID'         => '177',
          'CUSTOMIZED' => 'true'
        },
        '79' => {
          'ID'         => '177',
          'CUSTOMIZED' => 'true'
        },
        '78' => {
          'ID'         => '177',
          'CUSTOMIZED' => 'true'
        },
      }
    }
  end

  let :new_template_element do
    {
      'ID'      => '1000004',
      'VERSION' => '2.0'
    }
  end

  describe "id" do
    it "should return the id as integer" do
      expect(template.id).to eq(1000002)
    end
  end

  describe "getting custom jobs" do
    it "should return an empty hash if template has no customizations" do
      expect(new_template.custom_jobs).to be_empty
    end

    it "should return an hash of jobs" do
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78)
    end
  end

  describe "add_custom_job" do
    it "should add an entry to the custom_jobs list" do
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78)
      template.add_custom_job 600
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78, 600)
      template.add_custom_job 30
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78, 600, 30)
    end

    it "should add a subsection to the custo section" do
      expect(template.element['CUSTOMIZATION']).to_not have_key '600'

      custom_job = template.add_custom_job 600
      new_child = template.element['CUSTOMIZATION']['600']

      expect(custom_job).to eq(new_child)
      expect(new_child['ID']).to eq('600')
      expect(new_child['CUSTOMIZED']).to eq('true')
    end

    it "should create the custo section if it does not already exist" do
      expect(new_template.element).to_not have_key('CUSTOMIZATION')
      expect(new_template.custom_jobs.keys).to be_empty

      custom_job = new_template.add_custom_job 177

      expect(new_template.element).to have_key('CUSTOMIZATION')
      expect(new_template.element['CUSTOMIZATION']['177']).to eq(custom_job)
    end
  end

  describe "del_custom_job" do
    it "should do nothing if job is not customized" do
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78)
      template.del_custom_job 99
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78)
    end

    it "should remove the entry from the custom_jobs list" do
      expect(template.custom_jobs.keys).to contain_exactly(177, 79, 78)
      template.del_custom_job 79
      expect(template.custom_jobs.keys).to contain_exactly(177, 78)
      template.del_custom_job 177
      expect(template.custom_jobs.keys).to contain_exactly(78)
      template.del_custom_job 78
      expect(template.custom_jobs.keys).to be_empty
    end

    it "should remove the subsection from the custo section" do
      expect(template.element['CUSTOMIZATION']).to have_key '79'
      template.del_custom_job 79
      expect(template.element['CUSTOMIZATION']).to_not have_key '79'
    end

    it "should not touch other customizations" do
      expect(template.element['CUSTOMIZATION'].keys).to contain_exactly(177, '79', '78' )
      template.del_custom_job 79
      expect(template.element['CUSTOMIZATION'].keys).to contain_exactly(177, '78')
    end

    it "should remove the CUSTOMIZATION section if this was the last customization" do
      expect(template.element['CUSTOMIZATION'].keys).to contain_exactly(177, '79', '78')

      template.del_custom_job 177
      template.del_custom_job 79
      template.del_custom_job 78

      expect(template.element).to_not have_key('CUSTOMIZATION')
    end
  end

  describe "getting jobs" do
    it "should return an empty array if no jobs" do
      template.element.delete 'JOBS'
      expect(template.jobs).to be_empty
    end

    it "should return an array of numeric job ids" do
      expect(template.jobs).to eq([ 79, 78, 600, 601 ])
    end
  end

  describe "setting jobs" do
    it "should remove the jobs section if new value is empty" do
      expect(template.element).to have_key('JOBS')
      template.jobs = []
      expect(template.element).to_not have_key('JOBS')
    end

    it "should replace current job ids with new ones" do
      template.jobs = [ 10, 5, 23 ]
      expect(template.element['JOBS']).to eq([10, 5, 23])
    end

    it "should create the jobs section first if necessary" do
      template.element.delete 'JOBS'

      template.jobs = [ 10, 5, 23 ]
      expect(template.element['JOBS']).to eq([10, 5, 23])
    end
  end

  describe "getting system_template" do
    it "should return :true if template is a system template" do
      template.element["SYSTEM_TEMPLATE"] = 'true'
      expect(template.system_template).to eq(:true)
    end

    it "should return :false if template is not a system template" do
      template.element["SYSTEM_TEMPLATE"] = 'false'
      expect(template.system_template).to eq(:false)
    end
  end

  describe "setting system_template" do
    it "should set SYSTEM_TEMPLATE to true if new value is :true" do
      template.element.expects(:[]=).with("SYSTEM_TEMPLATE", 'true')
      template.system_template = :true
    end

    it "should set SYSTEM_TEMPLATE to false if new value is :false" do
      template.element.expects(:[]=).with("SYSTEM_TEMPLATE", 'false')
      template.system_template = :false
    end
  end
end
