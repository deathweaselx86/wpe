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
    @output_csv = CSV.open(output_filepath, "w", 
                           write_headers: true, headers: OUTPUT_HEADER)
    
    # It's much more performant to stream this file rather than opening it
    # and putting its contents in memory so we will do it this way.
    @input_file = input_filepath
  end

  def merge
    begin
      CSV.foreach(@input_file, headers: true, skip_blanks: true, converters: "Created On") do |row|
        output_row = process_row(row)
        @output_csv << output_row unless output_row.nil?
      end
    rescue ArgumentError
      raise RuntimeError, "Invalid input CSV file." 
    ensure
      @output_csv.close
    end 
  end

  def process_row(row)
    account_id, account_name, first_name, created_on = row[0], row[1], row[2], row[3]
    return nil if account_id.nil? || first_name.nil? || created_on.nil?
    response = get_response_for_account account_id
    [account_id, first_name, created_on, response["status"], response["created_on"]]
  end

  def get_response_for_account(account_id)
    wpe_uri = "#{WPE_API}#{account_id}"
    resp = HTTParty.get wpe_uri
    
    if resp.response.is_a? Net::HTTPOK
      resp.parsed_response
    elsif resp.response.is_a? Net::HTTPNotFound
      {"status"=> "not found", "created_on"=> nil}
    else
      STDERR.puts "Request to #{wpe_uri} resulted in a #{resp.response.code} status code."
      {"status"=> "api error", "created_on"=> nil}
    end
  end

  private
  
  def configure_csv
    # Convert input date so the dates in our output file will be consistent.
    CSV::Converters["Created On"] = lambda do |field|
      Date.strptime(field, "%m/%d/%y") rescue field
    end
  end

  def validate_input_file(input_filepath)
    raise RuntimeError, "Input file doesn't exist." unless File.exist? input_filepath
  end

  def validate_output_file(output_filepath)
    output_directory = get_parent_directory output_filepath
    raise RuntimeError, "Output file cannot be written." unless File.writable? output_directory
  end

  def get_parent_directory(filepath)
    # Remove file from path to get its directory
    pathbits = filepath.split File::SEPARATOR
    pathbits[0...pathbits.length-1].join File::SEPARATOR
  end
end


# Is this being run as a script?
# This is here so we can require this file for testing.
if __FILE__ == $0
  WpeMerge.new(*ARGV).merge
end
