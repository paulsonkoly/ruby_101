Ruby gotchas
============

## Credits

This document is mainly based on:

  - [interview questions][interview]
  - [ruby gotchas][gotchas]
  - [Ruby under a microscope][microscope]
  - [Everything you ever wanted to know about constant lookup in Ruby][constant]

[interview]: https://www.toptal.com/ruby/interview-questions/
  "interview questions"
[gotchas]: https://docs.google.com/presentation/d/1cqdp89_kolr4q1YAQaB-6i5GXip8MHyve8MvQ_1r6_s/edit#slide=id.gd9ccd329_00
  "ruby gotchas"
[microscope]: http://patshaughnessy.net/ruby-under-a-microscope
  "Ruby under a microscope"
[constant]: https://cirw.in/blog/constant-lookup.html
  "Everything you ever wanted to know about constant lookup in Ruby"

## Variable types: locals, instance variables, class variables, globals, constants

### Constants

You can change constants, but you get a warning.

```ruby
X = 3 # !> previous definition of X was here
X = 5 # !> already initialized constant X
```

even after freezing:

```ruby
X.freeze
X += 3 # !> already initialized constant X
```

#### Constant visibility and lexical scopes

Constant lookup starts by looking for the constant in the current lexical scope of the `Module` or `Class` that is open. If the constant is not found it continues with `Module.nesting`. If the constant is still not found it tries to find constants following the ancestor chain of the current `Module` or `Class` (not including `self.class`).

##### Lexical scope nesting

`module A::B; end` is different from `module A; module B; end; end;`. To prove this we can look at their nesting.

```ruby
module A
end

module A::B
  def self.blah
    Module.nesting
  end
end

A::B.blah # => [A::B]
```

whereas

```ruby
module A
  module B
    def self.blah
      Module.nesting
    end
  end
end

A::B.blah # => [A::B, A]
```

As the first case doesn't include `A` in the nesting list, any constants defined in the lexical scope of `A` will not be visible in `A::B` resulting in the following error:

```ruby
module A
  X = 'constant'
end

module A::B
  def self.blah
    X
  end
end

A::B.blah
# ~> -:7:in `blah': uninitialized constant A::B::X (NameError)
# ~>  from -:11:in `<main>'
```

However the nested scope matches (on the contrary to what can be read at [interview][]).

```ruby
module A
  module B
    X = 'constant'
  end
end

module A::B
  def self.blah
    X
  end
end

p A::B.blah
# >> "constant"
```

### Local variables

#### Variables `defined?`

Variables that appear in code on the left hand side of an assignment are defined. Even if the code is not executed. Defined but not initialized variables evaluate to `nil`.

```ruby
a = 1 if false
defined?(a) # => "local-variable"
```

However not before they lexically appear:

```ruby
defined?(a) # => nil
a = 1 # !> assigned but unused variable - a
```

Defined local variables shadow the visible method names. Therefore the following outputs `nil` (regardless of what's defined first, the function or the variable). Explicit parenthesis can force the parser to take the name as a method name.

```ruby
foo = 'bar' if false

def foo
  'not bar'
end

foo # => nil
foo() # => "not bar"
```

## Equality

 - `==`

   The normal equal by value operator. Define it in a strange way and you might break ruby semantics.

   ```ruby
   class X
     def ==(other)
       false
     end
   end

   a = X.new
   [a].include?(a) # => true
   ```

 - `===`

   Case equality.

 - `eql?`

   Equality with types.

   ```ruby
   1 == 1.0 # => true
   1.eql? 1.0 # => false
   ```

 - `equal?`

 Object equality. Equals if it's the same object instance (.object_id matches).

## `and`, `or`, `||`, `&&`

The main difference is precedence:

```ruby
a = true and false
a  # => true
b = true && false
b  # => false
```

as `a = true and false` is the same as `(a = true) and false`.

## Whitespace nonsense

### Whitespace before method arguments

Method calls with parenthesis omitted for single arguments are OK:

```ruby
def foo(arg)
  arg
end

foo 1 # => 1
foo(1) # => 1
foo (1) # => 1
```

Here `(1)` is a single expression evaluating `1` therefore it's equivalent to the first line. Therefore with two argument it breaks:

```ruby
def foo2(arg1, arg2)
  arg2
end

foo2 1, 2 # => 2
foo2(1, 2) # => 2
foo2 (1, 2)
# ~> -:37: syntax error, unexpected ',', expecting ')'
# ~> ...7178590_6708_297553 = (foo2 (1, 2));$stderr.puts("!XMP153717...
# ~> ...                              ^
# ~> -:37: syntax error, unexpected ')', expecting end-of-input
# ~> ... _xmp_1537178590_6708_297553;));
# ~> ...                              ^
```

### Whitespace with unary `-`

```ruby
def one
  1
end

one - 1 # => 0
one -1
# !> ambiguous first argument; put parentheses or a space even after `-' operator
# ~> -:35:in `one': wrong number of arguments (given 1, expected 0) (ArgumentError)
# ~> 	from -:40:in `<main>'
```

## Class variables

They should not be used. They break inheritance, encapsulation etc. Variables are shared with *all* subclasses.

## `super` vs `super()`

`super` is a keyword, not a method call. It's semantics are slightly different from a normal call: with no argument it passes the current methods arguments to the parent class's method.

## `.freeze` is shallow

```ruby
a = ['apple']
a.freeze
a << 1

# ~> -:3:in `<main>': can't modify frozen Array (FrozenError)
```

but this is fine:

```ruby
a[0].concat('gate')
a # => ["applegate"]
```

## default values

Default values point to the same object:

```ruby
a = Array.new(3, 'apple')
a[0].concat('gate')
a # => ["applegate", "applegate", "applegate"]
```

Same with hash defaults.
