require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Provider::Nimsoft < Puppet::Provider

  def self.register_config(filename, sectionname)
    @filename = filename
    @sectionname = sectionname

    @config = Puppet::Util::NimsoftConfig.add(@filename)
    @root = @config.section(@sectionname)
  end

  def self.config
    @config
  end

  def self.root
    @root
  end

  def self.map_property(puppet_attribute, key, sectionname = nil)
    define_method(puppet_attribute) do
      if element
        e = sectionname.nil? ? element : element.subsection(sectionname)
        e.attributes[key] || :absent
      else
        :absent
      end
    end
    define_method(puppet_attribute.to_s + "=") do |new_value|
      if element
        e = sectionname.nil? ? element : element.subsection(sectionname)
        if new_value == :absent
          e.attributes.delete key
        else
          e.attributes[key] = new_value
        end
      end
    end
  end

  def element
    @property_hash[:element]
  end

  def self.instances
    instances = []
    if root
      instances = root.children.map do |element|
        new(:name => element.name, :ensure => :present, :element => element)
      end
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
    @property_hash[:element] = Puppet::Util::NimsoftSection.new(name, self.class.root)
    self.class.resource_type.validproperties.each do |attr|
      next if attr == :ensure
      if respond_to?("#{attr}=") and resource[attr]
        send("#{attr}=", resource[attr])
      end
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
    if @property_hash[:element]
      @property_hash[:element].parent.children.delete element
      @property_hash[:element] = nil
    end
  end

  def flush
    self.class.config.sync
  end
end
