#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/nimsoft_section.rb'

describe Puppet::Util::NimsoftSection do

  describe "when creating a new section" do
    it "should be possible to create a section without a parent" do
      section = described_class.new('root')
      section.parent.should be_nil
      section.children.should be_empty
    end

    it "should add the update the children list of the parent section" do
      rootsection = described_class.new('root')
      subsection1 = described_class.new('s1', rootsection)
      subsection2 = described_class.new('s2', rootsection)

      rootsection.children.should == [ subsection1, subsection2 ]

      subsection1.parent.should == rootsection
      subsection1.children.should be_empty

      subsection2.parent.should == rootsection
      subsection2.children.should be_empty
    end
  end

  describe "to_cfg" do
    it "should list the attributes in the order they were inserted" do
      section = described_class.new('root')
      section[:a] = 'value1'
      section[:z] = 'value2'
      section[:b] = 'value3'
      section.to_cfg.should == <<'EOS'
<root>
   a = value1
   z = value2
   b = value3
</root>
EOS
    end

    it "should use the specified tabsize for indention" do
      section = described_class.new('root')
      section[:a] = 'value1'
      section.to_cfg(2, 0).should == <<'EOS'
<root>
  a = value1
</root>
EOS
    end

    it "should indent the section when specified" do
      section = described_class.new('root')
      section[:a] = 'value1'
      section.to_cfg(3, 1).should == <<'EOS'
   <root>
      a = value1
   </root>
EOS
      section.to_cfg(3, 2).should == <<'EOS'
      <root>
         a = value1
      </root>
EOS
    end

    it "should print all subcategories" do
      section = described_class.new('root')
      subsection1 = described_class.new('s1', section)
      subsection2 = described_class.new('s2', section)
      subsection1[:s1a] = 'some_value'
      subsection1[:s2a] = 'some_other_value'
      subsection2[:key3] = 'next key'
      section[:foo] = 'bar'
      section.to_cfg.should == <<'EOS'
<root>
   foo = bar
   <s1>
      s1a = some_value
      s2a = some_other_value
   </s1>
   <s2>
      key3 = next key
   </s2>
</root>
EOS
    end
  end

  describe "del_attr" do
    it "should remove an attribute" do
      section = described_class.new('root')
      section[:a] = 'value1'
      section[:b] = 'value2'
      section.del_attr(:a)

      section[:a].should be_nil
      section.to_cfg.should == <<'EOS'
<root>
   b = value2
</root>
EOS
    end

    it "should do nothing if attribute does not exist" do
      section = described_class.new('root')
      section[:a] = 'value1'
      section[:b] = 'value2'
      section.del_attr(:c)

      section[:a].should == 'value1'
      section[:b].should == 'value2'
      section[:c].should be_nil
      section.to_cfg.should == <<'EOS'
<root>
   a = value1
   b = value2
</root>
EOS
    end
  end

  describe "path" do
    it "should return self when no path is given" do
      section = described_class.new('root')
      section.path(nil).should == section
    end

    it "should return the corresponding subsection" do
      section = described_class.new('root')
      s1 = described_class.new('level1_child1', section)

      section.path('level1_child1').should == s1
    end

    it "should be possible to access a nested subsection" do
      section = described_class.new('root')
      l1c1 = described_class.new('level1_child1', section)
      l1c2 = described_class.new('level1_child2', section)
      l2c1 = described_class.new('level2_child1', l1c1)
      l3c1 = described_class.new('level3_child1', l2c1)

      section.path('level1_child1/level2_child1/level3_child1').should == l3c1
    end

    it "should create missing sections" do
      section = described_class.new('root')
      section.children.should be_empty

      child = section.path('level1')
      child.parent.should == section
      section.children[0].should == child
    end
  end


end
