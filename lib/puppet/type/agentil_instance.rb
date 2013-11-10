require 'puppet/type/agentil_template'

Puppet::Type.newtype(:agentil_instance) do

  @doc = "The `agentil_instance` resource type describes an instance
    that can appear as a job 177 customization. The job 177 is responsible
    for checking all your SAP instances and can be customized to include
    the concrete instance names to check.

    Example:

        agentil_instance { 'sap01-2_PRO_00':
          ensure      => present,
          template    => 'System Template for sap01',
          mandatory   => true,
          autoclear   => false,
          criticality => warning,
        }"


  newparam(:name) do
    desc "The name of the instance. Check transaction sm51 if you are unsure"
    isnamevar
  end

  ensurable

  newproperty(:template) do
    desc "The name of the system template the instance should appear in"
  end

  newproperty(:mandatory) do
    desc "Wether this instance is mandatory or not"

    newvalues :true, :false
  end

  newproperty(:criticality) do
    desc "The severity of the message that is sent when the instance becomes unavailable"
    newvalues :info, :warning, :minor, :major, :critical
  end

  newproperty(:autoclear) do
    newvalues :true, :false
  end

  autorequire(:agentil_template) do
    self[:template]
  end
end
