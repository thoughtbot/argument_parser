# frozen_string_literal: true

RSpec.describe "ArgumentParser schema building" do
  it "allows multiple required args" do
    schema = ArgumentParser.schema.required(:cmd).required(:target)

    parser = schema.build

    expect(parser).to be_a(ArgumentParser::Parser)
  end

  it "allows required followed by optional" do
    schema = ArgumentParser.schema.required(:cmd).optional(:env)

    parser = schema.build

    expect(parser).to be_a(ArgumentParser::Parser)
  end

  it "allows required followed by rest" do
    schema = ArgumentParser.schema.required(:cmd).rest(:files)

    parser = schema.build

    expect(parser).to be_a(ArgumentParser::Parser)
  end

  it "allows required followed by optional and rest" do
    schema = ArgumentParser.schema.required(:cmd).optional(:env).rest(:files)

    parser = schema.build

    expect(parser).to be_a(ArgumentParser::Parser)
  end

  it "allows starting with an optional (e.g., `show [gemname]`)" do
    schema = ArgumentParser.schema.optional(:gemname)

    parser = schema.build

    expect(parser).to be_a(ArgumentParser::Parser)
  end

  it "allows starting with a rest (a pure list shape)" do
    schema = ArgumentParser.schema.rest(:files)

    parser = schema.build

    expect(parser).to be_a(ArgumentParser::Parser)
  end

  it "rejects multiple optional positionals" do
    builder = ArgumentParser.schema.required(:cmd).optional(:env)

    expect {
      builder.optional(:another_env)
    }.to raise_error(ArgumentParser::SchemaError, /only one optional/i)
  end

  it "rejects required after optional" do
    builder = ArgumentParser.schema.required(:cmd).optional(:env)

    expect {
      builder.required(:target)
    }.to raise_error(ArgumentParser::SchemaError, /cannot add required/i)
  end

  it "rejects optional after rest" do
    builder = ArgumentParser.schema.required(:cmd).rest(:files)

    expect {
      builder.optional(:env)
    }.to raise_error(ArgumentParser::SchemaError, /only one optional|after optional\/rest/i)
  end

  it "rejects required after rest" do
    builder = ArgumentParser.schema.required(:cmd).rest(:files)

    expect {
      builder.required(:target)
    }.to raise_error(ArgumentParser::SchemaError, /cannot add required/i)
  end

  it "rejects multiple rest positionals" do
    builder = ArgumentParser.schema.required(:cmd).rest(:files)

    expect {
      builder.rest(:more_files)
    }.to raise_error(ArgumentParser::SchemaError, /only one rest/i)
  end
end
