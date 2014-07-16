class Puppet::Util::AgentilUser

  attr_reader :id, :element

  def initialize(id, element)
    @id = id
    @element = element
  end

  def name
    @element["USER"]
  end

  def name=(new_value)
    @element["USER"] = new_value
    @element["TITLE"] ||= new_value
  end

  def password
    @element["ENCRYPTED_PASSWD"]
  end

  def password=(new_value)
    @element["ENCRYPTED_PASSWD"] = new_value
  end
end
