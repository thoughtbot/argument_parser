# frozen_string_literal: true

require_relative "argument_parser/version"

module ArgumentParser
  extend self

  Error           = Class.new(StandardError)
  SchemaError     = Class.new(Error)
  ParseError      = Class.new(Error)
  MissingArgument = Class.new(ParseError)
  InvalidArgument = Class.new(ParseError)

  class Parser < Data.define(:schema)
    def usage(program_name = nil)
      parts = []
      parts << program_name if program_name

      parts += schema.map do |rule|
        case rule
        in kind: :required
          "<#{rule.name.to_s.upcase}>"
        in kind: :optional
          "[#{rule.name.to_s.upcase}]"
        in kind: :rest, options:
          if options[:min].to_i.positive?
            "<#{rule.name.to_s.upcase}...>"
          else
            "[#{rule.name.to_s.upcase}...]"
          end
        end
      end

      parts.join(" ")
    end

    def parse!(argv = ARGV)
      i = 0

      args = schema.each_with_object({}) do |rule, result|
        case rule.kind
        in :required
          arg = argv[i]
          raise MissingArgument, "missing required argument: #{rule.name}" if arg.nil?
          arg = validate_pattern!(arg, rule.options)

          result[rule.name] = arg
          i += 1
        in :optional
          arg = validate_pattern!(argv[i], rule.options)

          result[rule.name] = arg || rule.options[:default]
          i += 1 if arg
        in :rest
          rest_args = argv.dup[i..] || []
          validate_size(rest_args, rule.options)
          rest_args.map! { |it| validate_pattern!(it, rule.options) }

          result[rule.name] = rest_args
          i = argv.size
        end
      end

      argv.shift(i)

      args
    end

    private

    def validate_pattern!(arg, options)
      coerced_arg = coerce!(arg, options[:type])
      pattern = options[:pattern]
      return coerced_arg unless pattern
      return coerced_arg unless arg
      return coerced_arg if pattern === coerced_arg
      return pattern[coerced_arg] if pattern.respond_to?(:key?) && pattern.key?(coerced_arg)
      return coerced_arg if pattern.respond_to?(:include?) && pattern.include?(coerced_arg)

      raise InvalidArgument, "invalid argument: #{arg}"
    end

    def validate_size(args, options)
      if (min = options[:min])
        raise InvalidArgument, "expected at least #{min} argument(s)" if args.size < min
      end

      if (max = options[:max])
        raise InvalidArgument, "expected at most #{max} argument(s)" if args.size > max
      end
    end

    def coerce!(arg, type)
      return arg unless arg
      return arg unless type

      if type == Integer
        Integer(arg)
      elsif type == Float
        Float(arg)
      elsif type == String
        arg
      else
        raise SchemaError, "type not supported: #{type}"
      end
    rescue ArgumentError
      raise InvalidArgument, "invalid argument: #{arg}"
    end
  end

  module Schema
    class Builder
      def initialize
        @current_stage = Schema::RequiredStage.new([])
      end

      def required(...) = @current_stage = @current_stage.required(...)
      def optional(...) = @current_stage = @current_stage.optional(...)
      def rest(...)     = @current_stage = @current_stage.rest(...)
      def build = @current_stage.build
    end

    Rule = Data.define(:kind, :name, :options)

    RequiredStage = Data.define(:schema) do
      def required(name, **opts)
        self.class.new(schema + [Rule.new(:required, name, opts)])
      end

      def optional(name, **opts)
        OptionalStage.new(schema + [Rule.new(:optional, name, opts)])
      end

      def rest(name, **opts)
        RestStage.new(schema + [Rule.new(:rest, name, opts)])
      end

      def build = Parser.new(schema)
    end

    class OptionalStage < RequiredStage
      def required(*) = raise SchemaError, "cannot add required arguments after optional/rest"
      def optional(*) = raise SchemaError, "only one optional argument is allowed"
    end

    class RestStage < OptionalStage
      def rest(*) = raise SchemaError, "only one rest argument is allowed"
    end
  end

  def schema = Schema::RequiredStage.new([])
  def build(&block) = Schema::Builder.new.tap { |it| it.instance_eval(&block) }.build
end
