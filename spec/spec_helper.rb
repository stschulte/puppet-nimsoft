require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'

class Object
  alias :must :should
  alias :must_not :should_not
end
