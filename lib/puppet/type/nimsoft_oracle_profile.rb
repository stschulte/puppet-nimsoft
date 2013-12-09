Puppet::Type.newtype(:nimsoft_oracle_profile) do

  @doc = "The `nimsoft_oracle_connection` type can be used to describe
    a profile of the `oracle` probe to monitor an oracle instance. It is
    most useful together with the `nimsoft_oracle_connection` type."

  newparam(:name) do
    desc "The name of the profile"
    isnamevar
  end

  ensurable

  newproperty(:active) do
    desc "Wether the profile should be active (`yes`) or not (`no`)"

    newvalues :yes, :no
  end

  newproperty(:description) do
    desc "A short description"
  end

  newproperty(:connection) do
    desc "The name of the connection this profile should use. You can
      create the connection with the `nimsoft_oracle_connection` type."
  end

  newproperty(:source) do
    desc "The alarm source that should be used in outgoing events"
  end

  newproperty(:interval) do
    desc "Specifies the default interval between two checkpoint
      executions if no specific value is defined in the checkpoint
      itself"

    validate do |value|
      unless /^\d+ (sec|min)$/.match(value)
        raise Puppet::Error, "interval must be a positive number and must be specified in \"sec\" or \"min\", not #{value.inspect}"
      end
    end
  end

  newproperty(:heartbeat) do
    desc "Specifies the interval at which all checkpoint schedules
      will be tested and trigger eventual checkpoint executions."

    validate do |value|
      unless /^\d+ (sec|min)$/.match(value)
        raise Puppet::Error, "heartbeat must be a positive number and must be specified in \"sec\" or \"min\", not #{value.inspect}"
      end
    end
  end

  newproperty(:profile_timeout) do
    desc "The timeout for the whole profile. Can be expressed in minutes
      (e.g. `10 min`) or seconds (e.g. `30 sec`)"

    validate do |value|
      unless /^\d+ (sec|min)$/.match(value)
        raise Puppet::Error, "profile_timeout must be a positive number and must be specified in \"sec\" or \"min\", not #{value.inspect}"
      end
    end
  end

  newproperty(:sql_timeout) do
    desc "The timeout for each sql query that represents one checkpoint
      Can be expressed in minutes (e.g. `10 min`) or seconds (e.g. `30 sec`)"

    validate do |value|
      unless /^\d+ (sec|min)$/.match(value)
        raise Puppet::Error, "sql_timeout must be a positive number and must be specified in \"sec\" or \"min\", not #{value.inspect}"
      end
    end
  end

  newproperty(:profile_timeout_msg) do
    desc "Messagename for profile timeout alarms"
  end

  newproperty(:sql_timeout_msg) do
    desc "Messagename for sql timeout alarms"
  end

  newproperty(:clear_msg) do
    desc "Messagename for timeout clear messages"
  end

  newproperty(:severity) do
    desc "The severity used for timeout messages"
    newvalues :info, :warning, :minor, :major, :critical
  end

  newproperty(:connection_failed_msg) do
    desc "Messagename fot the message that should be sent in case no
      connection to the database is possible"
  end

  autorequire(:nimsoft_oracle_connection) do
    self[:connection]
  end

end
