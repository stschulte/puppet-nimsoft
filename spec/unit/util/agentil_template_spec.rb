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
    element = Puppet::Util::NimsoftSection.new('TEMPLATE1000002')
    element[:NAME] = 'System Template for system id 2'
    element[:VERSION] = '1'
    element[:ID] = '1000002'
    element[:SYSTEM_TEMPLATE] = 'true'
    element.path('JOBS')[:INDEX000] = '79'
    element.path('JOBS')[:INDEX001] = '78'
    element.path('JOBS')[:INDEX002] = '600'
    element.path('JOBS')[:INDEX003] = '601'
    element.path('MONITORS')[:INDEX000] = '1'
    element.path('MONITORS')[:INDEX001] = '30'
    element.path('CUSTO/JOB177')[:ID] = '177'
    element.path('CUSTO/JOB177')[:CUSTOMIZED] = 'true'
    element.path('CUSTO/JOB79')[:ID] = '79'
    element.path('CUSTO/JOB79')[:CUSTOMIZED] = 'true'
    element.path('CUSTO/JOB78')[:ID] = '78'
    element.path('CUSTO/JOB78')[:CUSTOMIZED] = 'true'
    element
  end

  let :new_template_element do
    element = Puppet::Util::NimsoftSection.new('TEMPLATE1000004')
    element[:ID] = '1000004'
    element[:VERSION] = '1'
    element
  end

  describe "id" do
    it "should return the id as integer" do
      template.id.should == 1000002
    end
  end

  describe "getting custom jobs" do
    it "should return an empty hash if template has no customizations" do
      new_template.custom_jobs.should == {}
    end

    it "should return an hash of jobs" do
      template.custom_jobs.keys.should =~ [ 177, 79, 78 ]
    end
  end

  describe "add_custom_job" do
    it "should add an entry to the custom_jobs list" do
      template.custom_jobs.keys.should =~ [ 177, 79, 78 ]
      template.add_custom_job 600
      template.custom_jobs.keys.should =~ [ 177, 79, 78, 600 ]
      template.add_custom_job 30
      template.custom_jobs.keys.should =~ [ 177, 79, 78, 600, 30 ]
    end

    it "should add a subsection to the custo section" do
      template.element.path('CUSTO').child('JOB600').should be_nil

      custom_job = template.add_custom_job 600
      new_child = template.element.path('CUSTO').child('JOB600')

      custom_job.element.should == new_child
      new_child[:ID].should == '600'
      new_child[:CUSTOMIZED].should == 'true'
    end

    it "should crate the custo section if it does not already exist" do
      new_template.element.child('CUSTO').should be_nil
      new_template.custom_jobs.keys.should be_empty

      custom_job = new_template.add_custom_job 177

      new_template.element.child('CUSTO').should_not be_nil
      new_template.element.child('CUSTO').child('JOB177').should == custom_job.element
    end
  end

  describe "del_custom_job" do
    it "should do nothing if job is not customized" do
      template.custom_jobs.keys.should =~ [ 177, 79, 78 ]
      template.del_custom_job 99
      template.custom_jobs.keys.should =~ [ 177, 79, 78 ]
    end

    it "should remove the entry from the custom_jobs list" do
      template.custom_jobs.keys.should =~ [ 177, 79, 78 ]
      template.del_custom_job 79
      template.custom_jobs.keys.should =~ [ 177, 78 ]
      template.del_custom_job 177
      template.custom_jobs.keys.should =~ [ 78 ]
      template.del_custom_job 78
      template.custom_jobs.keys.should be_empty
    end

    it "should remove the subsection from the custo section" do
      template.element.child('CUSTO').children.map(&:name).should include 'JOB79'
      template.del_custom_job 79
      template.element.child('CUSTO').children.map(&:name).should_not include 'JOB79'
    end

    it "should not touch other customizations" do
      template.element.child('CUSTO').children.map(&:name).should == [ 'JOB177', 'JOB79', 'JOB78' ]
      template.del_custom_job 79
      template.element.child('CUSTO').children.map(&:name).should == [ 'JOB177', 'JOB78' ]
    end

    it "should remove the custo section if this was the last customization" do
      template.element.child('CUSTO').children.map(&:name).should == [ 'JOB177', 'JOB79', 'JOB78' ]

      template.del_custom_job 177
      template.del_custom_job 79
      template.del_custom_job 78

      template.element.child('CUSTO').should be_nil
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

  describe "getting system_template" do
    it "should return :true if template is a system template" do
      template.element.expects(:[]).with(:SYSTEM_TEMPLATE).returns 'true'
      template.system_template.should == :true
    end

    it "should return :false if template is not a system template" do
      template.element.expects(:[]).with(:SYSTEM_TEMPLATE).returns 'false'
      template.system_template.should == :false
    end
  end

  describe "setting system_template" do
    it "should set SYSTEM_TEMPLATE to true if new value is :true" do
      template.element.expects(:[]=).with(:SYSTEM_TEMPLATE, 'true')
      template.system_template = :true
    end

    it "should set SYSTEM_TEMPLATE to false if new value is :false" do
      template.element.expects(:[]=).with(:SYSTEM_TEMPLATE, 'false')
      template.system_template = :false
    end
  end
end
