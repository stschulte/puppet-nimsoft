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
        }"

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

    munge do |value|
      value.to_i
    end
  end

  # Custom job 166
  newproperty(:tablespace_used) do
    desc "A Hashmap of tablespaces that should be monitored differently
      than the rest. The hash should be of the form

          tablespace_used => {
            PSAPSR3  => 90,
            PSAPUNDO => 50,
          }"

    validate do |value|
      raise Puppet::Error, "Hash required of the form { tablespace => value_in_percent }" unless value.is_a? Hash
      value.each_pair do |key,value|
        raise Puppet::Error, "The tablespace #{key} has an invalid should value of #{value}. Must be an Integer" unless value.to_s =~ /^\d+$/
      end
    end

    munge do |value|
      new_hash = {}
      value.each_pair do |key,value|
        new_hash[key.intern] = value.to_i
      end
      new_hash
    end
  end

  # Custom job 177
  newproperty(:expected_instances, :array_matching => :all) do
    desc "An array of expected instances. This customizes the job \"instance availability\""

    validate do |value|
      raise Puppet::Error, "instance #{value.inspect} must not contain any whitespace" if value =~ /\s/
    end
  end

  newproperty(:rfc_destinations, :array_matching => :all) do
    desc "An array of rfc connections (sm59) that should be monitored for availability"
  end
end
