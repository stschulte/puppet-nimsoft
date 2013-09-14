class Puppet::Util::NimsoftSection

  attr_accessor :parent, :name, :children, :attributes

  def initialize(name, parent = nil)
    @parent = parent
    @parent.children << self unless @parent.nil?
    @name = name
    @children = []
    @attributes = {}
  end

  def child(name)
    @children.select { |c| c.name == name }.first
  end

  def [](name)
    @attributes[name]
  end

  def []=(name, value)
    @attributes[name] = value
  end

  def to_cfg(indent=0)
    s = "   "*indent + "<#{name.gsub('/', '#')}>\n"
    @attributes.each_pair do |key,value|
      s +=  "   "*(indent+1) + "#{key} = #{value}\n"
    end
    @children.each { |c| s += c.to_cfg(indent+1) }
    s +=  "   "*indent + "</#{name.gsub('/','#')}>\n"
  end
end
