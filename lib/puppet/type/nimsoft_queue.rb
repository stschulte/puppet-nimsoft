Puppet::Type.newtype(:nimsoft_queue) do

  def attach_queue?
    self[:type] and self[:type] == :attach
  end

  def get_queue?
    self[:type] and self[:type] == :get
  end

  def post_queue?
    self[:type] and self[:type] == :post
  end

  newparam(:name) do
    isnamevar
    desc "The name of the queue"
  end

  ensurable

  newproperty(:active) do
    desc "Specify whether this queue should be active or not. Valid values are `yes` and `no`"
    newvalues :yes, :no
  end

  newproperty(:type) do
    desc "The type of the queue. A `post` queue sends messages directy to a destination hub. An
      `attach` queue can be installed for other hubs to attach to and a `get` queue can be used
      to get messages from a remote `attach` queue."
    newvalues :attach, :get, :post
  end

  newproperty(:subject, :array_matching => :all) do
    desc "Specifying a subject for an attach queue or post queue defines that only messages with
      that subject should be placed in that queue. Specifying a subject for a get queue is invalid"

    validate do |value|
      raise Puppet::Error, "subject must be provided as an array, not a comma-separated list." if value.include?(",")
    end
  end

  newproperty(:remote_queue) do
    newvalues :absent, /.*/
    defaultto { :absent if resource.attach_queue? }
  end

  newproperty(:address) do
    newvalues :absent, /.*/
    defaultto { :absent if resource.attach_queue? }
  end

  newproperty(:bulk_size) do
  end

  validate do
    if self[:address] and self[:address] != :absent and attach_queue?
      raise Puppet::Error, "Specifying an address for an attach queue is invalid. Address is only valid for get queues and post queues"
    end

    if self[:remote_queue] and self[:remote_queue] != :absent and !get_queue?
      raise Puppet::Error, "Specifying a remote queue is only valid for get queues"
    end

    if self[:subject] and get_queue?
      raise Puppet::Error, "Specifying a subject is invalid for get queues"
    end

    true
  end

end
