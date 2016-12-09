require_relative '../wpe_merge'

# Things to test:
# For all paths:
#   1. Output header is correct
#   2. Expected information is present
#   3. Does not throw errors
#   4. Does not overwrite existing files
#
# For path where API is not available
#   1. Fails gracefully (how should it fail? what if it's intermittent?)
#
# For path where CSV has rows with missing data
#   1. Handles those gracefully (should it fail the whole thing? skip that row?)
#
# For path where CSV has rows corresponding to accounts that do not exist
#   1. Handles that (print doesn't exist? how to handle that?)
#
# For path where CSV has encoding issues
#   1. Handles that somehow (Do we know if we'll have encoding issues? Will it always be UTF-8?)
#
#


RSpec.describe WpeMerge do
  context "initialize" do
    before do
      allow(CSV).to receive(:open) # So we don't create files during this part of the test.

    end

    it "errors with too few arguments" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv") }.to raise_error(ArgumentError)
    end

    it "errors with too many arguments" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv", 
                            "output.csv", "more_output.csv") }.to raise_error(ArgumentError)
    end

    it "does not error with two arguments" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv",
                            "spec/fixtures/foo.csv") }.to_not raise_error
    end

    it "errors if the input file does not exist" do
      expect{ WpeMerge.new("spec/fixtures/nonexistent.csv", 
                           "spec/fixtures/nonexistent_output.csv") }.to raise_error(RuntimeError) 
    end

    it "errors if the output file exists already" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv",
                            "spec/fixtures/happy_output.csv") }.to raise_error(RuntimeError)
    end
  end
end
