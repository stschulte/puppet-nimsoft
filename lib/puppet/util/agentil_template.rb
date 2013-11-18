require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Util::AgentilTemplate

  attr_reader :name, :element, :custom_jobs

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.initvars
    @config = nil
    @loaded = false
    @templates = {}
  end

  def self.config
    unless @config
      @config = Puppet::Util::NimsoftConfig.add(filename)
      @config.tabsize = 4
    end
    @config
  end

  def self.root
    config.path('PROBE/TEMPLATES')
  end

  def self.parse
    config.parse unless config.loaded?
    @templates = {}
    root.children.each do |element|
      # Only catch custom templates which start with 1000000
      if /^TEMPLATE1\d{6}$/.match(element.name)
        add(element[:NAME], element)
      end
    end
    @loaded = true
  end

  def self.loaded?
    @loaded
  end

  def self.sync
    config.sync
  end

  def self.add(name, element = nil)
    unless @templates.include? name
      if element.nil?
        element_name = "TEMPLATE#{root.children.select { |c| /^TEMPLATE1\d{6}$/.match(c.name) }.size + 1000000}"
        element = Puppet::Util::NimsoftSection.new(element_name, root)
      end
      @templates[name] = new(name, element)
    end
    @templates[name]
  end

  def self.del(name)
    if user = @templates.delete(name)
      root.children.delete user.element
      root.children.select { |c| /^TEMPLATE1\d{6}$/.match(c.name) }.each_with_index do |child, index|
        child.name = sprintf "TEMPLATE%d", index + 1000000
      end
    end
  end

  def self.templates
    parse unless loaded?
    @templates
  end

  def self.genid
    id = 1000000
    taken_ids = templates.values.map(&:id)
    while taken_ids.include? id
      id += 1
    end
    id
  end

  def initialize(name, element)
    @name = name
    @element = element
    @element[:NAME] = name
    @element[:ID] ||= self.class.genid.to_s
    @element[:VERSION] ||= '1'

    @custom_jobs = []
    if cust = @element.child('CUSTO')
      cust.children.each do |child|
        if match = /^JOB(\d+)$/.match(child.name)
          @custom_jobs << match.captures[0].to_i
        end
      end
    end
  end

  def id
    @element[:ID].to_i
  end

  def version
    @element[:VERSION]
  end

  def version=(new_value)
    @element[:VERSION] = new_value
  end

  def system
    @element[:SYSTEM_TEMPLATE].downcase.intern
  end

  def system=(new_value)
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
    @custom_jobs.include?(jobid)
  end

  def add_custom_job(jobid)
    @custom_jobs << jobid unless @custom_jobs.include? jobid
    custom_job = @element.path("CUSTO/JOB#{jobid}")
    custom_job[:ID] = jobid.to_s
    custom_job[:CUSTOMIZED] = 'true'
    custom_job
  end

  def del_custom_job(jobid)
    if @custom_jobs.delete jobid
      cust = @element.child('CUSTO')
      if job = cust.child("JOB#{jobid}")
        cust.children.delete(job)
      end
      if cust.children.empty?
        @element.children.delete cust
      end
    end
  end
end
