require 'puppet/util/nimsoft_section'

class Puppet::Util::NimsoftConfig

  attr_accessor :name, :children

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

    if File.exists?(filename)
      current_section = self
      File.read(filename).each_line do |line|
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
    end
  end

  def section(name)
    name.split('/').inject(self) do |section, subsection| 
      section.child(subsection) || Puppet::Util::NimsoftSection.new(subsection, section)
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
    @children.inject("") { |content, section| content += section.to_cfg(0) }
  end
end
