Puppet::Type.newtype(:nimsoft_oracle_connection) do

  @doc = "The `nimsoft_oracle_connection` type can be used to describe
    a connection of the `oracle` probe to monitor an oracle instance."

  newparam(:name) do
    desc "The name of the connection"
    isnamevar
  end

  ensurable

  newproperty(:description) do
    desc "A short description"
  end

  newproperty(:connection) do
    desc "The connection string. This can ether be a SID if you want to
      work with a `tnsnames.ora` or can follow the easy connect naming method
      (`host:port/service_name`)"
  end

  newproperty(:user) do
  end

  newproperty(:password) do
  end

  newproperty(:retry) do
    desc "Specifies the number of retries to connect to the database until
      the probe will give up"

    validate do |value|
      unless /^\d+$/.match(value)
        raise Puppet::Error, "retry must be a positive number, not #{value.inspect}"
      end
    end
  end

  newproperty(:retry_delay) do
    desc "If retry has been set to value greater than zero, retry_delay will
      specify how long the probe will wait between connection attempts. The
      value can be specified in seconds or minutes (e.g `30 sec` or `1 min`)"

    validate do |value|
      unless /^\d+ (sec|min)$/.match(value)
        raise Puppet::Error, "retry_delay must be a positive number and must be specified in \"sec\" or \"min\", not #{value.inspect}"
      end
    end
  end
      
end
