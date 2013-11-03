Puppet::Type.newtype(:agentil_user) do

  @doc = "Manages a sap user inside the `sapbasis_agentil.cfg` file. If you want
    to monitor a SAP ABAP Systems with the `sapbasis_agentil` probe, you'll
    need a user the probe can use to actually connect to your SAP system.

    You can define multiple users in the `sapbasis_agentil` probe and each system
    you want to monitor has to be assigned to one of these users.

    The `agenil_users` resource can be used to describe such a user:

    Example:

        agentil_user { 'SAP_PROBE':
          ensure      => present,
          password    => 'encrypted_password'
        }

    In order to get the encrypted password you currently have to create the user
    in the GUI once and check the configuration file afterwards. From now on you
    can manage this user through puppet."

  ensurable

  newparam(:name) do
    desc "The name of the user. The name has to be all uppercase"
    isnamevar

    validate do |value|
      unless /^[A-Z][A-Z0-9_]*$/.match(value)
        raise Puppet::Error, "Username must only contain uppercase letters, digits and underscores"
      end
    end
  end

  newproperty(:password) do
    desc  "The encrypted password. To get the encrypted password you currently have to create the
      user in the probe GUI and check the configuration file afterwards."
  end
end
