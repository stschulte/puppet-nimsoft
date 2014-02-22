Puppet::Type.newtype(:nimsoft_process) do

  @doc = "A `process` resource describes a nimsoft monitoring profile
    for the processes probe.

    Example:"

  newparam(:name) do
    desc "The name of the profile"
    isnamevar
  end

  ensurable

  newproperty(:pattern) do
    desc "The pattern that should be looked up in the process table.
      This can either be a single command or the command with arguments.
      Make sure to also set the `match` parameter accordingly"
  end

  newproperty(:match) do
    desc "This defines if just the binary has to be present in the
      process table or if the full argument list has to match the
      `pattern` parameter"

    newvalues :nameonly, :cmdline
    defaultto :nameonly
  end

  newproperty(:active) do
    desc "Defines wether the profile should be active or deactivated"

    newvalues :yes, :no
  end

  newproperty(:trackpid) do
    desc "Defines wether the process identifier should be tracked. This
      way the probe is able to detect process restarts"


    newvalues :yes, :no
  end

  newproperty(:count) do
    desc "The number of expected processes. This can either be an absolute
      value or a minimal or maximum value"

    validate do |value|
      unless value =~ /^(?:(?:>|>=|<=|<|!=) )?\d+$/
        raise Puppet::Error, "count must be of the form `1`, `> 1`, `>= 1`, `< 5`, `<= 5`, `!= 0`, not #{value}"
      end
    end

  end

  newproperty(:description) do
    desc "A short description of the profile."
  end

  newproperty(:alarm_on, :array_matching => :all) do
    desc "Defines when an alarm should be triggered. You can pass an
      array if you want to trigger an alarm on multiple conditions"

    newvalues :up, :down, :restart
  end
end
