Puppet::Type.newtype(:agentil_landscape) do

  @doc = "Manages a sap landscape inside the `sapbasis_agentil.cfg` file.
    Example:

        agentil_landscape { 'sap01.example.com':
          ensure      => present,
          sid         => 'PRO',
          company     => 'Examplesoft',
          description => 'managed by puppet',
        }"

  ensurable

  newparam(:name) do
    desc "The name of the landscape. This is typically a full qualified domain name"
  end

  newproperty(:sid) do
    desc  "The system identifier. Must consists of three of the alphanumerical characters"

    validate do |value|
      unless /^[A-Z][A-Z0-9][A-Z0-9]$/.match(value)
        raise Puppet::Error, "SID #{value} is invalid and must consist of three alphanumerical characters and cannot start with a digit"
      end
    end
  end

  newproperty(:description) do
    desc "A short description about the landscape. This will only show up in the GUI"
  end

  newproperty(:company) do
    desc "The company that belongs to the landscape. This will only show up in the GUI"
  end

end
