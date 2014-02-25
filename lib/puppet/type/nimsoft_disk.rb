Puppet::Type.newtype(:nimsoft_disk) do

  @doc = "The `nimsoft_disk` resource describes a monitoring rule for a single
    filesystem. Example:

        nimsoft_disk { '/var':
          ensure      => present,
          description => '/var managed by puppet',
          warning     => '20',
          critical    => '10',
        }"

  newparam(:name) do
    desc "The Mountpoint of the disk"
    isnamevar
  end

  ensurable

  newproperty(:description) do
    desc "A short description of the Filesystem"
  end

  newproperty(:device) do 
    desc "The underlying blockdevice or nfs share that is mounted"
  end

  newproperty(:missing) do
    desc "Set this property to `yes` to raise an alarm when the described filesystem is absent"
    newvalues :yes, :no
  end

  newproperty(:active) do
    desc "Should this disk be monitored?"
    newvalues :yes, :no
  end

  newproperty(:warning) do
    desc "The warning threshold in free space percentage. Set this to absent if you want to remove the warning threshold"
    newvalues :absent, /^\d+$/

    validate do |value|
      return true if value == :absent or value == 'absent'
      if /^\d+$/.match(value)
        if value.to_i < 0 or value.to_i > 100
          raise Puppet::Error, "threshold has to between 0 and 100, not #{value}"
        end
      else
        raise Puppet::Error, "threshold has to be numeric, not #{value}"
      end
    end
  end

  newproperty(:critical) do
    desc "The critical threshold in free space percentage. Set this to absent if you want to remove the critical threshold"
    newvalues :absent, /^\d+$/

    validate do |value|
      return true if value == :absent or value == 'absent'
      if /^\d+$/.match(value)
        if value.to_i < 0 or value.to_i > 100
          raise Puppet::Error, "threshold has to between 0 and 100, not #{value}"
        end
      else
        raise Puppet::Error, "threshold has to be numeric, not #{value}"
      end
    end
  end
end
