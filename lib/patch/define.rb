# frozen_string_literal: true

# Enhances the Binding class to easily extract local variables into a Hash.
class Binding
  # Converts the local variables accessible from this binding into a Hash.
  # The keys of the hash are the variable names (as Symbols), and the values
  # are the corresponding variable values.
  #
  # @return [Hash<Symbol, Object>] A hash mapping local variable names to their values.
  #
  # @example
  #   def my_method
  #     a = 10
  #     b = "hello"
  #     binding.variables # => {:a=>10, :b=>"hello"}
  #   end
  def variables
    Hash[
      local_variables.map do |var|
        [var, local_variable_get(var)]
      end
    ]
  end
end

# Enhances the Array class with a utility method to check its structure.
class Array
  # Checks if the array is "hashy", meaning it consists entirely of
  # two-element arrays. This structure is suitable for conversion to a Hash
  # using `to_h`.
  #
  # @return [Boolean] `true` if the array is "hashy", `false` otherwise.
  #
  # @example
  #   [[:a, 1], [:b, 2]].hashy?  # => true
  #   [["key1", "value1"]].hashy? # => true
  #   [[1, 2, 3], [:b, 2]].hashy? # => false (first item has 3 elements)
  #   [1, 2, 3].hashy?            # => false (items are not arrays)
  #   [[], [:a, 1]].hashy?       # => false (first item is not a 2-element array)
  def hashy?
    all? { |item| item.is_a?(Array) && item.size == 2 }
  end
end

# Enhances the String class with validation for method and variable names.
class String
  # Checks if the string is a valid Ruby method or variable name.
  #
  # Valid method names can include letters, numbers, underscores, and may
  # end with `!`, `=`, or `?`.
  # Valid variable names can include letters, numbers, and underscores but
  # cannot end with `!`, `=`, or `?`.
  #
  # @param target [:method, :variable] Specifies whether to validate as a method
  #   name or a variable name. Defaults to `:method`.
  # @return [Boolean] `true` if the string is a valid name for the specified target,
  #   `false` otherwise.
  #
  # @example
  #   "my_method".valid_name?                # => true
  #   "my_method?".valid_name?               # => true
  #   "setter=".valid_name?                 # => true
  #   "_private_method!".valid_name?         # => true
  #   "ConstantLike".valid_name?             # => true
  #   "1invalid".valid_name?                 # => false (starts with a number)
  #   "invalid-name".valid_name?             # => false (contains hyphen)
  #
  #   "my_variable".valid_name?(target: :variable) # => true
  #   "_var".valid_name?(target: :variable)        # => true
  #   "my_variable?".valid_name?(target: :variable)# => false (ends with ?)
  #   "A_CONSTANT".valid_name?(target: :variable)  # => true
  def valid_name?(target: :method)
    case target
    when :method
      self =~ /\A[a-zA-Z_]\w*[!?=]?\z/
    when :variable
      self =~ /\A[a-zA-Z_]\w*\z/
    else
      false
    end
  end
end

# Enhances the base Object class to allow dynamic definition of properties
class Object
  # Dynamically defines properties on `self`,
  # based on the provided arguments and/or block.
  #
  # Arguments can be Hashes or "hashy" Arrays (arrays of `[key, value]` pairs).
  # If a block is given, its local variables are also used to define methods.
  # Keys are converted to symbols and validated as method names.
  #
  # If a value is a Hash or a "hashy" Array, it's recursively
  # used to define nested properties.
  #
  # @param `args` [Array<Hash, Array>] A list of Hashes or "hashy" Arrays.
  #   Each key-value pair will result in a getter and setter method.
  # @param `block` [Proc] If provided, `block.call` is expected to return a `Binding`
  #   (i.e. last expression in the block must be `binding`).
  #   Local variables from this binding will be used to define methods.
  #
  # @return [self] The object itself, now with the newly defined methods.
  #
  # @raise [ArgumentError] If an argument is not a Hash or a "hashy" Array.
  # @raise [ArgumentError] If a key is not a valid method name.
  #
  # @example Defining with a Hash
  #   # let(...) === Object.new.define(...)
  #
  #   person = let(name: "Alice", age: 30)
  #   person.name # => "Alice"
  #   person.age = 31
  #   person.age # => 31
  #
  # @example Defining with a "hashy" Array
  #   config = let([[:host, "localhost"], [:port, 8080]])
  #   config.host # => "localhost"
  #
  # @example Defining with a block
  #   user = let do
  #     username = "bob"
  #     active = true
  #     binding # Important: makes local variables available
  #   end
  #
  #   user.username # => "bob"
  #   user.active?  # This won't define active? automatically, but user.active
  #
  # @example Nested definitions
  #   settings = let(
  #     database: { adapter: "sqlite3", pool: 5 },
  #     logging: [[:level, "info"], [:file, "/var/log/app.log"]]
  #   )
  #   settings.database.adapter # => "sqlite3"
  #   settings.logging.level    # => "info"
  #
  # @example Combining arguments
  #   complex = let({id: 1}, [[:type, "example"]]) do
  #     description = "A complex object"
  #     status = :new
  #     binding
  #   end
  #
  #   complex.id          # => 1
  #   complex.type        # => "example"
  #   complex.description # => "A complex object"
  def define(*args, &block)
    # Stores all key-value pairs to be defined
    variable = {}

    # Process Hashes and "hashy" Arrays first
    args.each do |arg|
      case arg
      when Hash
        variable.merge!(arg)
      when Array
        raise ArgumentError, "Array should be Hash like." unless arg.hashy?
        variable.merge!(arg.to_h)
      else
        raise ArgumentError, "Invalid argument type: #{arg.class}"
      end
    end

    # Process local variables from the block
    if block_given? # If provided
      binding = block.call # The block is expected to return its binding.
      raise ArgumentError, "Block must return a Binding object." unless binding.is_a?(Binding)

      variable.merge!(binding.variables)
    end

    # Define getters and setters and store values
    variable.each do |name, value|
      name = name.to_s.to_sym
      raise ArgumentError, "Invalid name: #{name}" unless name.to_s.valid_name?(target: :method)

      # Recursively define for nested Hashes or "hashy" Arrays
      if value.is_a? Hash
        value = Object.new.define(value)
      elsif value.is_a?(Array) && value.hashy?
        value = Object.new.define(value.to_h)
      end

      # Store the original value in an instance variable
      instance_variable_set("@#{name}", value)

      define_singleton_method(name) do
        instance_variable_get("@#{name}")
      end

      define_singleton_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end

    self
  end
end
