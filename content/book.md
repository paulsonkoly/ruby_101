Ruby 101
============

## 101

The title 101 refers to the UK television program [Room 101](https://en.wikipedia.org/wiki/Room_101_(TV_series)).

## Credits

This document is mainly based on:

  - [interview questions][interview]
  - [ruby gotchas][gotchas]
  - [Ruby under a microscope][microscope]
  - [Everything you ever wanted to know about constant lookup in Ruby][constant]
  - [API docs][api]
  - [expression vs statement][exp_vs_stm]

[interview]: https://www.toptal.com/ruby/interview-questions/
  "interview questions"
[gotchas]: https://docs.google.com/presentation/d/1cqdp89_kolr4q1YAQaB-6i5GXip8MHyve8MvQ_1r6_s/edit#slide=id.gd9ccd329_00
  "ruby gotchas"
[microscope]: http://patshaughnessy.net/ruby-under-a-microscope
  "Ruby under a microscope"
[constant]: https://cirw.in/blog/constant-lookup.html
  "Everything you ever wanted to know about constant lookup in Ruby"
[api]: https://ruby-doc.org/core-2.6.4/
  "Official ruby stdlib documentation"
[exp_vs_stm]:https://github.com/ruby/ruby/commit/29c1e9a0d4c855781853f0ad41b0125f42cf504d
  "Jeremy Evans' CI to ruby documentation"

## Variable types: locals, instance variables, class variables, globals, constants

### Class variables

They should not be used. They break inheritance, encapsulation etc. Variables are shared with *all* subclasses.

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

Local variables are declared by their first assignment. This might be syntactically ambiguous, like in the following example:

```ruby
class X
  def initialize
    @foo = 1
  end

  attr_accessor :foo

  def boo
    foo = 10 # !> assigned but unused variable - foo
  end
end

x = X.new
x.boo
x.foo # => 1
```

Here the intention was to modify `@foo` via the attr_accessor, however ruby interprets the assignment as a local variable declaration. To override this behaviour one can explicitly add _self_, `self.foo = 10` would have worked as expected. Also note that the same behaviour is present with the `+=`, `-=` etc operators, as those are just short hand forms of `=` expression ie. `foo += 10` is equivalent to `foo = foo + 10`.

#### Binding#local_variable_set

Binding#local_variable_set doesn't declare the local variable in the local lexical scope.

```ruby
binding.local_variable_set :a, 1
a # => NameError: undefined local variable or method `a' for main:Object
```

However if the variable was already declared then we can change it.

```ruby
a = 2
binding.local_variable_set :a, 1
a # => 1
```

#### Local variable scopes

Local variables can appear in any of the following scopes:

  - top level
  - module definition
  - class definition
  - method definition
  - block

For all cases except the block case local variables are only visible from the lexical scope that defines them, excluding contained sub-scopes, and containing scopes.

```ruby
module A
  x = 3
  puts "before blah : #{x}"
  def self.blah
    x = 5
    puts "in blah : #{x}"
    1.times do
      puts "in block : #{x}"
      x = 6
    end
    puts "after block : #{x}"
  end
  puts "after blah : #{x}"
end
A.blah
# >> before blah : 3
# >> after blah : 3
# >> in blah : 5
# >> in block : 5
# >> after block : 6
```

In case of a block if the containing lexical scope defines the local variable (see next section on `defined?`), the variable from the outside scope will be used. Otherwise the variable automatically becomes local to the block. 

```ruby
def foo
  1.times do
    bar = 1 # !> assigned but unused variable - bar
  end
  p bar
end

foo
# ~> -:5:in `foo': undefined local variable or method `bar' for main:Object (NameError)
# ~> 	from -:8:in `<main>'
```

We can also explicitly declare local variables block local.

```ruby
def foo
  bar = 1 # !> assigned but unused variable - bar
  1.times do |;bar| # !> shadowing outer local variable - bar
    p bar
  end
end

foo
# >> nil
```

##### Variables `defined?`

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

##### `local_variables` is confusing

`local_variables` include not yet defined variable names, but we can't use them:

```ruby
local_variables # => [:bar]
p bar
bar = 1 # !> assigned but unused variable - bar
# ~> -:2:in `<main>': undefined local variable or method `bar' for main:Object (NameError)
```

#### Files and TOPLEVEL_BINDING

In the top level lexical scope of our program we can define local variables and
these go to TOPLEVEL_BINDING. However files also make local variables lexically
bound. This results in confusing results.

In `a.rb` we can access local variables either by using their name, or using
the TOPLEVEL_BINDING.

```ruby
# a1.rb
a = 1
TOPLEVEL_BINDING.local_variable_get(:a) # => 1
```

or this seems to be the same at the first glance:

```ruby
# a2.rb
a = 2
TOPLEVEL_BINDING.local_variable_set(:a, 1) # => 1
a # => 1
```

However the difference between TOPLEVEL_BINDING and the file local variables
become apparent, when we require these files:

```ruby
# b.rb
require 'a1.rb'
TOPLEVEL_BINDING.local_variable_get(:a) # => 
# ~> /tmp/a1.rb:3:in `local_variable_get': local variable `a' is not defined for #<Binding:0x0000556f87388a78> (NameError)
# ~> 	from /tmp/a.rb:3:in `<top (required)>'
# ~> 	from /usr/lib/ruby/2.5.0/rubygems/core_ext/kernel_require.rb:59:in `require'
# ~> 	from /usr/lib/ruby/2.5.0/rubygems/core_ext/kernel_require.rb:59:in `require'
# ~> 	from -:1:in `<main>'
```

but

```ruby
# b.rb
require 'a2.rb'

TOPLEVEL_BINDING.local_variable_get(:a) # => 1
```

Accessing local variables from other files by name is not possible.

## Expressions vs. statements

The modifier `if`, `unless` etc. statements are not expressions as explained in [exp_vs_stm]. The following code results in syntax error:

```ruby
puts('nope' if true)

# ~> 	Syntax Error: :2
# ~> 	unexpected token kIF_MOD
```

but this is fine:

```ruby
puts(('nope' if true))

# >> nope
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

   Case equality is type dependent. In most cases it expresses that the left hand side contains the right hand side, and some cases it expresses that they are equal. It's natural to think that `a == b` implies `a === b` in all cases but it's not true.

   ```ruby
   c = Integer
   case c
   when String then 'String'
   when Integer then 'Integer'
   else 'none of the above'
   end # => "none of the above"
   ```

 - `eql?`, is hash key/value in a set equality

The `eql?` method returns true if obj and other refer to the same hash key. This is used by Hash to test members for equality. For objects of class Object, `eql?` is synonymous with `==.` Subclasses normally continue this tradition by aliasing `eql?` to their overridden `==` method, but there are exceptions. `Numeric` types, for example, perform type conversion across `==,` but not across `eql?` [api]

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

Here `(1)` is a single expression evaluating to `1` therefore it's equivalent to the first line. Therefore with two argument it breaks:

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
