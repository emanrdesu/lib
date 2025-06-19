module Kernel
  # The Enum module provides a factory method `[]` to dynamically create
  # simple, lightweight enum-like classes. These classes allow defining a set of
  # named constants with associated numeric values.
  #
  # Enums are defined by passing symbols, strings, or hashes to the `[]` method.
  #
  # Usage examples:
  #   OS = Enum[:Arch, :BSD] # OS.Arch => 0, OS.BSD => 1
  #   Bool = Enum[nil: 1, :t 10] # Bool.nil => 1, Bool.t => 10
  #   Way = Enum["↑", { ↓: 50 }, :→ ] # Way.↑ => 0, Way.↓ => 50, Way.→ => 51
  #   Pet = Enum[:Dog, :Cat] { |v| 0.5 * v } # Pet.Dog => 0.0, Pet.Cat => 0.5
  #
  # The generated enum class provides:
  # * Class methods to access each constant's value (e.g., `Way.↑`).
  # * A `size` method to get the number of defined constants.
  # * An `each` class method to iterate over value-name pairs.
  # * A `to_h` class method to get a hash of name-value pairs.
  module Enum
    def self.[](*args, &block)
      # At least one argument should be provided
      raise ArgumentError, "Enums must have at least one constant" if args.empty?

      # Initialize tracking variables
      pairs = {}
      current = 0

      args.flatten!(1)

      # Process all arguments to extract name-value pairs
      args.each do |arg|
        current = case arg
          when Symbol, String
            # Single enum value - assign current value and increment
            pairs[arg.to_sym] = current
            current + 1
          when Hash
            # Hash with explicit key-value mapping
            arg.each do |key, value|
              unless key.is_a?(Symbol) || key.is_a?(String)
                raise ArgumentError, "Enum names must be Symbol|String: #{key.inspect}"
              end
              raise ArgumentError, "Enum values must be Numeric: #{value.inspect}" unless value.is_a?(Numeric)
              pairs[key.to_sym] = value
              current = value + 1
            end

            current
          else
            raise ArgumentError, "Invalid enum argument: #{arg.inspect}"
          end
      end

      # Apply block transformation if provided
      if block_given?
        values = Set.new
        pairs.each do |prop, value|
          hash = block.call(value, prop)

          # Make sure block result is Numeric
          unless hash.is_a?(Numeric)
            raise ArgumentError, "Block must return a Numeric, got #{hash.class}: #{hash.inspect}"
          end

          # Check that result is unique
          if values.include?(hash)
            raise ArgumentError, "Block must return unique values, duplicate: #{hash}"
          end

          values.add(hash)
          pairs[prop] = hash
        end
      end

      # Create enum class and include this module
      klass = Class.new
      klass.include(Enum)

      # Store enums data for instance methods
      klass.instance_variable_set(:@pairs, pairs.freeze)

      # Define getter methods for each constant
      pairs.each do |prop, value|
        begin
          klass.define_singleton_method(prop) { value }
        rescue => e
          raise ArgumentError, "Invalid const name '#{prop}': #{e.message}"
        end
      end

      klass.define_method(:initialize) do
        raise RuntimeError, "Enums are not meant to be instantiated"
      end

      # Define utility methods directly on the class
      klass.define_singleton_method(:size) do
        @pairs.size
      end

      klass.define_singleton_method(:to_h) do
        @pairs.dup
      end

      klass.define_singleton_method(:each) do |&block|
        return enum_for(:each) unless block

        @pairs.each do |prop, value|
          block.call(value, prop)
        end
      end

      klass
    end
  end
end
