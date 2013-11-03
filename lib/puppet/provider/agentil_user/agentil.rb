require 'puppet/util/agentil_user'

Puppet::Type.type(:agentil_user).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::AgentilUser.users.each do |name, user|
      instances << new(:name => name, :ensure => :present, :user => user)
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
    raise Puppet::Error, 'Unable to create a new user without a password'  unless resource[:password]
    new_user = Puppet::Util::AgentilUser.add name
    new_user.password = resource[:password]
    @property_hash[:user] = new_user
  end

  def destroy
    Puppet::Util::AgentilUser.del name
  end

  def password
    @property_hash[:user].password
  end

  def password=(new_value)
    @property_hash[:user].password = new_value
  end

  def flush
    Puppet::Util::AgentilUser.sync
  end
end
