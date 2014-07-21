require 'puppet/util/nimsoft_config'

require 'puppet/util/agentil_landscape'
require 'puppet/util/agentil_system'
require 'puppet/util/agentil_template'

class Puppet::Util::Agentil

  class << self
    attr_reader :config, :users, :templates, :landscapes, :systems
  end

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.initvars
    @config = nil
    @parsed = false
    @users = {}
    @templates = {}
    @landscapes = {}
    @systems = {}
  end

  def self.parsed?
    @parsed
  end

  def self.parse
    self.initvars

    unless Puppet.features.json?
      raise Puppet::Error, "Unable to parse #{filename} without the json gem. Please install json first"
    end

    begin
      @config = JSON.parse(File.read(filename))
    rescue JSON::ParserError
      @config = {}
    end

    if landscapes = @config["SYSTEMS"]
      landscapes.each do |element|
        add_landscape(element)
      end
    end

    map_template2system = {}

    if systems = @config["CONNECTORS"]
      systems.each do |element|
        system = add_system(element)
        if templateid = element['DEFAULT_TEMPLATE']
          map_template2system[templateid.to_i] = system
        end
      end
    end

    if users = @config['USER_PROFILES']
      users.each do |element|
        add_user(element)
      end
    end

    if templates = @config['TEMPLATES']
      templates.each do |element|
        templateid = element['ID'].to_i

        # If we have parsed a system earlier that claims to belong
        # to the template, we will let the template know about it
        assigned_system = nil
        if element['SYSTEM_TEMPLATE'] == 'true'
          unless assigned_system = map_template2system[templateid]
            Puppet.warning "System template #{element['NAME'].inspect} does not belong to any host"
          end
        end
        add_template(element, assigned_system)
      end
    end
    @parsed = true
  end

  def self.add_landscape(element = nil)
    id = nil
    if element
      id = element['ID'].to_i
    else
      # generate the next free id
      id = 1
      id += 1 while @landscapes.include? id
      element = {
        'ID'     => id.to_s,
        'ACTIVE' => 'true',
      }
      @config["SYSTEMS"] ||= []
      @config["SYSTEMS"] << element
    end

    @landscapes[id] = Puppet::Util::AgentilLandscape.new(id, element)
  end

  def self.add_system(element = nil)
    id = nil
    if element
      id = element['ID'].to_i
    else
      id = 1
      id += 1 while @systems.include? id
      element = {
        'ID'                     => id.to_s,
        'ACTIVE'                 => 'true',
        'MAX_INVALID_TIME'       => '180000',
        'MAX_RESPONSE_TIME'      => '30000',
        'TYPE'                   => '0',
        'NB_WORKERS'             => '1',
        'SECURE_MODE'            => 'false',
        'SAPCONTROL_PORT'        => '0',
        'CCMS_STRICT_MODE'       => 'false',
        'CRYPTO_CONVERTED'       => 'true',
        'SNC_MODE'               => 'false',
        'SNC_QUALITY_PROTECTION' => '3'
      }
      @config["CONNECTORS"] ||= []
      @config["CONNECTORS"] << element
    end
    @systems[id] = Puppet::Util::AgentilSystem.new(id, element)
  end

  def self.add_user(element = nil)
    id = nil
    if element
      id = element['ID'].to_i
    else
      id = 1
      id += 1 while @users.include? id
      element = {'ID' => id.to_s }
      @config["USER_PROFILES"] ||= []
      @config["USER_PROFILES"] << element
    end

    @users[id] = Puppet::Util::AgentilUser.new(id, element)
  end

  def self.add_template(element = nil, assigned_system = nil)
    id = nil
    if element
      id = element['ID'].to_i
    else
      id = 1000000
      id += 1 while @templates.include? id
      element = {
        'ID'      => id.to_s,
        'VERSION' => '2.0'
      }
      @config["TEMPLATES"] ||= []
      @config["TEMPLATES"] << element
    end

    @templates[id] = Puppet::Util::AgentilTemplate.new(id, element, assigned_system)
  end

  def self.del_landscape(id)
    if landscape = @landscapes[id]
      landscape.systems.each { |s| del_system(s.id) }
      @config["SYSTEMS"].delete landscape.element
      @landscapes.delete id
    else
      raise Puppet::Error, "Landscape with id=#{id} could not be found"
    end
  end

  def self.del_system(id)
    if system = @systems[id]
      if template = system.system_template
        del_template(template.id)
      end
      @config["CONNECTORS"].delete system.element
      @systems.delete id
    else
      raise Puppet::Error, "System with id=#{id} could not be found"
    end
  end

  def self.del_template(id)
    if template = @templates[id]
      @config["TEMPLATES"].delete template.element
      @templates.delete id
    else
      raise Puppet::Error, "Template with id=#{id} could not be found"
    end
  end

  def self.del_user(id)
    if user = @users[id]
      @config["USER_PROFILES"].delete user.element
      @users.delete id
    else
      raise Puppet::Error, "User with id=#{id} could not be found"
    end
  end

  def self.sync
    unless Puppet.features.json?
      raise Puppet::Error, "Unable to write to #{filename} without the json gem. Please install json first"
    end

    File.open(filename, 'w') do |f|
      f.write(JSON.pretty_generate(@config))
      f.write("\n")
    end
  end
end
