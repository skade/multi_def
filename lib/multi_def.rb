#require 'methopara'
require 'reg'
require 'multi_def/definition_environment'

# This library requires some kind of #instance_exec implementation.
# If there is none, we use our own.
unless respond_to?(:instance_exec)
  require 'instance_exec'
end


# MultiDef is a library to provide simple but powerful pattern matching written 
# in pure Ruby using Reg.

module MultiDef
  
  # Defines a single clause for the method of the given name. If no such method
  # exists, it will be created.
  # pattern_type should be a subclass of Pattern or anything that behaves like
  # a match pattern.
  # pattern is a list of elements to match for. These can be of any kind and will
  # be converted to Guards.
  def define_clause(name, pattern, &method_body)
    instance_variable_name = :"@#{name}_implementations"

    unless instance_variable_get(instance_variable_name)
      create_match_method(name)
    end
    
    instance_variable_get(instance_variable_name) << [+pattern, method_body]
  end
  
  # Creates a matching method. When called, it sets a instance variable holding all
  # known clauses of a method. 
  # Then, it creates a method with the given name that holds the lookup and matching code.
  def create_match_method(name)
    
    instance_variable_name = :"@#{name}_implementations"
    
    instance_variable_set(instance_variable_name, [])
    klass = self
    
    define_method(name) do |*arguments|
      clauses = klass.instance_variable_get(instance_variable_name)
      pattern, proc = clauses.find do |pattern, proc| 
        pattern === arguments
      end
      
      unless proc
        begin
          super(*arguments)
        rescue NoMethodError => e
          patterns = clauses.map(&:first)
          raise NoMethodError.new("There is no Method matching these Arguments: #{arguments.inspect}, available patterns: #{patterns.inspect}")
        end
      else
        instance_exec(*arguments, &proc)
      end
      
    end
  end
  
  # Evaluates a block with clause definitions within the given DefinitionEnvironment.
  # By default, the DefinitionEnvironment is the standard environment for the
  # object this method is called on.
  def multi_def(name, &definitions)   
    env = DefinitionEnvironment.new(self, name)     
    env.instance_eval(&definitions)
  end
  
  def cmulti_def(name, &definitions)
    c = class << self; self; end;
    
    env = DefinitionEnvironment.new(c, name)
    env.instance_eval(&definitions)
  end
  
  # Includes the MultiDef Module within every Object. Otherwise, it has to be included
  # in every Object that uses matched methods.
  def self.autoinclude()
    Module.send(:include, self)
  end
end
