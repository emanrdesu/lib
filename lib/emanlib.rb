require_relative "patch/define"
require_relative "patch/enum"
require_relative "patch/foobar"
require_relative "patch/lambda"

module EmanLib
  # The identity Lambda object (`_`).
  # Store in a short variable, and use it as a building block for anonymous functions.
  #
  #     _ = EmanLib._
  #     [1, 2, 3].map(&_.succ) => [2, 3, 4]
  #     [[1, 2], [3, 4]].map(&(_ + _).lift) => [3, 7]
  _ = Lambda.new

  # Helper method to create definitions.
  # A convenient shorthand for `Object.new.define(...)`.
  #
  # @param args [Array<Hash, Array>] A list of Hashes or "hashy" Arrays.
  # @param block [Proc] If provided, its local variables are used to define methods.
  # @return [Object] A new object with dynamically defined methods.
  #
  # @see [Object#define]
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
    Object.new.define(*args, &block)
  end

  # Support for using a `_` as the second operand with operators.
  # WARN: This method WILL MODIFY the standard library classes.
  # In particular, the operators: `- * / % ** & | ^ << >> <=> == === != > < >= <=`
  # in the classes: `Integer, Float, Rational, Complex, Array, String, Hash, Range, Set`
  def support_lambda
    [[Integer, Float, Rational, Complex, Array, String, Hash, Range, Set],
     %i[- * / % ** & | ^ << >> <=> == === != > < >= <=]].op(:product)
      .each do |klass, op|
      next unless klass.instance_methods(false).include?(op)

      original = klass.instance_method(op)
      klass.define_method(op) do |other|
        if other.is_a?(Lambda)
          repr = [self]
          repr.concat(other.repr)
          repr << Lambda::Function.new(op)
          Lambda.new(repr)
        else
          original.bind(self).call(other)
        end
      end
    end
  end

  module_function :let, :support_lambda
end
