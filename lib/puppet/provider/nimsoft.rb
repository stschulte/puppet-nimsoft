require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Provider::Nimsoft < Puppet::Provider

  def self.register_config(filename, sectionname)
    @filename = filename
    @sectionname = sectionname

    @config = Puppet::Util::NimsoftConfig.add(@filename)
  end

  def self.config
    @config
  end

  def self.initvars
    @config = nil
    @root = nil
    @filename = nil
    @sectionname = nil
  end

  def self.root
    unless @root
      @config.parse unless @config.loaded?
      @root = @config.path(@sectionname)
    end
    @root
  end

  def self.map_property(puppet_attribute, nimsoft_attribute, options = {})
    define_method(puppet_attribute) do
      if element
        element.path(options[:section])[nimsoft_attribute] || :absent
      else
        :absent
      end
    end
    define_method(puppet_attribute.to_s + "=") do |new_value|
      if element
        if new_value == :absent
          element.path(options[:section]).del_attr nimsoft_attribute
        else
          element.path(options[:section])[nimsoft_attribute] = new_value
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
    if self.class.resource_type
      self.class.resource_type.validproperties.each do |attr|
        next if attr == :ensure
        if respond_to?("#{attr}=") and resource[attr]
          send("#{attr}=", resource[attr])
        end
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
