# emanlib: My Personal Ruby Library

```
require 'emanlib' # this is all you need
```

**emanlib** is a Ruby library that extends core classes with a variety of helpful utility methods, shortcuts, and new features to make your code more expressive and concise. It's designed to add modern conveniences and functional programming patterns to your daily Ruby development.

---

## Key Features

### Object-level Control Flow & Utilities

`emanlib` adds several methods to the `Object` class for more fluid and readable conditional logic and debugging.

- **Conditional Execution**: Use methods like `if`, `or`, `when`, and `iff` to execute blocks based on an object's state in a chainable, expressive way.
- **Assertions**: The `assert` method allows for in-line validation of an object's state or type.
- **Utilities**: Other convenience methods include `tif` and `tor` (for conditional side-effects), and `show` (for inspecting an object's value mid-chain).

<!-- end list -->

```ruby
# Example of 'when' for case-like logic
status_code = 404
status_code
  .when(200..299) { puts "Success!" }
  .when(400..499) { puts "Client Error!" } # This block runs
```

---

### Dynamic Object Creation with `let`

Easily create plain objects with getters and setters from hashes, arrays, or even the local variables within a block. This is perfect for creating simple data structures on the fly.

```ruby
# Create an object from a Hash
person = let(name: "Rio", age: 37)
puts person.name # => "Rio"

# Create an object from a block's local variables
settings = let do
  theme = "dark"
  font_size = 12
  binding # Required to capture the variables
end
puts settings.theme # => "dark"
```

---

### Functional Programming with `Lambda` (`_`)

The `Lambda` feature, represented by the underscore (`_`), is a powerful tool for creating anonymous functions in a highly concise way. It acts as a placeholder for arguments in a function you define on the fly.

- **Core Concept**: Instead of `[1, 2, 3].map { |x| x.succ }`, you can write `[1, 2, 3].map(&_.succ)`. The `_` acts as a template for the function.
- **Chaining**: Build complex functions by chaining operations, like `&_.succ ** 2` which translates to `f(x) = (x + 1)^2`.
- **`.lift` for Multiple Arguments**: Use `.lift` to apply a function to the elements of an array. For example, `[[1, 2], [3, 4]].map(&(_ + _).lift)` will produce `[3, 7]`. It treats each inner array as the arguments for the `+` operation.
- **`support_lambda` for Operators**: Call `EmanLib.support_lambda` to enable using `_` as the second operand in common operations, allowing for natural expressions like `map(&(100 / _))`.

---

### Simple Enums

A simple and lightweight way to create enum-like classes for defining a set of named constants.

```ruby
OS = Enum[:Arch, :BSD]
puts OS.Arch # => 0
puts OS.BSD  # => 1

Pet = Enum["Dog", { Cat: 50 }, :Snake]
puts Pet.Dog   # => 0
puts Pet.Cat   # => 50
puts Pet.Snake # => 51
```

---

### Other Core Extensions

- **Integer**: Adds methods for time durations like `.seconds`, `.minutes`, `.hours`, etc.
- **String**: `exec` for running shell commands and `echo` for printing.
- **Array**: `rest` to get all but the first element and `simplify` to get the single element of a one-element array.
- **Symbol**: `with` for creating curried method procs.

Note: There are more methods, checkout the "foobar.rb" file in the `lib` directory for the complete list.

---

**Version**: 1.0.1
