Puppet::Type.newtype(:agentil_template) do

  @doc = "Manages a template that can be used to monitor your sap systems.
    Please notice the difference between a non-system template which can
    be seen in the probe GUI and a system template which is assigned to
    one specific system. These latter cannot be seen in the probe GUI and are
    implicitly created on the fly when you assign one template to a system.

    Both template types can (and must) be managed with the `agentil_template`
    type.

    Example:

        agentil_template { 'System template for System sap01':
          ensure    => present,
          system    => 'true',
          monitors  => [ 1, 4, 10, 20, 33 ],
          jobs      => [ 4, 5, 12, 177, 3 ],
          instances => [ D00_sap01, D01_sap01 ],
        }

    The instances property will cause a customization of job 177 (instance
    availability) to include the specified instances"

  ensurable

  newparam(:name) do
    desc "The name of the template."
    isnamevar
  end

  newproperty(:system) do
    desc  "Set to true if the template is a system template (can only be assigned
      to one specific system) or a general template that can also be seen in the
      probe GUI"

    newvalues :true, :false
  end

  newproperty(:jobs, :array_matching => :all) do
    desc "An array of job ids that should be assigned to the template"

    validate do |value|
      unless /^\d+$/.match(value)
        raise Puppet::Error, "Job ID has to be numeric, not #{value}"
      end
    end
  end

  newproperty(:monitors, :array_matching => :all) do
    desc "An array of monitor ids that should be assigned to the template"

    validate do |value|
      unless /^\d+$/.match(value)
        raise Puppet::Error, "Monitor ID has to be numeric, not #{value}"
      end
    end
  end

  newproperty(:instances, :array_matching => :all) do
    desc "An array of instances. This does only make sense for a system
      template and will cause a customization of job 177 which is responsible
      to check instance availability"
  end
end
