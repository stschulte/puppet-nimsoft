Puppet::Type.newtype(:nimsoft_oracle_connection) do

  @doc = "The `nimsoft_oracle_connection` type can be used to describe
    a connection of the `oracle` probe to monitor an oracle instance."

  newparam(:name) do
    desc "The name of the connection"
    isnamevar
  end

  ensurable

  newproperty(:description) do
    desc "A short description"
  end

  newproperty(:connection) do
    desc "The connection string. This can ether be a SID if you want to
      work with a `tnsnames.ora` or can follow the easy connect naming method
      (`host:port/service_name`)"
  end

  newproperty(:user) do
  end

  newproperty(:password) do
  end
      
end
