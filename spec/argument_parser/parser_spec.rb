# frozen_string_literal: true

RSpec.describe ArgumentParser::Parser do
  it "parses required only" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {}),
      ArgumentParser::Schema::Rule.new(:required, :target, {})
    ])

    argv = %w[deploy production]
    result = parser.parse!(argv)

    expect(result[:cmd]).to eq("deploy")
    expect(result[:target]).to eq("production")
    expect(argv).to be_empty
  end

  it "parses required + optional when optional is present" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {}),
      ArgumentParser::Schema::Rule.new(:optional, :env, {})
    ])

    argv = %w[server staging]
    result = parser.parse!(argv)

    expect(result[:cmd]).to eq("server")
    expect(result[:env]).to eq("staging")
    expect(argv).to be_empty
  end

  it "parses required + optional when optional is missing and default applies" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {}),
      ArgumentParser::Schema::Rule.new(:optional, :env, {default: "development"})
    ])

    argv = %w[server]
    result = parser.parse!(argv)

    expect(result[:cmd]).to eq("server")
    expect(result[:env]).to eq("development")
    expect(argv).to be_empty
  end

  it "leaves argv elements unconsumed when schema ends before argv" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {})
    ])

    argv = %w[echo hello world]
    result = parser.parse!(argv)

    expect(result[:cmd]).to eq("echo")
    expect(argv).to eq(%w[hello world])
  end

  it "raises on missing required" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {}),
      ArgumentParser::Schema::Rule.new(:required, :target, {})
    ])

    argv = %w[deploy]
    expect { parser.parse!(argv) }.to raise_error(ArgumentParser::MissingArgument, /missing required argument: target/i)
  end

  context "when a pattern is given" do
    it "ensures value matches the pattern using case equality" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:required, :cmd, {pattern: /^(show|list|open)$/}),
        ArgumentParser::Schema::Rule.new(:optional, :env, {pattern: ->(v) { %w[dev staging prod].include?(v) }})
      ])

      argv = %w[list]
      expect(parser.parse!(argv)).to eq(cmd: "list", env: nil)

      argv = %w[show prod]
      expect(parser.parse!(argv)).to eq(cmd: "show", env: "prod")

      argv = %w[close]
      expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /invalid argument: close/i)
    end

    context "when pattern responds to #include?" do
      it "ensures value is included in the pattern" do
        parser = ArgumentParser::Parser.new([
          ArgumentParser::Schema::Rule.new(:required, :env, {pattern: %w[dev staging prod]})
        ])

        argv = %w[dev]
        expect(parser.parse!(argv)).to eq(env: "dev")

        argv = %w[qa]
        expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /invalid argument: qa/i)
      end

      context "and responds to #key?" do
        it "maps input values to expected values" do
          parser = ArgumentParser::Parser.new([
            ArgumentParser::Schema::Rule.new(:required, :env, {pattern: {"d" => "dev", "s" => "staging"}})
          ])

          argv = %w[d]
          expect(parser.parse!(argv)).to eq(env: "dev")

          argv = %w[s]
          expect(parser.parse!(argv)).to eq(env: "staging")

          argv = %w[x]
          expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /invalid argument: x/i)
        end
      end
    end

    it "validates each item in rest with pattern" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:rest, :stages, {pattern: ->(v) { %w[dev staging prod].include?(v) }})
      ])

      argv = %w[dev staging deploy prod]
      expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /invalid argument: deploy/i)
    end
  end

  context "when a type is given" do
    it "allows coercing values to Integer" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:required, :count, {type: Integer}),
      ])

      argv = %w[1]
      expect(parser.parse!(argv)).to eq(count: 1)

      argv = %w[foo]
      expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /invalid argument: foo/i)
    end

    it "allows coercing values to Float" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:required, :count, {type: Float}),
      ])

      argv = %w[1.5]
      expect(parser.parse!(argv)).to eq(count: 1.5)

      argv = %w[foo]
      expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /invalid argument: foo/i)
    end

    it "allows coercing values to String" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:required, :count, {type: String}),
      ])

      argv = %w[1.5]
      expect(parser.parse!(argv)).to eq(count: "1.5")
    end

    it "raises on unsupported types" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:required, :count, {type: Class}),
      ])

      expect { parser.parse!([%w[Class]]) }.to raise_error(ArgumentParser::SchemaError, /type not supported: Class/i)
    end
  end

  describe "rest options" do
    it "accepts a min option" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:rest, :files, {min: 1})
      ])

      argv = %w[file1 file2]
      expect(parser.parse!(argv)).to eq(files: %w[file1 file2])

      argv = []
      expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /expected at least 1 argument/)
    end

    it "accepts a max option" do
      parser = ArgumentParser::Parser.new([
        ArgumentParser::Schema::Rule.new(:rest, :files, {max: 2})
      ])

      argv = %w[file1 file2]
      expect(parser.parse!(argv)).to eq(files: %w[file1 file2])

      argv = %w[file1 file2 file3]
      expect { parser.parse!(argv) }.to raise_error(ArgumentParser::InvalidArgument, /expected at most 2 argument\(s\)/)
    end
  end

  it "returns a hash result" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:required, :cmd, {}),
      ArgumentParser::Schema::Rule.new(:optional, :env, {default: "dev"}),
      ArgumentParser::Schema::Rule.new(:rest, :files, {})
    ])

    argv = %w[build]
    result = parser.parse!(argv)

    expect(result[:cmd]).to eq("build")
    expect(result[:env]).to eq("dev")
    expect(result[:files]).to eq([])
  end

  it "raises on unknown rule kind" do
    parser = ArgumentParser::Parser.new([
      ArgumentParser::Schema::Rule.new(:unknown, :bad, {})
    ])

    argv = %w[build]
    expect { parser.parse!(argv) }.to raise_error(NoMatchingPatternError, /unknown/i)
  end
end
