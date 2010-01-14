require 'test/test_helper'

require 'multi_def'
#require 'definition_environments/default_environment'

MultiDef.autoinclude

class Klass
  def string_string(string1, string2)
    1
  end
  
  def string_fixnum(string1, number1)
    2
  end
end

class Inherited < Klass; end

context "A multidef" do
  setup do
    Klass.multi_def(:multi) do
      match String, String do
        1
      end
      
      match String, Fixnum do
        2
      end
    end
    
    Klass.new
  end
  
  asserts("String arguments yield 1") do
    topic.multi("hoge", "piyo")
  end.equals(1)
  
  asserts("String and Fixnum arguments yield 2") do
    topic.multi("hoge", 1)
  end.equals(2)
  
  asserts("String and Double arguments error") do
    topic.multi("hoge", 1.0)
  end.raises(NoMethodError)
end

context "A guard using repond_to" do
  setup do
    Klass.multi_def(:respond_to_guard) do
      match -:+&-:concat do |arg|
        1
      end
    end
    
    Klass.new
  end
  
  asserts("Strings are accepted") do   
    topic.respond_to_guard("String")
  end.equals(1)
  
  asserts("Doubles are not") do
    topic.respond_to_guard(1.0)
  end.raises(NoMethodError)
end

context "Proxy methods" do
  setup do
    
    Klass.multi_def(:proxy_method) do
      match String, String, &use(:string_string)
      match String, Fixnum, &use(:string_fixnum)
    end
    
    Klass.new
  end
  
  asserts("String arguments yield 1") do
    topic.multi("hoge", "piyo")
  end.equals(1)
  
  asserts("String and Fixnum arguments yield 2") do
    topic.multi("hoge", 1)
  end.equals(2)
  
  asserts("String and Double arguments error") do
    topic.multi("hoge", 1.0)
  end.raises(NoMethodError)
end

context "A metaclass definition using class << self" do
  setup do
    class << Klass
      multi_def(:meta_class_method) do
        match(String, String) do
          1
        end
        match(String, Fixnum) do
          2
        end
      end
    end
  end
  
  asserts("matches correctly") do
    Klass.meta_class_method("String", "String")
  end.equals(1)
end

context "A metaclass definition using cmulti_def" do
  setup do
    Klass.cmulti_def(:cmeta_class_method) do
      match(String, String) do
        1
      end
      match(String, Fixnum) do
        2
      end
    end
  end
  
  asserts("matches correctly") do
    Klass.cmeta_class_method("String", "String")
  end.equals(1)
end

context "An inherited definition" do
  setup do
    Klass.multi_def(:inherited_method) do
      match(String, String) do
        1
      end
      match(String, Fixnum) do
        2
      end
    end
    
    Inherited.multi_def(:inherited_method) do
      match(String, String) do
        3
      end
    end
  end
  
  asserts("is not matched by the parent class") do
    Inherited.new.inherited_method("hoge", "fuga")
  end.equals(3)
  
  asserts("is not matched when called on parent class") do
    Klass.new.inherited_method("hoge", "fuga")
  end.equals(1)
end

context "Literal values" do
  setup do
    Klass.multi_def(:fib) do
      match(0..1) do |i|
        i
      end
      
      match(Fixnum) do |i|
        fib(i-1) + fib(i-2)
      end
    end
    
    Klass.new
  end
  
  asserts("fib(0) is 0") do
    topic.fib(0)
  end.equals(0)
  
  asserts("fib(1) is 1") do
    topic.fib(1)
  end.equals(1)
  
  asserts("fib(3) is 2") do
    topic.fib(3)
  end.equals(2)
end

context "Single don't cares" do
  setup do
    Klass.multi_def(:dont_care) do
      match(String, __) do |string, foo|
        1
      end
      
    end

    Klass.new
  end
  
  asserts("cares about the first argument") do
    topic.dont_care(1, 1.0)
  end.raises(NoMethodError)
  
  asserts("does not allow only one argument") do
    topic.dont_care("hoge")
  end.raises(NoMethodError)

  asserts("does not care about the second argument") do
    topic.dont_care("hoge", 1.0)
  end.equals(1)
  
  asserts("does not allow more then 2 arguments") do
    topic.dont_care("hoge", 1.0, 1.0)
  end.raises(NoMethodError)
  
end

context "Multiple don't cares" do
  setup do
    Klass.multi_def(:multi_dont_care) do
      match(String, ___) do |string, *foo|
        foo
      end
    end
    
    Klass.new
  end
  
  asserts("cares about the first argument") do
    topic.multi_dont_care(1, 1.0)
  end.raises(NoMethodError)
  
  asserts("does not care about no further arguments") do
    topic.multi_dont_care("hoge")
  end.equals([])
  
  asserts("does not care about additional further arguments") do
    topic.multi_dont_care("hoge", 1, 2)
  end.equals([1,2])
end

context "Nested don't cares" do
  setup do
    Klass.multi_def(:dont_care_in_arrays) do
      match(+[__,:a, :b]) do |array|
        1
      end
    end
    
    Klass.new
  end
  
  asserts("do not care about the first element") do
    topic.dont_care_in_arrays([1,:a,:b])
  end.equals(1)
  
  asserts("does care about the other elements") do
    topic.dont_care_in_arrays(["hoge", "fuga"])
  end.raises(NoMethodError)
end

context "proc_guard guards" do
  setup do
    Klass.multi_def(:proc_guard) do
      match(proc {|a| a > 1}) do |number|
        number + 1
      end
      match(proc {|a| a < 1}) do |number|
        number - 1
      end
    end
    
    Klass.new
  end
  
  asserts("chooses first clause for numbers > 1") do
    topic.proc_guard(2)
  end.equals(3)
  
  asserts("chooses second clause for numbers < 1") do
    topic.proc_guard(0)
  end.equals(-1)
  
  asserts("is not implemented for 1") do
    topic.proc_guard(1)
  end.raises(NoMethodError)
end

context "regexp guards" do
  setup do
    Klass.multi_def(:regexp) do
      match(/^a.*/) { 1 }
      match(/^b.*/) { 2 }
    end
    
    Klass.new
  end
  
  asserts(%{matches first clause for "abc"}) do
    topic.regexp("abc")
  end.equals(1)
  
  asserts(%{matches second clause for "bcd"}) do
    topic.regexp("bcd")
  end.equals(2)
  
  asserts(%{no implementation for "cde"}) do
    topic.regexp("cde")
  end.raises(NoMethodError)
end

context "hash guards" do
  setup do
    Klass.multi_def(:hash_guard) do
      match() do
        "render_default"
      end
      match(+{:partial => String, __ => __}) do
        "render_partial"
      end
      match(+{:dont_care => __}) do
        "render_dont_care"
      end
    end
    
    Klass.new
  end
  
  asserts("hash_guard without argument uses first clause") do
    topic.hash_guard
  end.equals("render_default")
  
  asserts("hash_guard with :partial key uses second clause") do
    topic.hash_guard(:partial => "hoge", :other => "fuga")
  end.equals("render_partial")
  
  asserts("hash_guard with dont_care allows Fixnums") do
    topic.hash_guard(:dont_care => 1)
  end.equals("render_dont_care")
  
  asserts("hash_guard with dont_care allows Floats") do
    topic.hash_guard(:dont_care => 1.0)
  end.equals("render_dont_care")
end