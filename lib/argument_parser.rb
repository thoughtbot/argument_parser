# frozen_string_literal: true

require_relative "argument_parser/version"

module ArgumentParser
  extend self

  Error           = Class.new(StandardError)
  SchemaError     = Class.new(Error)
  MissingArgument = Class.new(Error)
  InvalidArgument = Class.new(Error)

  class Parser < Data.define(:schema)
    def parse!(argv = ARGV)
      i = 0

      args = schema.each_with_object({}) do |rule, result|
        case rule.kind
        in :required
          arg = argv[i]
          raise MissingArgument, "missing required argument: #{rule.name}" if arg.nil?
          arg = validate!(arg, rule.options)

          result[rule.name] = arg
          i += 1
        in :optional
          arg = validate!(argv[i], rule.options)

          result[rule.name] = arg || rule.options[:default]
          i += 1 if arg
        in :rest
          rest_args = argv.dup[i..] || []
          rest_args.map! { |it| validate!(it, rule.options) }

          result[rule.name] = rest_args
          i = argv.size
        end
      end

      argv.shift(i)

      args
    end

    private

    def validate!(arg, options)
      coerced_arg = coerce!(arg, options)
      return coerced_arg unless options[:pattern]
      return coerced_arg unless arg
      return coerced_arg if options[:pattern] === coerced_arg

      raise InvalidArgument, "invalid argument: #{arg}"
    end

    def coerce!(arg, options)
      return arg unless arg
      return arg unless options[:type]

      if options[:type] == Integer
        Integer(arg)
      elsif options[:type] == Float
        Float(arg)
      elsif options[:type] == String
        arg
      else
        raise SchemaError, "type not supported: #{options[:type]}"
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
  def build(&block) = Schema::Builder.new.instance_eval(&block).build
end
