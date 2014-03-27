require 'benchmark'
require 'multi_def'

MultiDef.autoinclude

class Klass
  multi_def(:hash_guard) do
    match() do
      "render_default"
    end
    match(+{:partial => String}) do
      "render_partial"
    end
    match(+{:action => String}) do
      "render_action"
    end
    match(+{:template => String}) do
      "render_template"
    end
    match(+{:text => String}) do
      "render_text"
    end
    match(+{:dont_care => __}) do
      "render_dont_care"
    end
  end

  multi_def(:fac) do
    match(0) { 1 }
    match(->(a){a > 0}) {|n| n * fac(n-1)}
  end
end


class Klass2
  def hash_guard(arg = {})
    if arg == {}
      "render_default"
    elsif a = arg[:partial] && a.kind_of?(String)
      "render_partial"
    elsif a = arg[:action] && a.kind_of?(String)
      "render_action"
    elsif a = arg[:template] && a.kind_of?(String)
      "render_template"
    elsif a = arg[:text] && a.kind_of?(String)
      "render_text"
    elsif a = arg[:dont_care]
      "render_dont_care"
    end
  end

  def fac(n)
    n == 0 ? 1 : (n*fac(n-1))
  end
end


n = 1000
k = Klass.new
j = Klass2.new

Benchmark.bmbm do |x|

  x.report("hash_guard case") { 
    n.times do 
      j.hash_guard()
      j.hash_guard(:partial => "bla")
      j.hash_guard(:action => "bla")
      j.hash_guard(:template => "bla")
      j.hash_guard(:text => "bla")
      j.hash_guard(:dont_care => Object.new)
    end
  }

  x.report('fac straight forward') {
    n.times do
      j.fac(20)
    end
  }

  x.report("hash_guard matcher") { 
    n.times do 
      k.hash_guard()
      k.hash_guard(:partial => "bla")
      k.hash_guard(:action => "bla")
      k.hash_guard(:template => "bla")
      k.hash_guard(:text => "bla")
      k.hash_guard(:dont_care => Object.new)
    end
  }
  x.report("fac matcher"){
    n.times do 
      k.fac(20)
    end
  }
end