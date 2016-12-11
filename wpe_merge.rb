# what are we doing here?
# invoked by wpe_merge.rb path/to/input.csv path/to/output.csv
# given an input  comma separated CSV with a header row Account ID, Account Name, First Name, Created On
# and a RESTful status API at http://interview.wpengine.io/v1/accounts/{id}
# that returns information in JSON format
# {"account_id" : 12345,
#  "status": "good",
#  "created_on": "2011-01-12" }
#
#  for each row of the input CSV, pull the account id,
#  call the RESTful API, merge the data from the API with the data in the input CSV, and create
#  an output CSV with the columns Account ID, First Name, Created On, Status, and Status Set On
require "csv"
require "date"
require "httparty"

class WpeMerge
  OUTPUT_HEADER = ["Account ID", "First Name", "Created On", "Status", "Status Set On"]
  WPE_API = ENV["WPE_API"] || "http://interview.wpengine.io/v1/accounts/"

  def initialize(input_filepath, output_filepath)
    output_filepath = File.absolute_path output_filepath

    validate_input_file input_filepath
    validate_output_file output_filepath
    
    configure_csv
    @output_csv = CSV.open(output_filepath, "w", headers: OUTPUT_HEADER)
    
    # It's much more performant to stream this file rather than opening it
    # and putting its contents in memory so we will do it this way.
    @input_file = input_filepath
  end

  def merge
    # Open input file
    CSV.foreach(@input_file, headers: true, converters: "Created On") do |row|
      output_row = process_row(row)
      @output_csv << output_row
    end
    @output_csv.close 
  end

  def process_row(row)
    nil_row = [nil, nil, nil, nil, nil]
    account_id, account_name, first_name, created_on = row[0], row[1], row[2], row[3]
    return nil_row if account_id.nil?
    response = get_response_for_account account_id
    [account_id, first_name, created_on, response["status"], response["created_on"]]
  end

  def get_response_for_account(account_id)
    wpe_uri = "#{WPE_API}#{account_id}"
    resp = HTTParty.get wpe_uri
    
    if resp.response.is_a? Net::HTTPOK
      resp.parsed_response
    elsif resp.response.is_a? Net::HTTPNotFound
      # I guess it's ok to silently fail on a 404
      {"status": "not found", "created on": nil}
    else
      STDERR.puts "Request to #{wpe_uri} resulted in a #{resp.response.code} status code."
      {"status": "api error", "created on": nil}
    end
  end

  private
  
  def configure_csv
    # Automatically convert the created on field to a date object so we can convert it 
    # to the format we need it to be in 
    # TODO: Figure out what the final date format should be
    CSV::Converters["Created On"] = lambda do |field|
      Date.strptime(field, "%m/%d/%Y") rescue field
    end
  end

  def validate_input_file(input_filepath)
    raise RuntimeError, "Input file doesn't exist." unless File.exist? input_filepath
  end

  def validate_output_file(output_filepath)
    output_directory = get_parent_directory output_filepath
    raise RuntimeError, "Output file cannot be written" unless File.writable? output_directory
  end

  def get_parent_directory(filepath)
    # Remove file from path to get its directory
    pathbits = filepath.split File::SEPARATOR
    pathbits[0...pathbits.length-1].join File::SEPARATOR
  end
end


# Is this being run as a script?
if __FILE__ == $0
  WpeMerge.new(*ARGV).merge
end
