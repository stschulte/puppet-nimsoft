Facter.add('install_nimsoft') do
  setcode do
    Facter::Core::Execution.exec('test -e /opt/nimsoft/bin/nimbus; echo $?')
  end
end
