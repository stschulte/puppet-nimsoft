#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/nimsoft_section.rb'

describe Puppet::Util::NimsoftSection do

  describe "when creating a new section" do
    it "should be possible to create a section without a parent" do
      section = described_class.new('root')
      expect(section.parent).to be_nil
      expect(section.children).to be_empty
    end

    it "should add the update the children list of the parent section" do
      rootsection = described_class.new('root')
      subsection1 = described_class.new('s1', rootsection)
      subsection2 = described_class.new('s2', rootsection)

      expect(rootsection.children).to eq([ subsection1, subsection2 ])

      expect(subsection1.parent).to eq(rootsection)
      expect(subsection1.children).to be_empty

      expect(subsection2.parent).to eq(rootsection)
      expect(subsection2.children).to be_empty
    end
  end

  describe "to_cfg" do
    it "should list the attributes in the order they were inserted" do
      section = described_class.new('root')
      section[:a] = 'value1'
      section[:z] = 'value2'
      section[:b] = 'value3'
      expect(section.to_cfg).to eq(<<'EOS')
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
      expect(section.to_cfg(2, 0)).to eq(<<'EOS')
<root>
  a = value1
</root>
EOS
    end

    it "should indent the section when specified" do
      section = described_class.new('root')
      section[:a] = 'value1'
      expect(section.to_cfg(3, 1)).to eq(<<'EOS')
   <root>
      a = value1
   </root>
EOS
      expect(section.to_cfg(3, 2)).to eq(<<'EOS')
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
      expect(section.to_cfg).to eq(<<'EOS')
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

      expect(section[:a]).to be_nil
      expect(section.to_cfg).to eq(<<'EOS')
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

      expect(section[:a]).to eq('value1')
      expect(section[:b]).to eq('value2')
      expect(section[:c]).to be_nil
      expect(section.to_cfg).to eq(<<'EOS')
<root>
   a = value1
   b = value2
</root>
EOS
    end
  end

  describe "keys_in_order" do
    it "should return an empty array if section has no attributes" do
      section = described_class.new('root')
      expect(section.keys_in_order).to be_empty
    end

    it "should return the keys in the correct order" do
      section = described_class.new('root')
      section[:first] = 'foo'
      section[:second] = 'bar'
      section[:remove_later] = '123'
      section[:third] = 'baz'
      section.del_attr(:remove_later)
      expect(section.keys_in_order).to eq([:first, :second, :third ])
    end
  end

  describe "values_in_order" do
    it "should return an empty array if section has no attributes" do
      section = described_class.new('root')
      expect(section.values_in_order).to be_empty
    end

    it "should return the values in the correct order" do
      section = described_class.new('root')
      section[:first] = 'foo'
      section[:second] = 'bar'
      section[:remove_later] = '123'
      section[:third] = 'baz'
      section.del_attr(:remove_later)
      expect(section.values_in_order).to eq(%w{foo bar baz})
    end
  end

  describe "path" do
    it "should return self when no path is given" do
      section = described_class.new('root')
      expect(section.path(nil)).to eq(section)
    end

    it "should return the corresponding subsection" do
      section = described_class.new('root')
      s1 = described_class.new('level1_child1', section)

      expect(section.path('level1_child1')).to eq(s1)
    end

    it "should be possible to access a nested subsection" do
      section = described_class.new('root')
      l1c1 = described_class.new('level1_child1', section)
      l1c2 = described_class.new('level1_child2', section)
      l2c1 = described_class.new('level2_child1', l1c1)
      l3c1 = described_class.new('level3_child1', l2c1)

      expect(section.path('level1_child1/level2_child1/level3_child1')).to eq(l3c1)
    end

    it "should create missing sections" do
      section = described_class.new('root')
      expect(section.children).to be_empty

      child = section.path('level1')
      expect(child.parent).to eq(section)
      expect(section.children[0]).to eq(child)
    end
  end
end
