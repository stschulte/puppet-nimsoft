require 'puppet/util/agentil_template'

class Puppet::Util::AgentilJob177

  attr_reader :name, :template, :instances

  def self.initvars
    @config = nil
    @loaded = false
    @jobs = {}
  end

  def self.loaded?
    @loaded
  end

  def self.parse
    @jobs = {}
    Puppet::Util::AgentilTemplate.templates.each do |name, template|
      if template.customized?(177)
        add(name, template)
      end
    end
    @loaded = true
  end

  def self.add(name, template)
    unless @jobs.include? name
      element = template.add_custom_job(177)
      @jobs[name] = new(name, template, element)
    end
    @jobs[name]
  end

  def self.del(name)
    if job = @jobs.delete(name)
      template = job.template
      template.del_custom_job 177
    end
  end

  def self.jobs
    parse unless loaded?
    @jobs
  end

  def initialize(name, template, element)
    @name = name
    @template = template
    @element = element
    @instances = []

    mandatory_instances_info = @element.child('MANDATORY_INSTANCES')
    criticality_info = @element.child('CRITICITIES')
    autoclear_info = @element.child('AUTO_CLEARS')
    expected_instances_info = @element.child('EXPECTED_INSTANCES')

    if expected_instances_info
      expected_instances_info.keys_in_order.each do |index|
        @instances << {
          :name        => expected_instances_info[index],
          :mandatory   => mandatory_instances_info[index],
          :criticality => criticality_info[index],
          :autoclear   => autoclear_info[index]
        }
      end
    end
  end

  def add_instance(name, options = {})
    new_instance = { :name => name }
    new_instance[:criticality] = options[:criticality] || '5'
    new_instance[:autoclear] = options[:autoclear] || 'true'
    new_instance[:mandatory] = options[:mandatory] || 'true'

    @instances << new_instance
    sync_instances
    new_instance
  end

  def del_instance(name)
    if instance = @instances.select{ |i| i[:name] == name }.first
      @instances.delete instance
      sync_instances
      instance
    end
  end

  def mod_instance(name, options = {})
    if instance = @instances.select{ |i| i[:name] == name }.first
      instance[:criticality] = options[:criticality] if options[:criticality]
      instance[:autoclear] = options[:autoclear] if options[:autoclear]
      instance[:mandatory] = options[:mandatory] if options[:mandatory]
      sync_instances
      instance
    else
      raise Puppet::Error, "Unable to modify instance #{name}. Instance not found"
    end
  end

  def sync_instances
    mandatory_instances_info = @element.path('MANDATORY_INSTANCES')
    criticality_info = @element.path('CRITICITIES')
    autoclear_info = @element.path('AUTO_CLEARS')
    expected_instances_info = @element.path('EXPECTED_INSTANCES')

    if @instances.empty?
      @element.children.delete mandatory_instances_info
      @element.children.delete criticality_info
      @element.children.delete autoclear_info
      @element.children.delete expected_instances_info
    else
      mandatory_instances_info.clear_attr
      criticality_info.clear_attr
      autoclear_info.clear_attr
      expected_instances_info.clear_attr

      @instances.each_with_index do |instance, index|
        key = sprintf("INDEX%03d", index).intern
        expected_instances_info[key] = instance[:name]
        mandatory_instances_info[key] = instance[:mandatory]
        criticality_info[key] = instance[:criticality]
        autoclear_info[key] = instance[:autoclear]
      end
    end
  end
end
