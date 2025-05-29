# frozen_string_literal: true

# Extends the base Object class with utility methods for control flow,
# introspection, and data manipulation.
class Object
  # If the object is truthy (neither `nil` nor `false`), yields the object
  # itself to the given block.
  #
  # @example
  #   123.if { |x| puts "Number is #{x}" } # Output: Number is 123
  #   nil.if { |x| puts "This won't print: #{x}" } # Nothing
  #   false.if { |x| puts "This also won't print: #{x}" } # Nothing
  #   "hello".if { |s| s.upcase } # => "HELLO"
  #
  # @yield [self] Gives `self` to the block if `self` is truthy.
  # @return [Object, nil] The result of the block if executed, otherwise `nil`.
  def if
    self && yield(self)
  end

  # If the object is truthy, yields the object to the block and then returns `self`.
  # This is similar to {Object#if}, but always returns `self`, making it useful
  # for chaining or conditional side effects.
  #
  # @example
  #   value = "test".tif { |s| puts "Processing #{s}" } # Output: Processing test
  #   puts value # Output: test
  #
  #   data = [1, 2, 3]
  #   data.tif { |arr| arr.pop if arr.size > 2 }
  #   puts data.inspect # Output: [1, 2] (if data was not empty)
  #
  # @yield [self] Gives `self` to the block if `self` is truthy.
  # @return [self] The original object.
  def tif
    tap { self && yield(self) }
  end

  # If the object is falsy (`nil` or `false`), yields the object itself to the
  # given block.
  #
  # @example
  #   nil.or { |x| puts "Object was nil" } # Output: Object was nil
  #   false.or { |x| puts "Object was false" } # Output: Object was false
  #   123.or { |x| puts "This won't print: #{x}" } # Output: (nothing)
  #   "".or { |s| s + "default" } # => "" (empty string is truthy)
  #
  # @yield [self] Gives `self` to the block if `self` is falsy.
  # @return [Object, nil] The result of the block if executed, otherwise `self`.
  #   Note that `self || yield(self)` returns `self` if truthy, and `yield(self)` if falsy.
  def or
    self || yield(self)
  end

  # If the object is falsy, yields the object to the block and then returns `self`.
  # This is similar to {#or}, but always returns the original object.
  #
  # @see Object#default An alias for this method.
  #
  # @example
  #   result = nil.tor { |x| puts "Handled nil case" } # Output: Handled nil case
  #   puts result.inspect # Output: nil
  #
  #   user_input = "".empty? && nil # user_input is nil
  #   user_input.tor { puts "This will print" }
  #
  # @yield [self] Gives `self` to the block if `self` is falsy.
  # @return [self] The original object.
  def tor
    tap { self || yield(self) }
  end

  # If `x` is case-equal (`===`) to `self`, yields to the block and returns `self`.
  # This is useful for chaining checks, mimicking a case-like structure.
  #
  # @param x [Object] The object to compare against `self` using `===`. Defaults to `self`,
  #   which means `self === self` is checked if no argument is passed (effectively
  #   yielding if `self` is matched by itself, which is always true for typical objects).
  # @yield If `x === self` is true.
  # @return [self] The original object.
  #
  # @example
  #   status_code = 200
  #   status_code
  #     .when(200..299) { puts "Yay!" } # Only one to run
  #     .when(400..499) { puts "Client Error!" }
  #     .when(500..599) { puts "Server Error!" }
  #
  #   # Only `Array`'s block runs here
  #   [1,2,3,4,5,6]
  #       .when(Array) { puts "It's an array" }
  #       .when(String) { puts "It's a string" }
  #
  #   # Chaining `default` (alias for `tor`)
  #   "hello"
  #     .when(Integer) { |n| puts "#{n} + 1 = #{n + 1}" }
  #     .default { puts "This won't run either" }
  #
  #   # If value was nil:
  #   # nil.when(Integer){}.default { puts "this will print" }
  def when(x = self)
    tap { yield(self) if x === self }
  end

  # Just like [Object#when], but propagates the values of the blocks that execute.
  # This method can be chained because it returns `self` if no block is executed.
  #
  # @param x [Object] The object to compare against `self` using `===`. Default is `self`.
  # @yield If `x === self` is true.
  # @return [Object | self] The result of the block if executed, otherwise `self`.
  #
  # @example
  #   42.iff(Integer) { |x| x * 2 } # => 84
  #   "foo".iff(Float) { |n| n / 2 }.iff(String) { |s| s.upcase } # => "FOO"
  def iff(x = self)
    if x === self
      yield(self)
    else
      self
    end
  end

  # Asserts a condition about `self`.
  # If a block is given, it asserts that the block returns a truthy value.
  # The block is passed `self` as an argument.
  # If no block is given, it asserts that `n === self` is true.
  # If the assertion fails, it performs a non-local exit by `raise`.
  #
  # @param `n` ([Object]) The object to compare with `self` if no block is given.
  # @param `error` ([Class]) The class of error to raise if the assertion fails.
  # @param `message` (String?) An optional message to include in the raised error.
  # @yield [self] Optional block whose truthiness is asserted.
  # @return [self] The original object if assertion passes.
  # @throw `error` (or a related symbol) if the assertion fails.
  #
  # @example
  #   5.assert(Integer) # Passes
  #   "string".assert(error: ArgumentError) { |s| s.size > 5 } # Passes
  #   "".assert(message: "String too short") {|s| s.size > 5 } # Raises error with message
  def assert(n = self, error: StandardError, message: nil)
    tap { (block_given? ? yield(self) : (n === self)) || (message ? raise(error, message) : raise(error)) }
  end

  # Prints the `inspect` representation of `self` to standard output.
  # Returns `self`, allowing for chaining.
  #
  # @example
  #   [1, 2, 3]
  #      .show # prints [1, 2, 3]
  #      .map { |x| x * 2 }
  #      .show # print [2, 4, 6]
  def show
    tap { puts inspect }
  end
end

alias m method
alias default tor
alias env binding

# Extends the Integer class with methods for time durations and comparisons.
class Integer
  # Represents the integer as a duration in seconds.
  # @return [Integer] self
  def second; self end

  # Converts the integer (assumed to be minutes) into seconds.
  # @return [Integer] Total seconds.
  def minute; self * 60.second end

  # Converts the integer (assumed to be hours) into seconds.
  # @return [Integer] Total seconds.
  def hour; self * 60.minute end

  # Converts the integer (assumed to be days) into seconds.
  # @return [Integer] Total seconds.
  def day; self * 24.hour end

  # Converts the integer (assumed to be weeks) into seconds.
  # @return [Integer] Total seconds.
  def week; self * 7.day end

  # Converts the integer (assumed to be months, approximated as 4 weeks) into seconds.
  # @return [Integer] Total seconds.
  def month; self * 4.week end

  # Converts the integer (assumed to be years) into seconds.
  # @return [Integer] Total seconds.
  def year; self * 12.month end

  # Returns the minimum of `self` and the given numeric values.
  #
  # @param `xs` [Array<Numeric>] Zero or more numeric values to compare against.
  # @return [Numeric] The smallest value among `self` and `xs`.
  # @example
  #   5.min(3, 4, 2)  # => 2
  #   -1.min(0, 1)    # => -1
  #   10.min(20)      # => 10
  def min(*xs)
    xs.push(self)
    xs.min
  end

  # Returns the maximum of `self` and the given numeric values.
  #
  # @param `xs` [Array<Numeric>] Zero or more numeric values to compare against.
  # @return [Numeric] The largest value among `self` and `xs`.
  # @example
  #   5.max(3, 4, 11) # => 11
  #   -1.max(-5, 0)   # => 0
  #   10.max(2)       # => 10
  def max(*xs)
    xs.push(self)
    xs.max
  end
end

# Extends the String class with methods for system execution and output.
class String
  # Executes the string as a system command.
  # Allows for substituting arguments into the string using `sprintf` format.
  #
  # @param args [Hash] A hash of arguments to be interpolated into the command string.
  #   The keys are used in `sprintf`-style formatting (e.g., `%{key}`).
  # @return [Boolean, nil] Returns `true` if the command was found and ran successfully (exit status 0),
  #   `false` if the command returned a non-zero exit status, and `nil` if command execution failed
  #   (e.g., command not found).
  # @example
  #   "ls -l %{dir}".exec(dir: "/tmp")
  #   "echo 'Hello World'".exec # => true (prints "Hello World")
  #   "ruby -e 'exit 1'".exec # => false
  def exec(args = {})
    system(self % args)
  end

  # Prints the string to the console, followed by a newline.
  def echo
    tap { puts self }
  end
end

# Extends the Array class with methods for accessing elements.
class Array
  # Returns the rest of the array (all elements except the first).
  # Returns an empty array if the original array has 0 or 1 element.
  #
  # @return [Array] A new array containing all elements except the first.
  # @example
  #   [1, 2, 3, 4].rest # => [2, 3, 4]
  #   [1].rest          # => []
  #   [].rest           # => []
  def rest
    drop 1
  end

  # Simplifies the array: if it contains exactly one element, returns that element.
  # Otherwise, returns the array itself.
  #
  # @return [Object, Array] The single element if array size is 1, otherwise `self`.
  # @example
  #   [42].simplify    # => 42
  #   ["hello"].simplify # => "hello"
  #   [1, 2].simplify  # => [1, 2]
  #   [].simplify      # => []
  def simplify
    size == 1 ? fetch(0) : self
  end

  # Defines methods `second`, `third`, ..., `tenth` for accessing elements or sub-arrays.
  # Each method `arr.Nth(n=1)` (e.g., `arr.third` or `arr.third(2)`):
  # - Skips `(index_of_Nth - 1)` elements (e.g., for `third`, skips 2 elements).
  # - Takes `n` elements from that point.
  # - Simplifies the result using {#simplify}.
  #
  # @example
  #   arr = [10, 20, 30, 40, 50, 60]
  #   arr.second       # => 20 (drops 1, takes 1, simplifies)
  #   arr.third        # => 30 (drops 2, takes 1, simplifies)
  #   arr.second(2)    # => [20, 30] (drops 1, takes 2, simplifies)
  #   arr.fourth(3)    # => [40, 50, 60] (drops 3, takes 3, simplifies)
  #   arr.sixth        # => 60
  #   arr.seventh      # => nil (if out of bounds and simplified from empty array or single nil)
  #   ["a","b"].third  # => nil
  %i[second third fourth fifth sixth seventh eighth ninth tenth]
    .zip(1..) # 1-based index for human-readable Nth
    .each do |method_name, index|
    define_method(method_name) do |n = 1|
      # `index` is 1 for 'second', 2 for 'third', etc.
      # So, for 'second' (index 1), drop 1. For 'third' (index 2), drop 2.
      drop(index).take(n).simplify
    end
  end
end

# Extends the Symbol class for functional programming patterns.
class Symbol
  # Creates a Proc that functions as a curried instance method for objects
  # It is possible to supply a block (to the instance method) for later use.
  # This method allows for partial application of instance methods.
  #
  # @param `args` [Array<Object>] Arguments to be pre-supplied to the method.
  # @param `block` [Proc] A block to be pre-supplied to the method.
  # @return [Proc] A lambda that expects a receiver object and any further arguments.
  #
  # @example
  #   plus_2 = :+.with(2)
  #   plus_2.call(5) # => 7
  #
  #   mapper = :map.with { |x| x * x }
  #   data = [1, 2, 3]
  #   mapper.call(data) # => [1, 4, 9]
  #
  #   # Combining with map
  #   [1, 2, 3].map(&:+.with(10)) # => [11, 12, 13]
  def with(*args, &block)
    ->(o, *more) { o.send(self, *args, *more, &block) }
  end
end

# Extends the Thread class.
class Thread
  # Returns an array of all live threads except the current thread.
  # A static class method.
  #
  # @return [Array<Thread>] An array of other live Thread objects.
  #
  # @example
  #   thread1 = Thread.new { sleep 1 }
  #   thread2 = Thread.new { sleep 1 }
  #   # In the main thread:
  #   Thread.others # => might include thread1, thread2 (depending on timing)
  def self.others
    Thread.list.reject { |x| x == Thread.current }
  end
end

# Extends the Hash class with an alias
class Hash
  alias flip invert
end
