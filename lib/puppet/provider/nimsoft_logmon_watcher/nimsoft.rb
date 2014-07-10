require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_logmon_watcher).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/logmon/logmon.cfg', 'profiles'

  map_property :active, :symbolize => true
  map_property :match
  map_property :severity, :attribute => :level
  map_property :subsystem, :attribute => :subsystemid
  map_property :message
  map_property :suppkey, :attribute => :suppid
  map_property :source

  map_property :severity, :attribute => :level

  def self.instances
    instances = []
    if root
      root.children.map do |profil|
        if watchers = profil.child('watchers')
          watchers.children.each do |watcher|
            instances << new(:name => "#{profil.name}/#{watcher.name}", :ensure => :present, :element => watcher)
          end
        end
      end
    end
    instances
  end

  def create
    if match = /^(.+?)\/(.+)$/.match(name)
      profil_name = match.captures[0]
      watcher_name = match.captures[1]

      if profil = self.class.root.child(profil_name)
        watchers = profil.path('watchers')
        @property_hash[:element] = Puppet::Util::NimsoftSection.new(watcher_name, watchers)
        if self.class.resource_type
          self.class.resource_type.validproperties.sort.each do |attr|
            next if attr == :ensure
            if respond_to?("#{attr}=") and resource[attr]
              send("#{attr}=", resource[attr])
            end
          end
        end
      else
        raise Puppet::Error, "Cannot create watcher #{name}. Profile #{profil_name} not found"
      end
    else
      raise Puppet::Error, "Cannot create watcher #{name}. Unexpected name"
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
    if @property_hash[:element]
      watchers = @property_hash[:element].parent
      watchers.children.delete @property_hash[:element]
      @property_hash.delete :element
      if watchers.children.empty?
        watchers.parent.children.delete watchers
      end
    end
  end
end
