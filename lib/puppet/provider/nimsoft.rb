require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Provider::Nimsoft < Puppet::Provider

  def self.register_config(filename, sectionname)
    @filename = filename
    @sectionname = sectionname
  end

  def self.config
    @config ||= Puppet::Util::NimsoftConfig.add(@filename)
  end

  def self.initvars
    @config = nil
    @root = nil
    super
  end

  def self.root
    unless @root
      config.parse unless config.loaded?
      @root = config.path(@sectionname)
    end
    @root
  end

  def self.map_property(property, options = {}, &block)
    section = options[:section]
    attribute = options[:attribute] || property
    symbolize = options[:symbolize]

    define_method(property) do
      if element
        if value = element.path(section)[attribute]
          value = value.intern if symbolize
          if block
            block.call(:get, value)
          else
            value
          end
        else
          :absent
        end
      else
        :absent
      end
    end

    define_method("#{property}=".intern) do |new_value|
      if element
        if new_value == :absent
          element.path(section).del_attr attribute
        else
          value = block.nil? ? new_value : block.call(:set, new_value)
          element.path(section)[attribute] = value.to_s
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
