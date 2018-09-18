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

## Constants

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

### Lexical scopes

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

Defined local variables shadow the visible method names. Therefore the following outputs `nil` (regardless of what's defined first, the function or the variable)

```ruby
foo = 'bar' if false

def foo
  'not bar'
end

p foo
# >> nil
```

You can still access the method with explicit receiver:

```ruby
p self.send :foo
# >> "not bar"
```

`send` is required here because this is defined top level which makes `foo` a *private* instance method of `Object`. An other way of working around the visibility would have been:

```ruby
foo = 'bar' if false # !> assigned but unused variable - foo

public

def foo
  'not bar'
end

p self.foo
# >> "not bar"
```

### Lexical scopes with same name

Consider the following code:

```ruby
VAL = 'Global'

module Foo
  VAL = 'Foo Local'

  class Bar
    def value1
      VAL
    end
  end
end

class Foo::Bar
  def value2
    VAL
  end
end
```

then

```ruby
Foo::Bar.new.value1 # => "Foo Local"
Foo::Bar.new.value2 # => "Global"
```

The `module` keyword (as well as the `class` and `def` keywords) will create a new lexical scope for all of its contents. The above `module Foo` therefore creates the scope `Foo` in which the `VAL` constant equal to `'Foo Local'` is defined. Inside `Foo`, we declare class `Bar`, which creates another new lexical scope (named `Foo::Bar`) which also has access to its parent scope (i.e., `Foo`) and all of its constants.

However, when we then declare `Foo::Bar` (i.e., using ::), we are actually creating yet another lexical scope, which is also named `Foo::Bar` (how's that for confusing!). However, this lexical scope has no parent (i.e., it is entirely independent of the lexical scope `Foo` created earlier) and therefore does not have any access to the contents of the `Foo` scope.

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
