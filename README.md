# WP Engine Coding Exercise

This code takes an input CSV with some account information, uses it to gather more 
information from an API, and merges the information in an output. 
It's written with POSIX systems in mind.


## Technologies
Ruby :) This should work with any version of Ruby > 2.0. It was written 
using ruby 2.2 on OS X El Capitan.

## Building
1. Ruby should come with your Linux/OS X machine.
1. `gem install bundler`
1. `bundle install`
You're done!

## Testing
`bundle exec rspec`
This will only work from the source root.

## Running it

`./wpe_merge <input_file> <output_file>`

Your input CSV should be in UTF-8 format and your need to be able to 
write to wherever you're putting the output file.
