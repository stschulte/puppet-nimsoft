require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

class Puppet::Provider::Nimsoft < Puppet::Provider

  def self.register_config(filename, sectionname)
    @filename = filename
    @sectionname = sectionname

    @config = Puppet::Util::NimsoftConfig.add(@filename)
    @section = @config.section(@sectionname)
  end

  def self.config
    @config
  end

  def self.section
    @section
  end

  def self.map_fields(mapping_table = {})
    mapping_table.each_pair do |puppet_attribute, nimsoft_section_and_attribute|
      define_method(puppet_attribute) do
        # nimsoft_attribute can be something like subsection/key so we need to
        # split subsection and key apart
        targetsection = element 
        if nimsoft_section_and_attribute.include? '/'
          subsections = nimsoft_section_and_attribute.split('/')
          nimsoft_attribute = subsections.pop.intern
          targetsection = subsections.inject(element) do |section, subsection|
            section.child(subsection) if section
          end
        else
          nimsoft_attribute = nimsoft_section_and_attribute.intern
        end
        if targetsection
          targetsection.attributes[nimsoft_attribute] || :absent
        else
          :absent
        end
      end

      define_method(puppet_attribute.to_s + "=") do |new_value|
        # nimsoft_attribute can be something like subsection/key so we need to
        # split subsection and key apart
        targetsection = element
        if nimsoft_section_and_attribute.include? '/'
          subsections = nimsoft_section_and_attribute.split('/')
          nimsoft_attribute = subsections.pop.intern
          targetsection = subsections.inject(element) do |section, subsection|
            section.child(subsection) || Puppet::Util::NimsoftSection.new(subsection, section)
          end
        else
          nimsoft_attribute = nimsoft_section_and_attribute.intern
        end
        targetsection.attributes[nimsoft_attribute] = new_value
      end
    end
  end

  def element
    @property_hash[:element]
  end

  def element=(new_value)
    @property_hash[:element] = new_value
  end
  
  def self.instances
    instances = []
    if section
      instances = section.children.map do |element|
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
    element = Puppet::Util::NimsoftSection.new(name, self.class.section)
    self.class.resource_type.validproperties.each do |attr|
      element[attr] = resource[attr] if resource[attr]
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
