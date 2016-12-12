require 'spec_helper'
require_relative '../wpe_merge'

RSpec.describe WpeMerge do
  describe "initialize" do
    it "errors with too few arguments" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv") }.
               to raise_error(ArgumentError, "wrong number of arguments (1 for 2)")
    end

    it "errors with too many arguments" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv", 
                            "output.csv", "more_output.csv") }.
                to raise_error(ArgumentError, "wrong number of arguments (3 for 2)")
    end

    it "does not error with two arguments" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv",
                            "spec/fixtures/foo.csv") }.to_not raise_error
    end

    it "errors if the input file does not exist" do
      expect{ WpeMerge.new("spec/fixtures/nonexistent.csv", 
                           "spec/fixtures/foo.csv") }.
               to raise_error(RuntimeError, "Input file doesn't exist.") 
    end

    it "errors if the output file directory cannot be written to" do
      expect { WpeMerge.new("spec/fixtures/happy_input.csv", "/output.csv") }.
                to raise_error(RuntimeError, "Output file cannot be written.")
    end
  end

  describe "#merge" do
    let(:lex_output){ ["12345","Lex","2011-1-12","good","2011-01-12"] }
    let(:victor_output){ ["8172","Victor","2014-11-19","closed","2015-09-01"] }
    it "errors if the input file is not a CSV" do
      merger = WpeMerge.new("spec/fixtures/baby-alligator.jpg",
                            "spec/fixtures/foo.csv")
      expect { merger.merge }.to raise_error(RuntimeError, "Invalid input CSV file.")
    end

    it "errors if the input file is not encoded in UTF-8" do
      merger = WpeMerge.new("spec/fixtures/latin1.csv",
                            "spec/fixtures/foo.csv")
      expect { merger.merge }.to raise_error(RuntimeError, "Invalid input CSV file.")
    end

    it "errors if the input file is malformed" do
      merger = WpeMerge.new("spec/fixtures/malformed.csv",
                            "spec/fixtures/foo.csv")
      expect { merger.merge }.to raise_error(CSV::MalformedCSVError)
    end
    
    it "puts output in the output csv" do
      headers = ["Account ID", "Account Name", "First Name", "Created On"]
      expect_any_instance_of(WpeMerge).to receive(:process_row).
        with(CSV::Row.new(headers, ["12345","lexcorp","Lex", 
                                    Date.strptime("1/12/11", "%m/%d/%y")])).
        and_return(lex_output)
      expect_any_instance_of(WpeMerge).to receive(:process_row).
        with(CSV::Row.new(headers,["8172","⌀⌁⌂⌃⌄⌅⌆⌇","Victor", 
                                   Date.strptime("11/19/14", "%m/%d/%y")])).
        and_return(victor_output)
      
      merger = WpeMerge.new("spec/fixtures/happy_input.csv",
                           "spec/fixtures/foo.csv")
      merger.merge
      output  = CSV.open("spec/fixtures/foo.csv")
      contents = output.read
      expect(contents).to include(lex_output, victor_output)
    end
  end

  describe "#process_row" do
    let (:not_enough_row) { [0,] }
    let (:ok_row) { [0, "foo", "Foo", "2011-01-01"] }
    let (:nil_row) { [nil, nil, nil, nil, nil] }
    let(:subject){ WpeMerge.new("spec/fixtures/happy_input.csv",
                                "spec/fixtures/foo.csv") }

    before do 
      allow_any_instance_of(WpeMerge).to receive(:get_response_for_account).
        and_return({"account_id" => 0, "status" => "good", 
                    "created_on" => "2015-01-01"})
    end

    it "returns nil if required information is missing" do
      expect(subject.process_row(nil_row)).to eq(nil)  
    end

    it "returns a complete row with good data" do
      expect(subject.process_row(ok_row)).to eq([0, "Foo", "2011-01-01", "good", "2015-01-01"])
    end
  end


  describe "#get_response_for_account" do
    let(:ok_response){ {"account_id"=>5, "status"=>"good", "created_on"=>"2011-01-12"} }
    let(:not_found_response){ {"status"=>"not found", "created_on"=> nil } }
    let(:error_response){ {"status"=>"api error", "created_on"=> nil } }
    let(:subject){ WpeMerge.new("spec/fixtures/happy_input.csv", 
                                "spec/fixtures/foo.csv") }
   
    it "returns a parsed response if API returns 200 response" do
      stub_request(:get, "#{WpeMerge::WPE_API}5").
        to_return(body: JSON.generate(ok_response),
                  headers: {"Content-Type" => "application/json" })   
        expect(subject.get_response_for_account(5)).to eq(ok_response)
    end

    it "returns a not found status if API returns 404 response" do
      stub_request(:get, "#{WpeMerge::WPE_API}5").
        to_return(status: 404)
      expect(subject.get_response_for_account(5)).to eq(not_found_response)
    end

    it "returns an api error status if API returns something other than 200 or 404" do
      stub_request(:get, "#{WpeMerge::WPE_API}5").
        to_return(status: 503)
      expect(subject.get_response_for_account(5)).to eq(error_response)
    end

    it "reports error to stderr if API returns something other than 200 or 404" do
      stub_request(:get, "#{WpeMerge::WPE_API}5").
        to_return(status: 503)
      output = "Request to #{WpeMerge::WPE_API}5 resulted in a 503 status code.\n"
      expect{ subject.get_response_for_account(5) }.to output(output).to_stderr_from_any_process
    end
  end
end
