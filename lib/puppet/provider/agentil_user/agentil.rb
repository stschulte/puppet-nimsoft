require 'puppet/util/agentil'

Puppet::Type.type(:agentil_user).provide(:agentil) do

  def self.instances
    instances = []
    Puppet::Util::Agentil.parse unless Puppet::Util::Agentil.parsed?
    Puppet::Util::Agentil.users.each do |id, user|
      instances << new(:name => user.name, :ensure => :present, :agentil_user => user)
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
    new_user = Puppet::Util::Agentil.add_user
    new_user.name = resource[:name]
    new_user.password = resource[:password]
    @property_hash[:agentil_user] = new_user
  end

  def destroy
    Puppet::Util::Agentil.del_user @property_hash[:agentil_user].id
    @property_hash.delete :agentil_user
  end

  def password
    @property_hash[:agentil_user].password
  end

  def password=(new_value)
    @property_hash[:agentil_user].password = new_value
  end

  def flush
    Puppet::Util::Agentil.sync
  end
end
