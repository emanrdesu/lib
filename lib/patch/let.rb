# frozen_string_literal: true

# Enhances the Binding class to easily extract local variables into a Hash.
class Binding
  # Converts the local variables accessible from this binding into a Hash.
  # The keys of the hash are the variable names (as Symbols), and the values
  # are the corresponding variable values.
  #
  # @return (Symbol to Object) {} - A hash mapping local variable names to their values
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
  #   [[], [:a, 1]].hashy?       # => false (first item is empty)
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
  # @param target [[:method, :variable, :var]] Whether to validate as a method
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
  #   "my_variable".valid_name?(:variable) # => true
  #   "_var".valid_name?(:variable)        # => true
  #   "my_variable?".valid_name?(:variable)# => false (ends with ?)
  #   "A_CONSTANT".valid_name?(:variable)  # => true
  def valid_name?(target = :method)
    case target
    when :method
      self =~ /\A[a-zA-Z_]\w*[!?=]?\z/
    when :var, :variable
      self =~ /\A[a-zA-Z_]\w*\z/
    else
      false
    end
  end
end

module EmanLib
  # A convenient shorthand for `Maplet.new.define!(...)`.
  #
  # @param args [Array<Hash, Array>] A list of Hashes or "hashy" Arrays.
  # @param block [Proc] If provided, its local variables are used to define methods.
  # @return [Object] A new object with dynamically defined methods.
  #
  # @see [Maplet#define!]
  #
  # @example
  #   person = let(name: "Rio", age: 37)
  #   puts person.name # => "Rio"
  #   puts person.age  # => 37
  #
  #   point = let **{x: 10, y: 20}
  #   puts point.x # => 10
  #
  #   settings = let do
  #     theme = "dark"
  #     font_size = 12
  #     binding
  #   end
  #   puts settings.theme # => "dark"
  #
  #   complex_data = let([[:id, 42]], name: "Xed") do
  #     details = { color: "red", size: "large" }
  #     binding # Required
  #   end
  #
  #   puts complex_data.id            # => 42
  #   puts complex_data.name          # => "Xed"
  #   puts complex_data.details.color # => "red"
  def let(*args, &block)
    Maplet.new.define!(*args, &block)
  end

  module_function :let

  # Class that allows for dynamic definition of properties
  class Maplet
    include Enumerable

    def initialize
      @props = []
    end

    # Dynamically defines properties based on the provided arguments and/or block.
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
    #   # let(...) === Maplet.new.define!(...)
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
    def define!(*args, &block)
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
      if block_given?
        binding = block.call # The block is expected to return its binding.
        raise ArgumentError, "Block must return a Binding object." unless binding.is_a?(Binding)

        variable.merge!(binding.variables)
      end

      # Define getters and setters and store values
      variable.each do |prop, value|
        prop = prop.to_s.to_sym
        raise ArgumentError, "Invalid name: #{prop}" unless prop.to_s.valid_name?

        # Recursively define for nested Hashes or "hashy" Arrays
        if value.is_a? Hash
          value = Maplet.new.define!(value)
        elsif value.is_a?(Array) && value.hashy?
          value = Maplet.new.define!(value.to_h)
        end

        # Store the original value in an instance variable
        instance_variable_set("@#{prop}", value)

        define_singleton_method(prop) do
          instance_variable_get("@#{prop}")
        end

        define_singleton_method("#{prop}=") do |value|
          instance_variable_set("@#{prop}", value)
        end
      end

      @props += variable.keys.map(&:to_sym)
      self
    end

    # Accesses a prop's value, allowing for nested access.
    #
    # @param prop [Array<Symbol, String>] A sequence of prop names to access.
    # @return [Object] The value of the specified property.
    #
    # @raise [ArgumentError] If no prop is given or does not exist.
    #
    # @example Accessing top-level and nested properties
    #   settings = let(
    #     host: "localhost",
    #     database: { adapter: "sqlite3", pool: 5 }
    #   )
    #
    #   settings[:host]                # => "localhost"
    #   settings[:database]            # => <EmanLib::Maplet ...>
    #   settings[:database, :adapter]  # => "sqlite3"
    #   settings[:database, :pool]     # => 5
    def [](*prop)
      raise ArgumentError, "No property specified." if prop.empty?
      value = instance_variable_get("@#{prop.first}")

      if prop.size == 1
        value
      else
        value[*prop[1..]]
      end
    rescue NameError
      error = "Property '#{prop.join ?.}' is not defined in this Maplet."
      error += " Available properties: [#{@props.join(", ")}]"
      raise ArgumentError, error
    end

    # Converts the Maplet and any nested Maplets back into a Hash.
    # Recursively transforms inner maplets into nested Hashes.
    #
    # @return [Hash{Symbol => Object}] A hash representation of the Maplet.
    #
    # @example
    #   settings = let(host: 'localhost', db: { name: 'dev', pool: 5 })
    #   settings.to_h # => { host: "localhost", db: { name: "dev", pool: 5 } }
    def to_h
      @props.each_with_object({}) do |prop, hash|
        value = self[prop]

        if value.is_a?(Maplet)
          hash[prop] = value.to_h
        else
          hash[prop] = value
        end
      end
    end

    # Iterates over each leaf property of the Maplet.
    #
    # @yield [value, path] Gives the value and its full access path.
    # @yieldparam value [Object] The value of the leaf property.
    # @yieldparam path [String] The dotted path to the prop (e.g., `"dir.home"`).
    #
    # @return [self, Enumerator] Self if a block is given, otherwise an Enumerator.
    #
    # @example
    #   user = let(name: 'Ian', meta: { role: 'Admin', active: true })
    #   user.each { |value, path| puts "#{path}: #{value}" }
    #   # Prints:
    #   # name: Ian
    #   # meta.role: Admin
    #   # meta.active: true
    def each(&block)
      return enum_for(:each) unless block_given?

      tap do
        @props.each do |prop|
          value = self[prop]
          if value.is_a?(Maplet)
            value.each do |inner, nested|
              yield inner, "#{prop}.#{nested}"
            end
          else
            yield value, prop.to_s
          end
        end
      end
    end

    # Creates a new Maplet by applying a block to each property's value.
    # You can transform all properties or just a select few.
    #
    # @param only [Array<Symbol, String>] Optional. A list of top-level property
    #   names to transform. If provided, other properties are copied as-is.
    # @yield [value, prop] The block to apply to each selected property.
    # @yieldparam value [Object] The value of the property.
    # @yieldparam prop [String] The name of the property.
    #
    # @return [Maplet] A new Maplet with the transformed values.
    #
    # @example Transforming all numeric values
    #   config = let(port: 80, timeout: 3000, host: "localhost")
    #   doubled = config.map do |value, _|
    #     value.is_a?(Numeric) ? value * 2 : value
    #   end
    #   doubled.to_h # => { port: 160, timeout: 6000, host: "localhost" }
    #
    # @example Transforming only a specific property
    #   config = let(port: 80, host: "localhost")
    #   upcased = config.map(:host) { |val, _| val.upcase }
    #   upcased.to_h # => { port: 80, host: "LOCALHOST" }
    def map(*only, &block)
      return enum_for(:map) unless block_given?
      hash = {}

      @props.each do |prop|
        value = self[prop]
        if value.is_a?(Maplet)
          hash[prop] = value.map(*only, &block)
        elsif only.empty?
          hash[prop] = yield(value, prop)
        elsif only.any? { |p| p.to_sym == prop }
          hash[prop] = yield(value, prop)
        else
          hash[prop] = value
        end
      end

      Maplet.new.define!(hash)
    end

    # Returns a new Maplet that excludes the specified top-level properties.
    # Note: This only works on top-level properties.
    #
    # @param props [Array<Symbol, String>] A list of property names to exclude.
    # @return [Maplet] A new Maplet instance without the specified properties.
    #
    # @example
    #   user = let(id: 1, name: 'Tico', email: 'tico@example.com')
    #
    #   user_public_data = user.without(:id)
    #   user_public_data.to_h # => { name: "Tico", email: "tico@example.com" }
    def without(*props)
      return self if props.empty?

      remaining = to_h
      props.each { |p| remaining.delete(p.to_sym) }

      Maplet.new.define!(remaining)
    end
  end
end
