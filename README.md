# WP Engine Coding Exercise

This code takes an input CSV with some account information, uses it to gather more 
information from a WP Engine API, and merges the resulting information in an output CSV. 


## Technologies
Ruby 2.2 (but should work on version 2.0 or greater)

Gems:
* csv (for CSV parsing)
* httparty (HTTP client)
* rspec (for testing)
* webmock (for HTTP stubbing)

This was built using OS X El Capitan.

## Building
Ruby should come with most Linux distributions and OS X.
1. `gem install bundler`
1. `bundle install`

You're done!

## Testing
After installation, run `bundle exec rspec` from the source root.

## Running

`./wpe_merge <input_file> <output_file>`

Your input CSV should be comma delimited and in UTF-8 format.
