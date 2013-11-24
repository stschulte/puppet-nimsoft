#! /usr/bin/ruby

require 'spec_helper'

describe Puppet::Type.type(:nimsoft_dirscan).provider(:nimsoft) do

  let :config do
    config = Puppet::Util::NimsoftConfig.new('some_file')
    config.path('watchers/bar')
    config.stubs(:sync)
    config
  end

  let :watchers do
    config.child('watchers')
  end

  let :element do
    element = Puppet::Util::NimsoftSection.new('foo', watchers)
    element[:active] = 'yes'
    element[:name] = 'foo'
    element[:description] = 'foo profile'
    element[:pattern] = '*.log'
    element[:directory] = '/var/log'
    element[:check_dir] = 'yes'
    element[:recurse_dirs] = 'no'
    element[:number_command] = 'echo yeah'
    element[:file_size_type] = 'largest'
    element[:file_size_command] = 'echo filesize'
    element[:directory_check_command] = 'echo DirectoryCheck'
    element.path('number_condition')[:limit] = '1'
    element.path('number_condition')[:type] = 'eq'
    element.path('file_size_condition')[:limit] = '50'
    element.path('file_size_condition')[:type] = 'le'
    element.path('file_size_condition')[:unit] = 'Mb'
    element
  end

  let :provider do
    described_class.new(:name => element.name, :ensure => :present, :element => element)
  end

  let :provider_new do
    provider = described_class.new(:name => 'baz')
    resource = Puppet::Type.type(:nimsoft_dirscan).new(
      :name             => 'baz',
      :ensure           => 'present',
      :active           => 'yes',
      :description      => 'a short test',
      :directory        => '/var/log',
      :pattern          => '*.log',
      :recurse          => 'no',
      :direxists        => 'yes',
      :direxists_action => '/bin/mkdir /var/log',
      :nofiles          => '> 3',
      :size             => '<= 5M',
      :size_action      => '/bin/rm $file'
    )
    resource.provider = provider
    provider
  end

  before :each do
    Puppet::Util::NimsoftConfig.initvars
    Puppet::Util::NimsoftConfig.stubs(:add).with('/opt/nimsoft/probes/system/dirscan/dirscan.cfg').returns config
    described_class.initvars
  end

  describe "when managing ensure" do
    describe "exists?" do
      it "should return true if the instance is present" do
        provider.should be_exist
      end

      it "should return false if the instance is absent" do
        provider_new.should_not be_exist
      end
    end

    describe "create" do
      it "should add a new section" do
        described_class.root.children.map(&:name).should == [ 'bar' ]
        provider_new.create
        described_class.root.children.map(&:name).should == [ 'bar', 'baz' ]
      end

      it "should add set the correct attributes after adding the section" do
        provider_new.create

        child = described_class.root.child('baz')
        child.should_not be_nil
        child[:active].should == 'yes'
        child[:name].should == 'baz'
        child[:description].should == 'a short test'
        child[:pattern].should == '*.log'
        child[:directory].should == '/var/log'
        child[:check_dir].should == 'yes'
        child[:recurse_dirs].should == 'no'
        child[:number_command].should be_nil
        child[:file_size_type].should == 'individual'
        child[:file_size_command].should == '/bin/rm $file'
        child[:directory_check_command].should == '/bin/mkdir /var/log'

        number_condition = child.child('number_condition')
        number_condition.should_not be_nil
        number_condition[:limit].should == '3'
        number_condition[:type].should == 'gt'

        size_condition = child.child('file_size_condition')
        size_condition.should_not be_nil
        size_condition[:limit].should == '5'
        size_condition[:unit].should == 'Mb'
        size_condition[:type].should == 'le'
      end
    end

    describe "destroy" do
      it "should destroy the specific section" do
        provider = described_class.new(:name => element.name, :ensure => :present, :element => element)

        described_class.root.children.map(&:name).should == [ 'bar', 'foo' ]
        provider.destroy
        described_class.root.children.map(&:name).should == [ 'bar' ]
      end
    end
  end

  describe "when managing active" do
    it "should return :yes when active" do
      element[:active] = 'yes'
      provider.active.should == :yes
    end

    it "should return :no when not active" do
      element[:active] = 'no'
      provider.active.should == :no
    end

    it "should set active to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:active, 'yes')
      provider.active = :yes
    end

    it "should set active to \"no\" when new value is :no" do
      element.expects(:[]=).with(:active, 'no')
      provider.active = :no
    end
  end

  describe "when managing description" do
    it "should return the description field" do
      element[:description] = 'old_description'
      provider.description.should == 'old_description'
    end

    it "should update the description field with the new value" do
      element.expects(:[]=).with(:description, 'new_description')
      provider.description = 'new_description'
    end
  end

  describe "when managing pattern" do
    it "should return the pattern field" do
      element[:patter] = '*.log'
      provider.pattern.should == '*.log'
    end

    it "should update the description field with the new value" do
      element.expects(:[]=).with(:pattern, '*.log.gz')
      provider.pattern = '*.log.gz'
    end
  end

  describe "when managing recurse" do
    it "should return :yes when recurse_dirs is set to \"yes\"" do
      element[:recurse_dirs] = 'yes'
      provider.recurse.should == :yes
    end

    it "should return :no when recurse_dirs is set to \"no\"" do
      element[:recurse_dirs] = 'no'
      provider.recurse.should == :no
    end

    it "should set recurse_dirs to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:recurse_dirs, 'yes')
      provider.recurse = :yes
    end

    it "should set recurse_dirs to \"no\" when new value is :no" do
      element.expects(:[]=).with(:recurse_dirs, 'no')
      provider.recurse = :no
    end
  end

  describe "when managing direxists" do
    it "should return :yes when check_dir is set to \"yes\"" do
      element[:check_dir] = 'yes'
      provider.direxists.should == :yes
    end

    it "should return :no when check_dir is set to \"no\"" do
      element[:check_dir] = 'no'
      provider.direxists.should == :no
    end

    it "should set check_dir to \"yes\" when new value is :yes" do
      element.expects(:[]=).with(:check_dir, 'yes')
      provider.direxists = :yes
    end

    it "should set check_dir to \"no\" when new value is :no" do
      element.expects(:[]=).with(:check_dir, 'no')
      provider.direxists = :no
    end
  end

  describe "when managing direxists_action" do
    it "should return the directory_check_command field" do
      element[:directory_check_command] = '/bin/mkdir "$directory"'
      provider.direxists_action.should == '/bin/mkdir "$directory"'
    end

    it "should update the directory_check_command field with the new value" do
      element.expects(:[]=).with(:directory_check_command, '/bin/mkdir -p -m0755 "$directory"')
      provider.direxists_action = '/bin/mkdir -p -m0755 "$directory"'
    end
  end

  describe "when managing nofiles" do
    it "should return the correct value if type is eq" do
      element.path('number_condition')[:limit] = '6'
      element.path('number_condition')[:type] = 'eq'
      provider.nofiles.should == '6'
    end

    it "should return the correct value if type is lt" do
      element.path('number_condition')[:limit] = '23'
      element.path('number_condition')[:type] = 'lt'
      provider.nofiles.should == '< 23'
    end

    it "should return the correct value if type is le" do
      element.path('number_condition')[:limit] = '199'
      element.path('number_condition')[:type] = 'le'
      provider.nofiles.should == '<= 199'
    end

    it "should return the correct value if type is gt" do
      element.path('number_condition')[:limit] = '0'
      element.path('number_condition')[:type] = 'gt'
      provider.nofiles.should == '> 0'
    end

    it "should return the correct value if type is ge" do
      element.path('number_condition')[:limit] = '9'
      element.path('number_condition')[:type] = 'ge'
      provider.nofiles.should == '>= 9'
    end

    it "should set type to eq if new value has no prefix" do
      element.path('number_condition').expects(:[]=).with(:limit, '133')
      element.path('number_condition').expects(:[]=).with(:type, 'eq')
      provider.nofiles = '133'
    end

    it "should set type to lt if new value has prefix <" do
      element.path('number_condition').expects(:[]=).with(:limit, '40')
      element.path('number_condition').expects(:[]=).with(:type, 'lt')
      provider.nofiles = '< 40'
    end
    
    it "should ignore a missing space after prefix <" do
      element.path('number_condition').expects(:[]=).with(:limit, '36')
      element.path('number_condition').expects(:[]=).with(:type, 'lt')
      provider.nofiles = '< 36'
    end

    it "should set type to le if new value has prefix <=" do
      element.path('number_condition').expects(:[]=).with(:limit, '2')
      element.path('number_condition').expects(:[]=).with(:type, 'le')
      provider.nofiles = '<= 2'
    end
    
    it "should ignore a missing space after prefix <=" do
      element.path('number_condition').expects(:[]=).with(:limit, '39')
      element.path('number_condition').expects(:[]=).with(:type, 'le')
      provider.nofiles = '<=39'
    end

    it "should set type to gt if new value has prefix >" do
      element.path('number_condition').expects(:[]=).with(:limit, '23')
      element.path('number_condition').expects(:[]=).with(:type, 'gt')
      provider.nofiles = '> 23'
    end
    
    it "should ignore a missing space after prefix >" do
      element.path('number_condition').expects(:[]=).with(:limit, '5')
      element.path('number_condition').expects(:[]=).with(:type, 'gt')
      provider.nofiles = '>5'
    end

    it "should set type to ge if new value as prefix >=" do
      element.path('number_condition').expects(:[]=).with(:limit, '29')
      element.path('number_condition').expects(:[]=).with(:type, 'ge')
      provider.nofiles = '>= 29'
    end
    
    it "should ignore a missing space after prefix >=" do
      element.path('number_condition').expects(:[]=).with(:limit, '333')
      element.path('number_condition').expects(:[]=).with(:type, 'ge')
      provider.nofiles = '>=333'
    end
  end

  describe "when managing nofiles_action" do
    it "should return the number_command field" do
      element[:number_command] = '/bin/gzip -r "$directory"'
      provider.nofiles_action.should == '/bin/gzip -r "$directory"'
    end

    it "should update the number_command field with the new value" do
      element.expects(:[]=).with(:number_command, '/bin/rm -rf "$directory"')
      provider.nofiles_action = '/bin/rm -rf "$directory"'
    end
  end

  describe "when managing size" do
    it "should return the correct value if type is eq" do
      element.path('file_size_condition')[:limit] = '6'
      element.path('file_size_condition')[:type] = 'eq'
      element.path('file_size_condition')[:unit] = 'Kb'
      provider.size.should == '6K'
    end

    it "should return the correct value if type is lt" do
      element.path('file_size_condition')[:limit] = '22'
      element.path('file_size_condition')[:type] = 'lt'
      element.path('file_size_condition')[:unit] = 'Kb'
      provider.size.should == '< 22K'
    end

    it "should return the correct value if type is le" do
      element.path('file_size_condition')[:limit] = '9'
      element.path('file_size_condition')[:type] = 'le'
      element.path('file_size_condition')[:unit] = 'Kb'
      provider.size.should == '<= 9K'
    end

    it "should return the correct value if type is gt" do
      element.path('file_size_condition')[:limit] = '23'
      element.path('file_size_condition')[:type] = 'gt'
      element.path('file_size_condition')[:unit] = 'Kb'
      provider.size.should == '> 23K'
    end

    it "should return the correct value if type is ge" do
      element.path('file_size_condition')[:limit] = '86'
      element.path('file_size_condition')[:type] = 'ge'
      element.path('file_size_condition')[:unit] = 'Kb'
      provider.size.should == '>= 86K'
    end

    it "should return the correct value if unit is Kb" do
      element.path('file_size_condition')[:limit] = '86'
      element.path('file_size_condition')[:type] = 'ge'
      element.path('file_size_condition')[:unit] = 'Kb'
      provider.size.should == '>= 86K'
    end

    it "should return the correct value if unit is Mb" do
      element.path('file_size_condition')[:limit] = '86'
      element.path('file_size_condition')[:type] = 'ge'
      element.path('file_size_condition')[:unit] = 'Mb'
      provider.size.should == '>= 86M'
    end

    it "should return the correct value if unit is Gb" do
      element.path('file_size_condition')[:limit] = '86'
      element.path('file_size_condition')[:type] = 'ge'
      element.path('file_size_condition')[:unit] = 'Gb'
      provider.size.should == '>= 86G'
    end

    it "should set type to eq if new value has no prefix" do
      element.path('file_size_condition').expects(:[]=).with(:limit, '23')
      element.path('file_size_condition').expects(:[]=).with(:type, 'eq')
      element.path('file_size_condition').expects(:[]=).with(:unit, 'Kb')

      provider.size = '23K'
    end

    it "should set type to lt if new value has prefix <" do
      element.path('file_size_condition').expects(:[]=).with(:limit, '11')
      element.path('file_size_condition').expects(:[]=).with(:type, 'lt')
      element.path('file_size_condition').expects(:[]=).with(:unit, 'Kb')

      provider.size = '<11K'
    end

    it "should set type to le if new value has prefix <=" do
      element.path('file_size_condition').expects(:[]=).with(:limit, '29')
      element.path('file_size_condition').expects(:[]=).with(:type, 'le')
      element.path('file_size_condition').expects(:[]=).with(:unit, 'Mb')

      provider.size = '<=29M'
    end

    it "should set type to gt if new value has prefix >" do
      element.path('file_size_condition').expects(:[]=).with(:limit, '47')
      element.path('file_size_condition').expects(:[]=).with(:type, 'gt')
      element.path('file_size_condition').expects(:[]=).with(:unit, 'Gb')

      provider.size = '>47G'
    end

    it "should set type to ge if new value has prefix >=" do
      element.path('file_size_condition').expects(:[]=).with(:limit, '71')
      element.path('file_size_condition').expects(:[]=).with(:type, 'ge')
      element.path('file_size_condition').expects(:[]=).with(:unit, 'Kb')

      provider.size = '>=71K'
    end

    it "should ignore spaces between prefix, value and unit" do
      element.path('file_size_condition').expects(:[]=).with(:limit, '23')
      element.path('file_size_condition').expects(:[]=).with(:type, 'gt')
      element.path('file_size_condition').expects(:[]=).with(:unit, 'Mb')

      provider.size = '> 23 M'
    end
  end

  describe "when managing size_type" do
    it "should return :individual when file_size_type is set to \"individual\"" do
      element[:file_size_type] = 'individual'
      provider.size_type.should == :individual
    end

    it "should return :smallest when file_size_type is set to \"smallest\"" do
      element[:file_size_type] = 'smallest'
      provider.size_type.should == :smallest
    end

    it "should return :largest when file_size_type is set to \"largest\"" do
      element[:file_size_type] = 'largest'
      provider.size_type.should == :largest
    end

    it "should set file_size_type to \"individual\" when new value is :individual" do
      element.expects(:[]=).with(:file_size_type, 'individual')
      provider.size_type = :individual
    end

    it "should set file_size_type to \"smallest\" when new value is :smallest" do
      element.expects(:[]=).with(:file_size_type, 'smallest')
      provider.size_type = :smallest
    end

    it "should set file_size_type to \"largest\" when new value is :largest" do
      element.expects(:[]=).with(:file_size_type, 'largest')
      provider.size_type = :largest
    end
  end

  describe "when managing size_action" do
    it "should return the file_size_command field" do
      element[:file_size_command] = '/bin/gzip "$file"'
      provider.size_action.should == '/bin/gzip "$file"'
    end

    it "should update the file_size_command field with the new value" do
      element.expects(:[]=).with(:file_size_command, '/bin/rm -f "$file"')
      provider.size_action = '/bin/rm -f "$file"'
    end
  end
end
