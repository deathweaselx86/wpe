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
    CSV.foreach(@input_file, converters: "Created On") do |row|
      account_id = row[0]
      account_name = row[1]
      first_name = row[2]
      created_on = row[3]

      # TODO: Assume that we skip rows if account_id is not usable.
      next if account_id.nil?
      
      response = get_response_for_account(account_id)
      
      # TODO: Assume that 404s or other bad responses get skipped.
      next if response.nil? 
      # TODO: This output needs to be formatted.
      output_row = [account_id, first_name, created_on, response["status"],  response["created_on"]]
      @output_csv << output_row
    end
    @output_csv.close 
  end

  private

  def get_response_for_account(account_id)
    # TODO: What to do when the API returns something other than a 404 or a 200?
    wpe_uri = "#{WPE_API}#{account_id}"
    resp = HTTParty.get wpe_uri
    
    if resp.response.is_a? Net::HTTPOK
      resp.parsed_response
    elsif resp.response.is_a? Net::HTTPNotFound
      # I guess it's ok to silently fail on a 404
      nil
    else
      STDERR.puts "Request to #{wpe_uri} resulted in a #{resp.response.code} status code."
      nil
    end
  end

  def configure_csv
    # Automatically convert the created on field to a date object so we can convert it 
    # to the format we need it to be in 
    # TODO: Figure out what the final date format should be
    CSV::Converters["Created On"] = lambda do |field|
      Date.strptime(field, "%m/%d/%y") rescue field
    end
  end

  def validate_input_file(input_filepath)
    raise RuntimeError, "Input file doesn't exist." unless File.exist? input_filepath
  end

  def validate_output_file(output_filepath)
    output_directory = get_parent_directory output_filepath
    raise RuntimeError, "Output file already exists." if File.exist? output_filepath
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
