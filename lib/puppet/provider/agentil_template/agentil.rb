require 'puppet/util/agentil'

Puppet::Type.type(:agentil_template).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::Agentil.parse unless Puppet::Util::Agentil.parsed?
    Puppet::Util::Agentil.templates.each do |id, template|
      instances << new(:name => template.name, :ensure => :present, :agentil_template => template)
    end
    instances
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    get(:ensure) != :absent
  end

  def create
    raise Puppet::Error, 'Unable to create a new template without a system property'  unless resource[:system]
    new_template = Puppet::Util::Agentil.add_template
    new_template.name = resource[:name]
    new_template.system_template = resource[:system]
    new_template.jobs = resource[:jobs] if resource[:jobs]
    new_template.monitors = resource[:monitors] if resource[:monitors]
    @property_hash[:agentil_template] = new_template
  end

  def destroy
    Puppet::Util::Agentil.del_template @property_hash[:agentil_template].id
    @property_hash.delete :agentil_template
  end

  def jobs
    @property_hash[:agentil_template].jobs
  end

  def jobs=(new_value)
    @property_hash[:agentil_template].jobs = new_value
  end

  def monitors
    @property_hash[:agentil_template].monitors
  end

  def monitors=(new_value)
    @property_hash[:agentil_template].monitors = new_value
  end

  def system
    @property_hash[:agentil_template].system_template
  end

  def system=(new_value)
    @property_hash[:agentil_template].system_template = new_value
  end

  def tablespace_used
    used = {}
    if job = @property_hash[:agentil_template].custom_jobs[166] and parameters = job.child('PARAMETER_VALUES')
      names = PSON.parse(parameters[:INDEX000])
      values = PSON.parse(parameters[:INDEX001])

      names.each_with_index do |tablespace, index|
        used[tablespace.intern] = values[index].to_i
      end
    end
    used
  end

  def tablespace_used=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 166
    else
      job = @property_hash[:agentil_template].add_custom_job 166
      names = []
      values = []
      new_value.keys.sort.each do |tablespace|
        names  << tablespace.to_s
        values << new_value[tablespace]
      end
      job.path('PARAMETER_VALUES')[:INDEX000] = names.to_pson
      job.path('PARAMETER_VALUES')[:INDEX001] = values.to_pson
    end
  end

  def expected_instances
    if job = @property_hash[:agentil_template].custom_jobs[177] and parameters = job.child('EXPECTED_INSTANCES')
      parameters.values_in_order
    else
      []
    end
  end

  def expected_instances=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 177
    else
      job = @property_hash[:agentil_template].add_custom_job 177

      mandatory_instances_info = job.path('MANDATORY_INSTANCES')
      criticality_info = job.path('CRITICITIES')
      autoclear_info = job.path('AUTO_CLEARS')
      expected_instances_info = job.path('EXPECTED_INSTANCES')

      mandatory_instances_info.clear_attr
      criticality_info.clear_attr
      autoclear_info.clear_attr
      expected_instances_info.clear_attr

      new_value.each_with_index do |instance, index|
        key = sprintf("INDEX%03d", index).intern
        expected_instances_info[key] = instance
        mandatory_instances_info[key] = 'true'
        criticality_info[key] = '5'
        autoclear_info[key] = 'true'
      end
    end
  end

  def flush
    Puppet::Util::Agentil.sync
  end
end
