require 'puppet/provider/nimsoft'

Puppet::Type.type(:nimsoft_logmon_exclude).provide(:nimsoft, :parent => Puppet::Provider::Nimsoft) do

  register_config '/opt/nimsoft/probes/system/logmon/logmon.cfg', 'profiles'

  map_property :active, :symbolize => true
  map_property :match

  def self.instances
    instances = []
    if root
      root.children.map do |profil|
        if excludes = profil.child('excludes')
          excludes.children.each do |exclude|
            instances << new(:name => "#{profil.name}/#{exclude.name}", :ensure => :present, :element => exclude)
          end
        end
      end
    end
    instances
  end

  def create
    if match = /^(.+?)\/(.+)$/.match(name)
      profil_name = match.captures[0]
      exclude_name = match.captures[1]

      if profil = self.class.root.child(profil_name)
        excludes = profil.path('excludes')
        @property_hash[:element] = Puppet::Util::NimsoftSection.new(exclude_name, excludes)
        if self.class.resource_type
          self.class.resource_type.validproperties.each do |attr|
            next if attr == :ensure
            if respond_to?("#{attr}=") and resource[attr]
              send("#{attr}=", resource[attr])
            end
          end
        end
      else
        raise Puppet::Error, "Cannot create exclude #{name}. Profile #{profil_name} not found"
      end
    else
      raise Puppet::Error, "Cannot create exclude #{name}. Unexpected name"
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
    if @property_hash[:element]
      excludes = @property_hash[:element].parent
      excludes.children.delete @property_hash[:element]
      @property_hash.delete :element
      if excludes.children.empty?
        excludes.parent.children.delete excludes
      end
    end
  end
end
