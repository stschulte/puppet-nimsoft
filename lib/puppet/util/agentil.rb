require 'puppet/util/nimsoft_config'

require 'puppet/util/agentil_landscape'
require 'puppet/util/agentil_system'
require 'puppet/util/agentil_template'

class Puppet::Util::Agentil

  class << self
    attr_reader :users, :templates, :landscapes, :systems
  end

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.config
    unless @config
      @config = Puppet::Util::NimsoftConfig.add(filename)
      @config.tabsize = 4
    end
    @config
  end

  def self.initvars
    @config = nil
    @users = {}
    @templates = {}
    @landscapes = {}
    @systems = {}
    @instances = {}
    @parsed = false
  end

  def self.parsed?
    @parsed
  end

  def self.parse
    # First load the configuration file as a tree
    initvars
    config.parse unless config.loaded?

    # Now generate abstracted objects for the different sections
    if root = config.child('PROBE')
      if landscapes = root.child('LANDSCAPES')
        landscapes.children.each do |element|
          add_landscape(element)
        end
      end

      map_template2system = {}

      if systems = root.child('SYSTEMS')
        systems.children.each do |element|
          system = add_system(element)
          if templateid = element[:DEFAULT_TEMPLATE]
            map_template2system[templateid.to_i] = system
          end
        end
      end

      if users = root.child('USERS')
        users.children.each do |element|
          add_user(element)
        end
      end

      if templates = root.child('TEMPLATES')
        templates.children.each do |element|
          templateid = element[:ID].to_i

          # If we have parsed a system earlier that claims to belong
          # to the template, we will let the template know about it
          assigned_system = nil
          if element[:SYSTEM_TEMPLATE] == 'true'
            unless assigned_system = map_template2system[templateid]
              Puppet.warning "System template #{element[:NAME].inspect} does not belong to any host"
            end
          end
          add_template(element, assigned_system)
        end
      end
    end
    @parsed = true
  end

  def self.add_landscape(element = nil)
    id = nil
    if element
      id = element[:ID].to_i
    else
      root = config.path('PROBE/LANDSCAPES')
      element_name = "LANDSCAPE#{root.children.size + 1}"
      element = Puppet::Util::NimsoftSection.new(element_name, root)

      # generate the next free id
      id = 1
      id += 1 while @landscapes.include? id
      element[:ID] = id.to_s
      element[:ACTIVE] = 'true'
    end

    @landscapes[id] = Puppet::Util::AgentilLandscape.new(id, element)
  end

  def self.add_system(element = nil)
    id = nil
    if element
      id = element[:ID].to_i
    else
      root = config.path('PROBE/SYSTEMS')
      element_name = "SYSTEM#{root.children.size + 1}"
      element = Puppet::Util::NimsoftSection.new(element_name, root)

      id = 1
      id += 1 while @systems.include? id
      element[:ID] = id.to_s
      element[:ACTIVE] = 'true'
    end
    @systems[id] = Puppet::Util::AgentilSystem.new(id, element)
  end

  def self.add_user(element = nil)
    id = nil
    if element
      id = element[:ID].to_i
    else
      root = config.path('PROBE/USERS')
      element_name = "USER#{root.children.size + 1}"
      element = Puppet::Util::NimsoftSection.new(element_name, root)

      id = 1
      id += 1 while @users.include? id
      element[:ID] = id.to_s
    end
    @users[id] = Puppet::Util::AgentilUser.new(id, element)
  end

  def self.add_template(element = nil, assigned_system = nil)
    id = nil
    if element
      id = element[:ID].to_i
    else
      root = config.path('PROBE/TEMPLATES')
      element_name = "TEMPLATE#{root.children.select { |c| /^TEMPLATE1\d{6}$/.match(c.name) }.size + 1000000}"
      element = Puppet::Util::NimsoftSection.new(element_name, root)

      id = 1000000
      id += 1 while @templates.include? id
      element[:ID] = id.to_s
      element[:VERSION] = '1'
    end
    @templates[id] = Puppet::Util::AgentilTemplate.new(id, element, assigned_system)
  end

  #def self.add_custom_job(klass, template)
  #  jobid = klass.jobid

  #  raise Puppet::Error, "Unable to add a custom job without a template" unless template

  #  element = template.element.path("CUSTO/JOB#{jobid}")

  #  id = template.id
  #  element[:ID] = jobid.to_s
  #  element[:CUSTOMIZED] = 'true'

  #  @custom_jobs[jobid][id] = klass.new(id, element)
  #end


  def self.del_landscape(id)
    if landscape = @landscapes[id]
      landscape.systems.each { |s| del_system(s.id) }
      root = config.path('PROBE/LANDSCAPES')
      root.children.delete landscape.element
      root.children.each_with_index do |child, index|
        child.name = sprintf "LANDSCAPE%d", index+1
      end
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
      root = config.path('PROBE/SYSTEMS')
      root.children.delete system.element
      root.children.each_with_index do |child, index|
        child.name = sprintf "SYSTEM%d", index+1
      end
      @systems.delete id
    else
      raise Puppet::Error, "System with id=#{id} could not be found"
    end
  end

  def self.del_template(id)
    if template = @templates[id]
      root = config.path('PROBE/TEMPLATES')
      root.children.delete template.element
      root.children.select { |c| /^TEMPLATE1\d{6}$/.match(c.name) }.each_with_index do |child, index|
        child.name = sprintf "TEMPLATE%d", index + 1000000
      end
      @templates.delete id
    else
      raise Puppet::Error, "Template with id=#{id} could not be found"
    end
  end

  def self.del_user(id)
    if user = @users[id]
      root = config.path('PROBE/USERS')
      root.children.delete user.element
      root.children.each_with_index do |child, index|
        child.name = sprintf "USER%d", index+1
      end
      @users.delete id
    else
      raise Puppet::Error, "User with id=#{id} could not be found"
    end
  end

  def self.sync
    config.sync
  end
end
