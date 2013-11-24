Puppet::Type.newtype(:nimsoft_dirscan) do
  @doc = "The `dirscan` probe can be used to the number of
    files in a directory or the size of files. The `nimsoft_dirscan`
    type can be used to configure a profile for the `dirscan` probe.

    Example:

        nimsoft_dirscan { 'Oracle alertlog size':
          ensure      => present,
          active      => yes,
          description => 'monitors the alertlog of oracle instance PROD',
          directory   => '/u01/app/oracle/diag/rdbms/prod/PROD/trace',
          pattern     => 'alert_PROD.log',
          recurse     => no,
          direxists   => yes,
          size        => '< 50M'
          size_type   => individual
        }"

  newparam(:name) do
    desc "name of the profile"
    isnamevar
  end

  ensurable

  newproperty(:active) do
    desc "Described if the profile is active. Can be either `yes` or `no`"
    newvalues :yes, :no
  end

  newproperty(:description) do
    desc "A short description about the profile"
  end

  newproperty(:directory) do
  end

  newproperty(:pattern) do
    desc "The pattern can be a single filename or a regular expression to
      match multiple files"
  end

  newproperty(:recurse) do
    newvalues :yes, :no
  end

  newproperty(:direxists) do
    desc "Should an alarm be triggered if the directory does not exist?. Can
      be either `yes` or `no`"

    newvalues :yes, :no
  end

  newproperty(:direxists_action) do
    desc "A command that should be executed if the directory does not exist"
  end

  newproperty(:nofiles) do
    desc "Describes the expected number of files. Can be of the form `> 10`,
      `< 5`, `<= 3`, `>= 3`, or `= 10`"

    validate do |value|
      unless value == :absent or value =~ /^(>=|<=|<|>)?\s*[0-9]+$/
        raise Puppet::Error, "nofiles must be of the form `5`, `< 5`, `> 5`, not #{value}"
      end
    end
  end

  newproperty(:nofiles_action) do
    desc "A command to run when the number of files do not match"
  end

  newproperty(:size) do
    desc "The expected size of a file. Can be of the form `> 10M`, `< 20K`, `>= 6G`, `3M`"

    validate do |value|
      unless value == :absent or value =~/^(>=|<=|<|>)?\s*[0-9]+\s*(K|M|G)?$/
        raise Puppet::Error, "size must be of the form `> 10M`, `< 20K`, `>= 6G`, `3M`, not #{value}"
      end
    end
  end

  newproperty(:size_type) do
    desc "Specifies if the expected size should be considered for individual files, the
      smallest file or the largest file"

    newvalues :individual, :smallest, :largest

    defaultto do
      if resource[:size]
        :individual
      end
    end
  end

  newproperty(:size_action) do
    desc "The command to run when the size does not match"
  end
end
