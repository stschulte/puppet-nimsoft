require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Util::AgentilTemplate

  attr_reader :name, :element

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

  def instances
    instances = []
    if cust_element = @element.child('CUSTO')
      if job_element = cust_element.child('JOB177')
        if instance_element = job_element.child('EXPECTED_INSTANCES')
          instances = instance_element.values_in_order
        end
      end
    end
    instances
  end

  def instances=(new_value)
    if new_value.empty?
      if cust_element = @element.child('CUSTO')
        if job_element = cust_element.child('JOB177')
          cust_element.children.delete(job_element)
        end
        @element.children.delete(cust_element) if cust_element.children.empty?
      end
    else
      job_element = @element.path('CUSTO/JOB177')
      job_element[:ID] = '177'
      job_element[:CUSTOMIZED] = 'true'
      mandinst_element = job_element.path('MANDATORY_INSTANCES')
      crit_element = job_element.path('CRITICITIES')
      autoclear_element = job_element.path('AUTO_CLEARS')
      expinst_element = job_element.path('EXPECTED_INSTANCES')

      mandinst_element.clear_attr
      crit_element.clear_attr
      autoclear_element.clear_attr
      expinst_element.clear_attr

      new_value.each_with_index do |expected_instance, index|
        attr = sprintf("INDEX%03d", index).intern
        mandinst_element[attr] = 'true'
        crit_element[attr] = '5'
        autoclear_element[attr] = 'true'
        expinst_element[attr] = expected_instance
      end
    end
  end
end
