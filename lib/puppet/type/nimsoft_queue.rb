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
  end

  ensurable

  newproperty(:active) do
    newvalues :yes, :no
  end

  newproperty(:type) do
    newvalues :attach, :get, :post
  end

  newproperty(:subject, :array_matching => :all) do
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

end
