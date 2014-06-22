require 'puppet/util/agentil'

class Puppet::Util::AgentilTemplate

  attr_reader :id, :element, :assigned_system
  
  def self.registry
    Puppet::Util::Agentil
  end

  def registry
    Puppet::Util::Agentil
  end

  def initialize(id, element, assigned_system = nil)
    @id = id
    @element = element

    @assigned_system = assigned_system
  end

  def custom_jobs
    jobs = {}
    if cust = @element.child('CUSTO')
      cust.children.each do |child|
        jobs[child[:ID].to_i] = child
      end
    end
    jobs
  end

  def name
    @element[:NAME]
  end

  def name=(new_value)
    @element[:NAME] = new_value
  end

  def system_template?
    @element[:SYSTEM_TEMPLATE] and @element[:SYSTEM_TEMPLATE].downcase.intern == :true
  end

  def system_template
    @element[:SYSTEM_TEMPLATE].downcase.intern
  end

  def system_template=(new_value)
    @element[:SYSTEM_TEMPLATE] = new_value.to_s
  end

  def jobs
    if job_element = @element.child('JOBS')
      job_element.values_in_order.map(&:to_i)
    else
      []
    end
  end

  def jobs=(new_value)
    if new_value.empty?
      if job_element = @element.child('JOBS')
        @element.children.delete(job_element)
      end
    else
      job_element = @element.path('JOBS')
      job_element.clear_attr
      new_value.each_with_index do |jobid, index|
        job_element[sprintf("INDEX%03d", index).intern] = jobid.to_s
      end
    end
  end

  def monitors
    if monitor_element = @element.child('MONITORS')
      monitor_element.values_in_order.map(&:to_i)
    else
      []
    end
  end

  def monitors=(new_value)
    if new_value.empty?
      if monitor_element = @element.child('MONITORS')
        @element.children.delete(monitor_element)
      end
    else
      monitor_element = @element.path('MONITORS')
      monitor_element.clear_attr
      new_value.each_with_index do |monitorid, index|
        monitor_element[sprintf("INDEX%03d", index).intern] = monitorid.to_s
      end
    end
  end

  def customized?(jobid)
    cust = @element.child('CUSTO') and cust.child("JOB#{jobid}")
  end

  def add_custom_job(jobid)
    job = @element.path("CUSTO/JOB#{jobid}")
    job[:ID] = jobid.to_s
    job[:CUSTOMIZED] = 'true'
    job
  end

  def del_custom_job(jobid)
    cust = @element.child('CUSTO')
    if job = cust.child("JOB#{jobid}")
      cust.children.delete(job)
    end
    if cust.children.empty?
      @element.children.delete cust
    end
  end
end
