require 'puppet/util/agentil'

class Puppet::Util::AgentilJob

  attr_reader :id, :element, :template, :system, :sid

  def initialize(id, element, template)
    @id = id
    @element = element
    @template = template
    @system = @template.assigned_system
    if @system
      @sid = @system.sid
    end
  end
end
