Puppet::Type.newtype(:nimsoft_logmon_profile) do

  @doc = "The `nimsoft_logmon_profile` type describes a profile of the
    `logmon` probe. A profile can be used to monitor a specific logfile
    and watcher rules describe patterns that can be found in the specific
    logfile.

    The `nimsoft_logmon_profile` type does only describe general profile
    attributes and watcher rules can then be described as a
    `nimsoft_logmon_watcher` resource.

    Example:

        nimsoft_logmon_profile { 'system log':
          ensure       => present,
          active       => yes,
          file         => '/var/log/messages',
          mode         => updates,
          qos          => no,  # do not generate Quality of Service messages
          alarm        => yes, # allow creation of alarm messages
          alarm_maxsev => critical,
        }


    Please note that the `logmon` probe is also able to monitor a url,
    the exit code of a command, or a nimbus queue. These alternate
    usecases cannot be handled by the `nimsoft_logmon_profile` resource
    (yet)"

  newparam(:name) do
    desc "The name of the profile"
    isnamevar
  end

  ensurable

  newproperty(:active) do
    desc "Set to 'yes' if the profile should be active and 'no' if the
      profile should be inactive"

    newvalues :yes, :no
  end

  newproperty(:file) do
    desc "The filename you want to monitor. You can also include
      time formatting primitives (see the probe manual)"
  end

  newproperty(:mode) do
    desc "The mode describes how the probe monitors the specific file. Valid
      options are `cat` (file is always scanned from top to bottom), `updates`
      (file is scanned from the last EOF mark), `full` (like `cat`, but file must
      change between two runs), and `full_time` (like `full`, but only access
      time has to change, not the content itself)"

    newvalues :cat, :updates, :full, :full_time
  end

  newproperty(:interval) do
    desc "Specifies the  interval between two checks. Can be expressed
      in minutes (e.g. `10 min`) or seconds (e.g. `30 sec`)"

    validate do |value|
      unless /^\d+ (sec|min)$/.match(value)
        raise Puppet::Error, "interval must be a positive number and must be specified in \"sec\" or \"min\", not #{value.inspect}"
      end
    end
  end

  newproperty(:qos) do
    desc "Describes wether or not variables and number of matches should be
      sent as Quality of Service messages"

    newvalues :yes, :no
  end

  newproperty(:alarm) do
    desc "Describes wether or not alarm messages should be sent when a
      watcher rule matches"

    newvalues :yes, :no
  end

  newproperty(:alarm_maxserv) do
    desc "The maximum alarm severity."

    newvalues :info, :warning, :minor, :major, :critical
  end
end
