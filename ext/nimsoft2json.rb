#!/usr/bin/ruby

require 'puppet'
require 'puppet/util/nimsoft_config'
require 'puppet/util/nimsoft_section'

require 'rubygems'
require 'json'

configfile = ARGV[0]

config = Puppet::Util::NimsoftConfig.add(configfile)
config.tabsize = 2
config.parse

class Puppet::Util::NimsoftConfig
  def to_new_cfg
    child('PROBE').to_new_cfg
  end
end

class Puppet::Util::NimsoftSection
  def to_new_cfg
    res = nil
    if parent.name == 'PROBE' and %w{USERS TEMPLATES SYSTEMS LANDSCAPES}.include? name
      res = []
      @children.each { |c| res << c.to_new_cfg }
    elsif parent.name =~ /LANDSCAPE\d+/ and name == 'SYSTEMS'
      res = values_in_order.map(&:to_i)
    elsif parent.name =~ /SYSTEM\d+/ and name == 'TEMPLATES'
      res = values_in_order.map(&:to_i)
    elsif parent.name =~ /SYSTEM\d+/ and name == 'INSTANCE_IPS'
      res = values_in_order
    elsif parent.name =~ /TEMPLATE\d+/ and name == 'JOBS'
      res = values_in_order.map(&:to_i)
    else
      res = {}
      @attributes.each_pair do |key,value|
        if key == :VERSION and name =~ /TEMPLATE\d+/
          res[key.to_s] = '2.0'
        elsif key == :LANGUAGE and name =~ /SYSTEM\d+/
        else
          res[key.to_s] = value
        end
      end
      @children.each do |c| 
        if name == 'PROBE' and c.name == 'SYSTEMS'
          res['CONNECTORS'] = c.to_new_cfg
        elsif name == 'PROBE' and c.name == 'LANDSCAPES'
          res['SYSTEMS'] = c.to_new_cfg
        elsif name == 'PROBE' and c.name =='USERS'
          res['USER_PROFILES'] = c.to_new_cfg
        elsif name =~ /LANDSCAPE\d+/ and c.name == 'SYSTEMS'
          res['CONNECTORS'] = c.to_new_cfg
        elsif name =~ /TEMPLATE\d+/ and c.name == 'MONITORS'
        elsif name =~ /TEMPLATE\d+/ and c.name == 'CUSTO'
          res['CUSTOMIZATION'] = c.to_new_cfg
        elsif name == 'CUSTO' and c.name =~ /JOB166/ and c.child('PARAMETER_VALUES')
          res["166"] = c.to_new_cfg
          res["166"]["ID"] = res["166"]["ID"].to_i
          parameters = c.child('PARAMETER_VALUES')
          res["166"]["PARAMETERS"] = []
          [ :INDEX000, :INDEX001, :INDEX002 ].each do |index|
            if value = parameters[index]
              res["166"]["PARAMETERS"] << {
                "IDX"             => index.to_s[-1],
                "PARAMETER_VALUE" => value,
              }
            end
          end
          res["166"].delete("PARAMETER_VALUES")
        elsif name == 'CUSTO' and c.name =~ /JOB177/ and c.child('EXPECTED_INSTANCES')
          instances = c.child("EXPECTED_INSTANCES").values_in_order
          autoclear = c.child("AUTO_CLEARS").values_in_order
          severity = c.child('CRITICITIES').values_in_order
          mandatory = c.child('MANDATORY_INSTANCES').values_in_order
          c.children.delete(c.child('EXPECTED_INSTANCES'))
          c.children.delete(c.child('AUTO_CLEARS'))
          c.children.delete(c.child('CRITICITIES'))
          c.children.delete(c.child('MANDATORY_INSTANCES'))
          res["177"] = c.to_new_cfg
          res["177"]["Default"] = []
          instances.each_with_index do |instance, index|
            res["177"]["Default"] << {
              "IDX"      => index.to_s,
              "SEVERITY" => severity[index] || "5",
              "EXPECTED_INSTANCES" => instance,
              "AUTOCLEAR" => autoclear[index] || "true",
              "MANDATORY" => mandatory[index] || "true"
            }
          end

        elsif name == 'CUSTO' and c.name =~ /JOB(\d+)/
          res[$1] = c.to_new_cfg
        else
          res[c.name] = c.to_new_cfg
        end
      end
    end

    if parent.name == 'SYSTEMS' and name =~ /SYSTEM\d+/
      res["SNC_MODE"] = "false"
      res["SNC_QUALITY_PROTECTION"] = "3"
    end

    res
  end
end

puts JSON.pretty_generate(config.to_new_cfg)
