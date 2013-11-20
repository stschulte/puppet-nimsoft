Puppet::Type.newtype(:agentil_system) do

  @doc = "Manage a system inside the `sapbasis_agentil.cfg` configuration
    file of the `sapbasis_agentil` probe. A system must belong to a
    landscape that you can ensure with the `agentil_landscape` type. A
    system represents an ABAP or JAVA connector and contains information
    about to connect to the SAP system:

    Sample:

        agentil_system { 'PRO_sap01':
          ensure => present,
          sid    => 'PRO',
          host   => 'sap01.example.com',
          ip     => '192.168.0.1',
          stack  => 'abap',
          client => '000',
          user   => 'SAP_PROBE',
          group  => 'LOGON_GROUP_01',
        }"


  newparam(:name) do
    desc "The name of the instance"
    isnamevar
  end

  ensurable

  newproperty(:sid) do
    desc  "The system identifier. Must consists of three of the alphanumerical characters"

    validate do |value|
      unless /^[A-Z][A-Z0-9][A-Z0-9]$/.match(value)
        raise Puppet::Error, "SID #{value} is invalid and must consist of three alphanumerical characters and cannot start with a digit"
      end
    end
  end

  newproperty(:host) do
    desc "The hostname you want to connect to"
  end

  newproperty(:ip, :array_matching => :all) do
    desc "One or more IP adresses that belong to the SAP system"
  end

  newproperty(:stack) do
    desc "The stack of the sap system. Specify `abap` if this is a standard
      abap system and `java` if it is a java system. You also specify `dual`
      if your system implements both stacks"

    newvalues :abap, :java, :dual
  end

  newproperty(:user) do
    desc "The user that the probe should use when connection to the
      SAP system. The user has to be already present on the target SAP
      system and in the sapbasis_agentil probe. You can create the
      user definition with the `agentil_user` resource type."

    validate do |value|
      unless /^[A-Z][A-Z0-9_]*$/.match(value)
        raise Puppet::Error, "Username must only contain uppercase letters, digits and underscores"
      end
    end
  end

  newproperty(:client) do
    desc "The client number you want to connect to. A special monitoring
      user must be configured for this client. It is probably best to use
      client `000` here if you want to configure multiple SAP systems as
      this client is always present."

    validate do |value|
      unless /^[0-9][0-9][0-9]$/.match(value)
        raise Puppet::Error, "#{value} is no valid client number. The client must consist of three digits"
      end
    end
  end

  newproperty(:group) do
    desc "The logon group you want to use. If you have multiple instances a
      group can be used for load balancing logon requests. You can also use
      this feature when you connect to your SAP instance for monitoring
      purposes. A logon group can be configured in transaction `SMLG`
      and must be already present"
  end

  newproperty(:landscape) do
    desc "A reference to the landscape your system should belong to. The
      property value must match the name of the landscape exactly. The
      landscape has to be already present. If you define the landscape with
      puppet via the `agentil_landscape` puppet type, the landscape will be
      automatically required."
  end

  newproperty(:template) do
    desc "The name of the default template. This has to be a system
      template and is the one that actually defines what will be
      monitored"
  end

  newproperty(:templates, :array_matching => :all) do
    desc "The names of the templates that should be assigned to the
      SAP system. These assignments can be seen in the `sapbasis_agentil`
      probe GUI but actally have no influence in what will be monitored."

      def insync?(is)
        is.sort == @should.sort
      end
  end

  autorequire(:agentil_landscape) do
    self[:landscape]
  end

  autorequire(:agentil_user) do
    self[:user]
  end

  autorequire(:agentil_template) do
    req = []
    req << self[:template] if self[:template]
    req += self[:templates] if self[:templates]
    req
  end
end
