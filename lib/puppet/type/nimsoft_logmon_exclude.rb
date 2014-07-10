Puppet::Type.newtype(:nimsoft_logmon_exclude) do

  @doc = "The `nimsoft_logmon_exclude` type describes a single exclude rule
    of a profile in the `logmon` probe. This can be a pattern or a regular
    expression and every block or message that matches will be excluded
    from the watchers.

    Example:

        nimsoft_logmon_exclude { 'system log/ignore failed su'
          ensure   => present,
          active   => yes,
          match    => '/FAILED su for \S+ by/',
        }

    The name of the resource must be of the for `profile_name/exclude_name`"


  newparam(:name) do
    desc "The name of the exclude rule."
    isnamevar

    validate do |value|
      unless /^.+\/.+$/.match(value)
        raise Puppet::Error, "missing profile name. The name has to be of the form `profile_name/exclude_name` and must include the correct profile name, not #{value}"
      end
    end
  end

  ensurable

  newproperty(:active) do
    desc "Set to 'yes' if the exclude should be active and 'no' if the
      watcher rule should be inactive"

    newvalues :yes, :no
  end

  newproperty(:match) do
    desc "The pattern that has to match. This can be a simple glob or a
      regular expression"
  end
end
