# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ArgumentParser::Schema::Builder do
  it "builds schema with required, optional, and rest" do
    parser = ArgumentParser.build do
      required :cmd, pattern: /^(show|list|open)$/
      optional :env, default: "dev"
      rest :files
    end

    expect(parser.schema).to eq([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {pattern: /^(show|list|open)$/}),
      ArgumentParser::Schema::Rule.new(:optional, :env, {default: "dev"}),
      ArgumentParser::Schema::Rule.new(:rest, :files, {})
    ])
  end
end
