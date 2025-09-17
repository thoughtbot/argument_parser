# ArgumentParser

`OptionParser`'s missing sibling.

Parse command line arguments with like you parse options with `OptionParser`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'argument_parser'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install argument_parser

## Usage

`ArgumentParser` provides two ways to define argument schemas:

### Method Chaining API

```ruby
# Define a parser with required arguments
parser = ArgumentParser.schema
  .required(:command)
  .required(:target)
  .build

args = parser.parse!(["deploy", "production"])
# => { command: "deploy", target: "production" }
```

### Builder Block API

```ruby
# Define a parser using a builder block
parser = ArgumentParser.build do
  required :command
  required :target
end

args = parser.parse!(["deploy", "production"])
# => { command: "deploy", target: "production" }
```

## Argument Types

`ArgumentParser` supports three types of arguments that must be defined in a
specific order:

1. **Required** - Must be present, consumed in order. Can't appear after
   optional or rest arguments.
2. **Optional** - May be present. Only one allowed. Can't appear after rest
   arguments.
3. **Rest** - Captures remaining arguments as an array. Can only appear once, at
   the end.

### Order Requirements

Arguments must be defined in this exact order: **required → optional → rest**

```ruby
# ✅ Valid: required followed by optional
ArgumentParser.schema.required(:cmd).optional(:env).build

# ✅ Valid: required followed by rest
ArgumentParser.schema.required(:cmd).rest(:files).build

# ✅ Valid: required, optional, then rest
ArgumentParser.schema.required(:cmd).optional(:env).rest(:files).build

# ✅ Valid: optional, then rest
ArgumentParser.schema.optional(:env).rest(:files).build

# ❌ Invalid: optional before required
ArgumentParser.schema.optional(:env).required(:cmd) # raises SchemaError

# ❌ Invalid: multiple optional arguments
ArgumentParser.schema.optional(:env).optional(:other) # raises SchemaError

# ❌ Invalid: optional after rest
ArgumentParser.schema.rest(:files).optional(:cmd) # raises SchemaError

# ❌ Invalid: required after rest
ArgumentParser.schema.rest(:files).required(:cmd) # raises SchemaError

# ❌ Invalid: multiple rest arguments
ArgumentParser.schema.rest(:files).rest(:others) # raises SchemaError
```

## Options

### Global Options

These options apply to all argument types.

#### Type Coercion

Coerce arguments to specific types:

```ruby
parser = ArgumentParser.build do
  required :count, type: Integer
  required :ratio, type: Float
  required :name, type: String
end

args = parser.parse!(["42", "3.14", "hello"])
# => { count: 42, ratio: 3.14, name: "hello" }
```

Supported types: `Integer`, `Float`, `String` (default).

#### Pattern Validation

You can validate arguments against specific patterns.

##### Inclusion

Checks inclusion using `#include?`.

```ruby
# Using arrays (checks inclusion)
parser = ArgumentParser.build do
  required :env, pattern: %w[dev staging prod]
end
```

##### Mapping

If the object responds to `#key?` and `#[]`, it will be used to map input values
to output values.

```ruby
parser = ArgumentParser.build do
  required :env, pattern: { "d" => "dev", "s" => "staging", "p" => "prod" }
end

args = parser.parse!(["d"])
# => { env: "dev" }

```

##### Case Equality

Any object that responds to `===` can be used as a pattern (e.g., regexes,
ranges, procs):

```ruby
parser = ArgumentParser.build do
  required :command, pattern: /^(show|list|open)$/
  required :port, type: Integer, pattern: (1..65535)
  required :level, pattern: ->(v) { %w[debug info warn error].include?(v) }
end
```

### Options for `optional` Arguments

#### Default Values

Provide default values for optional arguments:

```ruby
parser = ArgumentParser.build do
  required :command
  optional :env, default: "development"
end

args = parser.parse!(["server"])
# => { command: "server", env: "development" }

args = parser.parse!(["server", "production"])
# => { command: "server", env: "production" }
```

### Options for `rest` Arguments

#### Size Constraints

Control the number of rest arguments:

```ruby
parser = ArgumentParser.build do
  rest :files, min: 1, max: 3
end

# Too few arguments
parser.parse!([]) # raises InvalidArgument: "expected at least 1 argument(s)"

# Too many arguments
parser.parse!(["f1", "f2", "f3", "f4"]) # raises InvalidArgument: "expected at most 3 argument(s)"

# Just right
args = parser.parse!(["file1", "file2"])
# => { files: ["file1", "file2"] }
```

## Example: CLI Tool

`ArgumentParser` works great alongside `OptionParser`. Use `ArgumentParser` for
positional arguments and `OptionParser` for options:

```ruby
require 'optparse'
require 'argument_parser'

# Simulated ARGV
argv = ["-v", "--port", "3000", "start", "api"]

# Parse options with OptionParser
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: myapp [options] <command> [service]"

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-p", "--port PORT", Integer, "Port number") do |port|
    options[:port] = port
  end
end.parse!(argv)

# Parse arguments with ArgumentParser
arg_parser = ArgumentParser.build do
  required :command, pattern: %w[start stop restart status]
  optional :service, default: "web"
end

args = arg_parser.parse!(argv)

# Now you have both:
# options => { verbose: true, port: 3000 }
# args => { command: "start", service: "api" }

puts "#{options[:verbose] ? 'Verbosely' : 'Quietly'} #{args[:command]}ing #{args[:service]} on port #{options[:port] || 8080}"
```

## Error Handling

`ArgumentParser` raises specific exceptions for different error conditions. Both
`MissingArgument` and `InvalidArgument` inherit from `ParseError`:

```ruby
begin
  args = parser.parse!(argv)
rescue ArgumentParser::MissingArgument => e
  puts "Missing required argument: #{e.message}"
rescue ArgumentParser::InvalidArgument => e
  puts "Invalid argument: #{e.message}"
rescue ArgumentParser::ParseError => e
  puts "Parse error: #{e.message}"
rescue ArgumentParser::SchemaError => e
  puts "Schema definition error: #{e.message}"
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/thoughtbot/argument_parser.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [code of
conduct](https://github.com/thoughtbot/data_customs/blob/main/CODE_OF_CONDUCT.md).

<!-- START /templates/footer.md -->

## About thoughtbot

![thoughtbot](https://thoughtbot.com/thoughtbot-logo-for-readmes.svg)

This repo is maintained and funded by thoughtbot, inc. The names and logos for
thoughtbot are trademarks of thoughtbot, inc.

We love open source software! See [our other projects][community]. We are
[available for hire][hire].

[community]: https://thoughtbot.com/open-source?utm_source=github&utm_medium=readme&utm_campaign=argument_parser
[hire]: https://thoughtbot.com/hire-us?utm_source=github&utm_medium=readme&utm_campaign=argument_parser

<!-- END /templates/footer.md -->

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
