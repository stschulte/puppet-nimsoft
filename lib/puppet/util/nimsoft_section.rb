class Puppet::Util::NimsoftSection

  attr_accessor :parent, :name, :children, :attributes

  def initialize(name, parent = nil)
    @parent = parent
    @parent.children << self unless @parent.nil?
    @name = name
    @children = []
    @attributes = {}
    @attribute_order = []
  end

  def child(name)
    @children.select { |c| c.name == name }.first
  end

  def [](name)
    @attributes[name]
  end

  def []=(name, value)
    @attributes[name] = value
    @attribute_order << name unless @attribute_order.include? name
  end

  def del_attr(name)
    @attributes.delete(name)
    @attribute_order.delete(name)
  end

  def clear_attr
    @attributes.clear
    @attribute_order.clear
  end

  def keys_in_order
    @attribute_order
  end

  def values_in_order
    @attribute_order.map { |attr| @attributes[attr] }
  end

  def to_cfg(tabsize = 3, indent = 0)
    s = " "*tabsize*indent << "<#{name.gsub('/', '#')}>\n"
    @attribute_order.each do |key|
      if @attributes[key].to_s.empty?
        s <<  " "*tabsize*(indent+1) << "#{key} =\n"
      else
        s <<  " "*tabsize*(indent+1) << "#{key} = #{@attributes[key]}\n"
      end
    end
    @children.each { |c| s += c.to_cfg(tabsize, indent+1) }
    s <<  " "*tabsize*indent << "</#{name.gsub('/','#')}>\n"
    s
  end

  def path(name)
    return self unless name
    name.split('/').inject(self) do |section, subsectionname|
      section.child(subsectionname) || Puppet::Util::NimsoftSection.new(subsectionname, section)
    end
  end
end
