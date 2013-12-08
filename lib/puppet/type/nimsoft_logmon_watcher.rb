Puppet::Type.newtype(:nimsoft_logmon_watcher) do

  @doc = "The `nimsoft_logmon_watcher` type describes a watcher rule of the
    `logmon` probe. A watcher rule described a pattern that can appear in
    a logfile and describes the message that will be sent, if such a
    message appears. A watcher rule does always belong to exactly one
    profile.

    Example:

        nimsoft_logmon_watcher { 'system log/failed root login'
          ensure   => present,
          active   => yes,
          match    => '/FAILED su for root by (.*)/',
          message  => 'Possible breakin attempt detected: ${msg}',
          severity => 'warning',
        }

    The name of the resource must be of the for `profile_name/watcher_name`"


  newparam(:name) do
    desc "The name of the watcher rule."
    isnamevar

    validate do |value|
      unless /^.+\/.+$/.match(value)
        raise Puppet::Error, "missing profile name. The name has to be of the form `profile_name/watcher_name` and must include the correct profile name, not #{value}"
      end
    end
  end

  ensurable

  newproperty(:active) do
    desc "Set to 'yes' if the watcher should be active and 'no' if the
      watcher rule should be inactive"

    newvalues :yes, :no
  end

  newproperty(:match) do
    desc "The pattern that has to match. This can be a simple glob or a
      regular expression"
  end

  newproperty(:severity) do
    desc "The severity of the outgoing message"

    newvalues :clear, :info, :warning, :minor, :major, :critical
  end

  newproperty(:subsystem) do
    desc "The subsystem of the outgoing message. This can either be a string
      or a subsystem id"
  end

  newproperty(:message) do
    desc "The messagetext of the outgoing message"
  end

  newproperty(:suppkey) do
    desc "The suppression key of the outgoing message. This can be useful
      if you have good and bad messages and you want to clear the bad
      message after you recognize that the problem has been solved"
  end

  newproperty(:source) do
    desc "The source of the outgoing message"
  end
end
