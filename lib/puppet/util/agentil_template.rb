require 'puppet/util/agentil'

class Puppet::Util::AgentilTemplate

  attr_reader :id, :element, :assigned_system
  
  def initialize(id, element, assigned_system = nil)
    @id = id
    @element = element

    @assigned_system = assigned_system
  end

  def custom_jobs
    jobs = {}
    if cust = @element['CUSTOMIZATION']
      cust.each_pair do |id, job|
        jobs[id.to_i] = job
      end
    end
    jobs
  end

  def name
    @element['NAME']
  end

  def name=(new_value)
    @element['NAME'] = new_value
  end

  def system_template?
    @element['SYSTEM_TEMPLATE'] and @element['SYSTEM_TEMPLATE'].downcase.intern == :true
  end

  def system_template
    @element['SYSTEM_TEMPLATE'].downcase.intern
  end

  def system_template=(new_value)
    @element['SYSTEM_TEMPLATE'] = new_value.to_s
  end

  def jobs
    @element['JOBS'] || []
  end

  def jobs=(new_value)
    if new_value.empty?
      @element.delete('JOBS')
    else
      @element['JOBS'] = new_value.dup
    end
  end

  # Monitors in no valid attribute anymore
  def monitors
    []
  end

  # Monitors in no valid attribute anymore
  def monitors=(new_value)
    @element.delete('MONITORS')
  end

  def customized?(jobid)
    cust = @element['CUSTOMIZATION'] and cust[jobid.to_s]
  end

  def add_custom_job(jobid)
    @element['CUSTOMIZATION'] ||= {}
    @element['CUSTOMIZATION'][jobid.to_s] ||= {}

    job = @element['CUSTOMIZATION'][jobid.to_s]
    job['ID'] = jobid.to_s
    job['CUSTOMIZED'] = 'true'
    job
  end

  def del_custom_job(jobid)
    if cust = @element['CUSTOMIZATION']
      cust.delete(jobid.to_s)
      cust.delete(jobid.to_i)
      if cust.empty?
        @element.delete('CUSTOMIZATION')
      end
    end
  end
end
