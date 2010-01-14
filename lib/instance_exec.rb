# Object-level monkeypatches required for the use of Patterns.
# Only included when necessary.
class Object
  # This is an empty Module required bei instance_exec to provide its magic.
  module InstanceExecHelper; end
  include InstanceExecHelper
  
  # This is the eigenclass version of instance_exec for ruby 1.8. This is used
  # in the case that the runtime system does not provide #instance_exec already.
  def instance_exec(*args, &block)
    begin
      old_critical, Thread.critical = Thread.critical, true
      n = 0
      n += 1 while respond_to?(mname="__instance_exec#{n}")
      InstanceExecHelper.module_eval{ define_method(mname, &block) }
    ensure
      Thread.critical = old_critical
    end
    begin
      ret = send(mname, *args)
    ensure
      InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
    end
    ret
  end
end
