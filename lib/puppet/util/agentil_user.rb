require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Util::AgentilUser

  attr_reader :name, :element

  def self.filename
    '/opt/nimsoft/probes/application/sapbasis_agentil/sapbasis_agentil.cfg'
  end

  def self.initvars
    @config = nil
    @loaded = false
    @users = {}
  end

  def self.config
    unless @config
      @config = Puppet::Util::NimsoftConfig.add(filename)
      @config.tabsize = 4
    end
    @config
  end

  def self.root
    config.path('PROBE/USERS')
  end

  def self.parse
    config.parse unless config.loaded?
    @users = {}
    root.children.each do |element|
      add(element[:USER], element)
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
    unless @users.include? name
      if element.nil?
        element_name = "USER#{root.children.size + 1}"
        element = Puppet::Util::NimsoftSection.new(element_name, root)
      end
      @users[name] = new(name, element)
    end
    @users[name]
  end

  def self.del(name)
    if user = @users.delete(name)
      root.children.delete user.element
      root.children.each_with_index do |child, index|
        child.name = sprintf "USER%d", index+1
      end
    end
  end

  def self.users
    parse unless loaded?
    @users
  end

  def self.genid
    id = 1
    taken_ids = users.values.map(&:id)
    while taken_ids.include? id
      id += 1
    end
    id
  end

  def initialize(name, element)
    @name = name
    @element = element
    @element[:USER] = name
    @element[:TITLE] ||= name
    @element[:ID] ||= self.class.genid.to_s
  end

  def id
    @element[:ID].to_i
  end

  def password
    @element[:ENCRYPTED_PASSWD]
  end

  def password=(new_value)
    @element[:ENCRYPTED_PASSWD] = new_value
  end
end
