require 'guards/guards'
require 'guards/default_guards'

module MultiDef
  #
  # The DefaultEnvironment provides all methods to evaluate matched
  # Method definitions.
  # To have access to more advanced features, you have to include another
  # set of guards instead of the default guards.
  class DefinitionEnvironment    
    attr_accessor :obj_to_define_on, :method_name
    
    def initialize(obj,name)
      self.obj_to_define_on = obj
      self.method_name = name
    end

    # Defines a clause for a matching method using a set of patterns
    # and a clause body.
    def define_clause(*pattern, &clause_body)      
      obj_to_define_on.define_clause(self.method_name, pattern, &clause_body)
    end
    alias :match :define_clause 
    
    def use(selector)
      lambda{|*args| send(selector, *args)}
    end
    
    def __
      OB
    end
    
    def ___
      OBS
    end
  end
end