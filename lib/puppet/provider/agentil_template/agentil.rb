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

  def system
    @property_hash[:agentil_template].system_template
  end

  def system=(new_value)
    @property_hash[:agentil_template].system_template = new_value
  end

  def tablespace_used
    used = {}
    if job = @property_hash[:agentil_template].custom_jobs[624] and tablespaces = job['Tablespaces'] and tablespaces.is_a? Array
      tablespaces.each do |ts|
        used[ts["NAME"]] = ts["TS_SIZE_THRESHOLD"].to_i
      end
    end
    used
  end

  def tablespace_used=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 624
    else
      job = @property_hash[:agentil_template].add_custom_job 624
      job['Tablespaces'] = []
      job['GLOBAL_METRICS'] = []
      new_value.keys.sort.each_with_index do |tablespace, index|
        job['Tablespaces'] << {
          'IDX'               => index.to_s,
          'NAME'              => tablespace,
          'TS_ACTIVE'         => true,
          'TS_SIZE_THRESHOLD' => new_value[tablespace].to_s,
          'TS_SEVERITY'       => 4,
          'TS_AUTO_CLEAR'     => true,
          'TS_ALARM_ENABLED'  => true,
          'TS_METRIC_ENABLED' => false,
          'TS_REPORT_ENABLED' => true
        }
        job['GLOBAL_METRICS'] << {
          'IDX'       => index.to_s,
          'TS_PREFIX' => ''
        }
      end
    end
  end

  def expected_instances
    if job = @property_hash[:agentil_template].custom_jobs[177] and instances = job['Default']
      instances.map { |i| i['EXPECTED_INSTANCES'] }
    else
      []
    end
  end

  def expected_instances=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 177
    else
      job = @property_hash[:agentil_template].add_custom_job 177

      job['Default'] = []
      new_value.each_with_index do |instance, index|
        job['Default'] << {
          'IDX'                    => index.to_s,
          'MANDATORY'              => true,
          'SEVERITY'               => 5,
          'RESTART_CHECK_SEVERITY' => 2,
          'AUTOCLEAR'              => true,
          'EXPECTED_INSTANCES'     => instance,
          'PREFIX'                 => ''
        }
      end
    end
  end

  def rfc_destinations
    if job = @property_hash[:agentil_template].custom_jobs[602] and destinations = job['Default']
      destinations.map { |d| d["DESTINATION"] }
    else
      []
    end
  end

  def rfc_destinations=(new_value)
    if new_value.empty?
      @property_hash[:agentil_template].del_custom_job 602
    else
      job = @property_hash[:agentil_template].add_custom_job 602
      job['Default'] = []
      new_value.each_with_index do |destination, index|
        job['Default'] << {
          'IDX'               => index.to_s,
          'ACTIVE'            => true,
          'DESTINATION'       => destination,
          'EXCLUDED_INSTANCE' => '',
          'STRICT'            => true,
          'CHECK_MODE'        => 2,
          'SEVERITY'          => 4,
          'AUTO_CLEAR'        => true,
          'PREFIX'            => '',
          'ALARM_ENABLED'     => true,
          'METRIC_ENABLED'    => true,
          'REPORT_ENABLED'    => false
        }
      end
    end
  end

  def flush
    Puppet::Util::Agentil.sync
  end
end
