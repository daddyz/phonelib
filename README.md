## Phonelib

[![Built in integration with JetBrains RubyMine](https://github.com/daddyz/phonelib/blob/master/icon_RubyMine.png?raw=true)](https://www.jetbrains.com/ruby/)
[![Gem Version](https://badge.fury.io/rb/phonelib.svg)](http://badge.fury.io/rb/phonelib)
[![Build Status](https://travis-ci.org/daddyz/phonelib.png?branch=master)](http://travis-ci.org/daddyz/phonelib)
[![](https://codeclimate.com/github/daddyz/phonelib/badges/coverage.svg)](https://codeclimate.com/github/daddyz/phonelib/coverage)
[![](https://codeclimate.com/github/daddyz/phonelib/badges/gpa.svg)](https://codeclimate.com/github/daddyz/phonelib)
[![Inline docs](http://inch-ci.org/github/daddyz/phonelib.svg?branch=master)](http://inch-ci.org/github/daddyz/phonelib)

Phonelib is a gem allowing you to validate phone number. All validations are based on [Google libphonenumber](https://github.com/googlei18n/libphonenumber).
Currently it can make basic validations and formatting to e164 international number format and national number format with prefix.
But it still doesn't include all Google's library functionality.

## Information

### Change Log

Change log can be found in repo's releases page
https://github.com/daddyz/phonelib/releases

### Bug reports

If you discover a problem with Phonelib gem, let us know about it.
https://github.com/daddyz/phonelib/issues

### Example application

You can see an example of ActiveRecord validation by phonelib working in spec/dummy application of this gem

## Getting started

Phonelib was written and tested on Rails >= 3.1. You can install it by adding in to your Gemfile with:

``` ruby
gem 'phonelib'
```

Run the bundle command to install it.

To set the default country (country names are [ISO 3166-1 Alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) codes), create a initializer in <tt>config/initializers/phonelib.rb</tt>:

``` ruby
Phonelib.default_country = "CN"
```

To use the ability to parse special numbers (Short Codes, Emergency etc.) you can set ```Phonelib.parse_special```. This is disabled by default

``` ruby
Phonelib.parse_special = true
```

To allow vanity phone numbers conversion you can set ```Phonelib.vanity_conversion``` to ```true```. This will convert characters in passed phone number to their numeric representation (800-CALL-NOW will be 800-225-5669).

``` ruby
Phonelib.vanity_conversion = true
```

To disable sanitizing of passed phone number (keeping digits only)

``` ruby
Phonelib.strict_check = true
```

To change sanitized symbols on parsed number, so non-specified symbols won't be wiped and will fail the parsing

``` ruby
Phonelib.sanitize_regex = '[\.\-\(\) \;\+]'
```

To disable sanitizing of double prefix on passed phone number

```ruby
Phonelib.strict_double_prefix_check = true
```

To set different extension separator on formatting, this setting doesn't affect parsing. Default setting is ';'

``` ruby
Phonelib.extension_separator = ';'
```

To set symbols that are used for separating extension from phone number for parsing use ```Phonelib.extension_separate_symbols``` method. Default value is '#;'. In case string is passed each one of the symbols in the string will be treated as possible separator, in case array was passed each string in array will be treated as possible separator.

``` ruby
Phonelib.extension_separate_symbols = '#;'           # for single symbol separator
Phonelib.extension_separate_symbols = %w(ext # ; extension) # each string will be treated as separator
```

In case you need to overwrite some Google's libphonenumber library data, you need to assign file path to this setter. File should be Marshal.dump'ed with existing structure like in ```Phonelib.phone_data```. Gem is simply doing ```merge``` between hashes.

``` ruby
Phonelib.override_phone_data = '/path/to/override_phone_data.dat'
```

In case phone number that was passed for parsing has "+" sign in the beginning, library will try to detect a country regarding the provided one.

### ActiveRecord Integration

This gem adds validator for active record.
Basic usage:

``` ruby
validates :attribute, phone: true
```

This will enable Phonelib validator for field "attribute". This validator checks that passed value is valid phone number.
Please note that passing blank value also fails.

Additional options:

``` ruby
validates :attribute, phone: { possible: true, allow_blank: true, types: [:voip, :mobile], country_specifier: -> phone { phone.country.try(:upcase) } }
```

<tt>possible: true</tt> - enables validation to check whether the passed number is a possible phone number (not strict check).
Refer to [Google libphonenumber](http://code.google.com/p/libphonenumber/) for more information on it.

<tt>allow_blank: true</tt> - when no value passed then validation passes

<tt>types: :mobile</tt> or <tt>types: [:voip, :mobile]</tt> - allows to validate against specific phone types patterns,
if mixed with <tt>possible</tt> will check if number is possible for specified type

<tt>countries: :us</tt> or <tt>countries: [:us, :ca]</tt> - allows to validate against specific countries, 
if mixed with <tt>possible</tt> will check if number is possible for specified countries

<tt>country_specifier: :method_name</tt> or <tt>country_specifier: -> instance { instance.country.try(:upcase) }</tt> - allows to specify country for validation dynamically for each validation. Usefull when phone is stored as national number without country prefix.

<tt>extensions: false</tt> - set to perform check for phone extension to be blank

### Basic usage

To check if phone number is valid simply run:

``` ruby
Phonelib.valid?('123456789') # returns true or false
```

Additional methods:

``` ruby
Phonelib.valid? '123456789'      # checks if passed value is valid number
Phonelib.invalid? '123456789'    # checks if passed value is invalid number
Phonelib.possible? '123456789'   # checks if passed value is possible number
Phonelib.impossible? '123456789' # checks if passed value is impossible number
```

There is also option to check if provided phone is valid for specified country.
Country should be specified as two letters country code (like "US" for United States).
Country can be specified as String <tt>'US'</tt> or <tt>'us'</tt> as well as symbol <tt>:us</tt>.

``` ruby
Phonelib.valid_for_country? '123456789', 'XX'   # checks if passed value is valid number for specified country
Phonelib.invalid_for_country? '123456789', 'XX' # checks if passed value is invalid number for specified country
```

Additionally you can run:

``` ruby
phone = Phonelib.parse('123456789')
phone = Phonelib.parse('+1 (972) 123-4567', 'US')
```

You can pass phone number with extension, it should be separated with <tt>;</tt> or <tt>#</tt> signs from the phone number.

Returned value is object of <tt>Phonelib::Phone</tt> class which have following methods:

``` ruby
# basic validation methods
phone.valid?
phone.invalid?
phone.possible?
phone.impossible?

# validations for countries
phone.valid_for_country? 'XX'
phone.invalid_for_country? 'XX'
```

You can also fetch matched valid phone types

``` ruby
phone.types          # returns array of all valid types
phone.type           # returns first element from array of all valid types
phone.possible_types # returns array of all possible types
```

Possible types:
* <tt>:premium_rate</tt> - Premium Rate
* <tt>:toll_free</tt> - Toll Free
* <tt>:shared_cost</tt> - Shared Cost
* <tt>:voip</tt> - VoIP
* <tt>:personal_number</tt> - Personal Number
* <tt>:pager</tt> - Pager
* <tt>:uan</tt> - UAN
* <tt>:voicemail</tt> - VoiceMail
* <tt>:fixed_line</tt> - Fixed Line
* <tt>:mobile</tt> - Mobile
* <tt>:fixed_or_mobile</tt> - Fixed Line or Mobile (if both mobile and fixed pattern matches)
* <tt>:short_code</tt>
* <tt>:emergency</tt>
* <tt>:carrier_specific</tt>
* <tt>:sms_services</tt>
* <tt>:expanded_emergency</tt>
* <tt>:no_international_dialling</tt>
* <tt>:carrier_services</tt>
* <tt>:directory_services</tt>
* <tt>:standard_rate</tt>
* <tt>:carrier_selection_codes</tt>
* <tt>:area_code_optional</tt>

Or you can get human representation of matched types

``` ruby
phone.human_types # return array of human representations of valid types
phone.human_type  # return human representation of first valid type
```

Also you can fetch all matched countries

``` ruby
phone.countries       # returns array of all matched countries
phone.country         # returns first element from array of all matched countries
phone.valid_countries # returns array of countries where phone was matched against valid pattern
phone.valid_country   # returns first valid country from array of valid countries
phone.country_code    # returns country phone prefix
```

Also it is possible to get formatted phone number

``` ruby
phone.international      # returns formatted e164 international phone number
phone.national           # returns formatted national number with national prefix
phone.area_code          # returns area code of parsed number or nil
phone.local_number       # returns local number
phone.extension          # returns extension provided with phone
phone.full_e164          # returns e164 phone representation with extension
phone.full_international # returns formatted international number with extension
```

You can pass <tt>false</tt> to <tt>national</tt> and <tt>international</tt> methods in order to get unformatted representaions

``` ruby
phone.international(false) # returns unformatted international phone
phone.national(false)      # returns unformatted national phone
```

You can get E164 formatted number

``` ruby
phone.e164 # returns number in E164 format
```

You can define prefix for ```international``` and ```e164``` related methods to get formatted number prefixed with anything you need.

``` ruby
phone.international('00')      # returns formatted international number prefixed by 00 instead of +
phone.e164('00')               # returns e164 represantation of a number prefixed by 00 instead of +
phone.full_international('00') # returns formatted international number with extension prefixed by 00 instead of +
phone.full_e164('00')          # returns e164 represantation of a number with extension prefixed by 00 instead of +
phone.international_00         # same as phone.international('00'). 00 can be replaced with whatever you need
phone.e164_00                  # same as phone.international('00') 
```

There is a ```to_s``` method, it will return ```e164``` in case number is valid and ```original``` otherwise

``` ruby
phone.to_s # returns number in E164 format if number is valid or original otherwise
```

You can compare 2 instances of ```Phonelib::Phone``` with ```==``` method or just use it with string

```ruby 
phone1 = Phonelib.parse('+12125551234') # Phonelib::Phone instance
phone2 = Phonelib.parse('+12125551234') # Phonelib::Phone instance
phone1 == phone2                        # returns true
phone1 == '+12125551234'                # returns true
phone1 == '12125551234;123'             # returns true
```

There is extended data available for numbers. It will return <tt>nil</tt> in case there is no data or phone is impossible.
Can return array of values in case there are some results for specified number

``` ruby
phone.geo_name # returns geo name of parsed phone
phone.timezone # returns timezone name of parsed phone
phone.carrier  # returns carrier name of parsed phone
```

Phone class has following attributes

``` ruby
phone.original        # string that was passed as phone number
phone.sanitized       # sanitized phone number (only digits left)
```

### How it works

Gem includes data from Google libphonenumber which has regex patterns for validations.
Valid patterns are more specific to phone type and country.
Possible patterns as usual are patterns with number of digits in number.

### Development and tests

Everyone can do whatever he wants, the only limit is your imagination.
Just don't forget to write test before the pull request.
In order to run test without Rails functionality simply use

```
bundle exec rake spec
```

If you want to run including Rails environment, you need to set <tt>BUNDLE_GEMFILE</tt> while running the spec task, for example:

```
BUNDLE_GEMFILE=gemfiles/Gemfile.rails-3.2.x bundle exec rake spec
```

Gemfiles can be found in <tt>gemfiles</tt> folder, there are gemfiles for Rails 3.1, 3.2, 4, 5 and 5.1.
