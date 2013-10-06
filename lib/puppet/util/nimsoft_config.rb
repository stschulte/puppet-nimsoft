require 'puppet/util/nimsoft_section'

class Puppet::Util::NimsoftConfig

  attr_accessor :name, :children

  def self.initvars
    @configfiles = {}
  end

  def self.add(filename)
    @configfiles ||= {}
    if @configfiles.include? filename
      @configfiles[filename]
    else
      @configfiles[filename] = new(filename)
    end
  end

  def self.flush(filename)
    @configfiles ||= {}
    if @configfiles[filename]
      @configfiles[filename].sync
    end
  end

  def initialize(filename)
    @name = filename
    @children = []
    @loaded = false
  end

  def loaded?
    @loaded
  end

  def parse
    if File.exists?(@name)
      current_section = self
      File.read(@name).each_line do |line|
        case line.chomp!
        when /^\s*<([^\/]+)>.*$/
          name = $1.gsub('#','/')
          current_section = Puppet::Util::NimsoftSection.new(name, current_section)
        when /^\s*(.*?)\s*=\s*(.*)$/
          key = $1
          value =$2
          current_section[key.intern] = value
        when /^\s*<\/(.*)>\s*$/
          current_section = current_section.parent
        end
      end
      @loaded = true
    end
  end

  def path(name)
    sectionname, subsections = name.split('/',2)
    section = child(sectionname) || Puppet::Util::NimsoftSection.new(sectionname, self)
    if subsections
      section.path(subsections)
    else
      section
    end
  end

  def child(name)
    @children.select { |c| c.name == name }.first
  end

  def sync
    File.open(@name, 'w') do |f|
      f.puts to_cfg
    end
  end

  def to_cfg
    @children.inject("") { |content, section| content += section.to_cfg }
  end
end
