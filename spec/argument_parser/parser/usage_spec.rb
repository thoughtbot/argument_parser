# frozen_string_literal: true

RSpec.describe ArgumentParser::Parser, "#usage" do
  describe "basic argument types" do
    it "formats required arguments with angle brackets" do
      parser = ArgumentParser.build do
        required :input
        required :output
      end

      expect(parser.usage).to eq("<INPUT> <OUTPUT>")
    end

    it "formats optional arguments with square brackets" do
      parser = ArgumentParser.build do
        required :input
        optional :format
      end

      expect(parser.usage).to eq("<INPUT> [FORMAT]")
    end

    it "formats optional rest arguments with square brackets and ellipsis" do
      parser = ArgumentParser.build do
        required :input
        rest :files
      end

      expect(parser.usage).to eq("<INPUT> [FILES...]")
    end

    it "formats required rest arguments with angle brackets and ellipsis" do
      parser = ArgumentParser.build do
        required :input
        rest :files, min: 1
      end

      expect(parser.usage).to eq("<INPUT> <FILES...>")
    end
  end

  describe "with program name" do
    it "includes program name at the beginning" do
      parser = ArgumentParser.build do
        required :input
        optional :output
      end

      expect(parser.usage("myprogram")).to eq("myprogram <INPUT> [OUTPUT]")
    end

    it "includes program name with multiple words" do
      parser = ArgumentParser.build do
        required :command
        required :target
      end

      expect(parser.usage("gem show")).to eq("gem show <COMMAND> <TARGET>")
    end
  end

  describe "complex combinations" do
    it "handles all argument types in correct order" do
      parser = ArgumentParser.build do
        required :source
        required :dest
        optional :format
        rest :extras, min: 2
      end

      expect(parser.usage("tool")).to eq("tool <SOURCE> <DEST> [FORMAT] <EXTRAS...>")
    end

    it "handles optional rest with other arguments" do
      parser = ArgumentParser.build do
        required :command
        optional :config
        rest :args
      end

      expect(parser.usage).to eq("<COMMAND> [CONFIG] [ARGS...]")
    end

    it "handles multiple required arguments with optional and rest" do
      parser = ArgumentParser.build do
        required :command
        required :action
        optional :env
        rest :files
      end

      expect(parser.usage).to eq("<COMMAND> <ACTION> [ENV] [FILES...]")
      expect(parser.usage("myapp")).to eq("myapp <COMMAND> <ACTION> [ENV] [FILES...]")
    end
  end

  describe "single argument types" do
    it "handles only optional argument" do
      parser = ArgumentParser.build do
        optional :gemname
      end

      expect(parser.usage).to eq("[GEMNAME]")
      expect(parser.usage("gem show")).to eq("gem show [GEMNAME]")
    end

    it "handles only optional rest argument" do
      parser = ArgumentParser.build do
        rest :files
      end

      expect(parser.usage).to eq("[FILES...]")
      expect(parser.usage("cat")).to eq("cat [FILES...]")
    end

    it "handles only required rest argument" do
      parser = ArgumentParser.build do
        rest :files, min: 3
      end

      expect(parser.usage).to eq("<FILES...>")
    end
  end

  it "handles empty schema" do
    parser = ArgumentParser.build do; end

    expect(parser.usage).to eq("")
    expect(parser.usage("prog")).to eq("prog")
  end
end
