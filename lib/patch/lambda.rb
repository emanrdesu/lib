# frozen_string_literal: true

# Monkey patches for use in `Lambda`
class Array
  # Allows for this:
  # -  `[1, 2, 3].op(:+) # => 6`
  # -  `[1, 2, 3].op(:-) # => -4`
  #
  # Not the same as [reduce] or [inject]
  # The `method` argument is supposed to be an instance method
  # for the first element of the array.
  def op(method)
    first.send(method, slice(1..))
  end

  # Same as [Array#pop] but returns `default` if the array is empty.
  def qoq(default = nil)
    empty? ? default : pop
  end
end

module Kernel

  # A Lambda object (`_`) is building block for anonymous functions.
  # For instance, (`_ + _`) represents f(x,y) = x + y
  # (`_ * 2`) represents f(x) = 2x.
  # You can use any method or operator on a `_`, and it will work:
  # -   `[1, 2].map(&_.succ ** 3)      => [8, 27]`
  # -   `[[1,2], [3,4]].map(&_.sum / 2)  => [1.5, 3.5]`
  #
  # The `lift` method allows a `_` to be used like so:
  # -   `[[1, 2], [3, 4]].map(&(_ + _).lift) => [3, 7]`
  #
  # i.e. it treats the first arg (that is an array) as the actual arguments to be used
  # WARN: "lift" state is contagious (e.g. `(_ + _.lift) <=> (_ + _).lift`).
  #
  # You can similarly use [unlift] to convert a lifted `_` back to a normal.
  # [support_lambda] will allow for a _ to be used as the second operand (e.g. `2 - _`)
  #
  class Lambda < BasicObject
    class Arg; end

    class Block
      def initialize(block)
        @proc = block
      end

      def to_proc
        @proc
      end
    end

    class Function
      def initialize(method)
        @method = method
      end

      def to_proc
        @method.to_proc
      end
    end

    def __repr__; @__repr__ end
    def __tuply__; @__tuply__ end

    def initialize(repr = [Arg.new], *args)
      @__tuply__ = args.include?(:lift)
      @__repr__ = repr

      return if repr != :lift

      @__repr__ = [Arg.new]
      @__tuply__ = true
    end

    def to_proc
      ::Proc.new do |*args|
        args = args.first if @__tuply__ && args.first.is_a?(::Array)
        stack = []
        index = 0

        @__repr__.each do |element|
          case element
          when Arg
            stack << args[index]
            index += 1
          when Function
            f = element.to_proc
            operands, block = stack.partition { |e| !e.is_a?(Block) }
            empty = ::Object.new
            xy = [operands.qoq(empty), operands.qoq(empty)]
              .reject { |x| x.equal?(empty) }.reverse
            stack = operands

            if block.empty?
              stack << f.call(*xy)
            else
              stack << f.call(*xy, &block[0].to_proc)
            end
          else
            stack << element
          end
        end

        stack.first
      end
    end

    # Temporary wrapper for @__repr__
    class Repr
      attr_reader :repr

      def initialize(repr)
        @repr = repr
      end
    end

    def method_missing(method, *args, &block)
      extra = [Function.new(method)]
      extra.unshift Block.new(block) if block
      tuply = @__tuply__

      args.map do |arg|
        if arg.is_a?(::Lambda)
          tuply ||= arg.__tuply__
          Repr.new(arg.__repr__)
        else
          arg
        end
      end.each_with_index do |arg, i|
        if arg.is_a? Repr
          args.insert(i, *arg.repr)
          args.delete_at(i + arg.repr.size)
        end
      end

      if tuply
        ::Lambda.new(@__repr__ + args + extra, :lift)
      else
        ::Lambda.new(@__repr__ + args + extra)
      end
    end

    def lift
      ::Lambda.new(@__repr__, :lift)
    end

    def unlift
      @__tuply__ ? ::Lambda.new(@__repr__) : self
    end
  end

  # The identity Lambda object (`_`).
  # Store in a short variable, and use it as a building block for anonymous functions.
  #
  #     _ = EmanLib._
  #     [1, 2, 3].map(&_.succ) => [2, 3, 4]
  #     [[1, 2], [3, 4]].map(&(_ + _).lift) => [3, 7]
  _ = Lambda.new
end

module EmanLib
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

  module_function :support_lambda
end
