Puppet::Type.newtype(:nimsoft_disk) do

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
    desc "Do we want to report if the disk is missing?"
  end

  newproperty(:active) do
    desc "Should this disk be monitored?"
  end

  newproperty(:warning) do
    desc "The warning threshold in free space percentage"
  end

  newproperty(:warning_enable) do
    desc "Specifies wether the warning level should be enabled or not"
  end


  newproperty(:critical) do
    desc "The critical threshold in free space percentage"
  end

  newproperty(:critical_enable) do
    desc "Specifies wether the critical level should be enabled or not"
  end
end
