## Phonelib

[![Build Status](https://travis-ci.org/daddyz/phonelib.png?branch=master)](http://travis-ci.org/daddyz/phonelib)
[![Gem Version](https://badge.fury.io/rb/phonelib.png)](http://badge.fury.io/rb/phonelib)

Phonelib is a gem allowing you to validate phone number. All validations are based on [Google libphonenumber](http://code.google.com/p/libphonenumber/).
Currently it can make only basic validation and still not include all Google's library functions.

## Information

### RDoc

RDoc documentation can be found here
http://rubydoc.info/github/daddyz/phonelib/master/frames

### Bug reports

If you discover a problem with Evercookie gem, let us know about it.
https://github.com/daddyz/phonelib/issues

### Example application

You can see an example of phonelib model validation working in test/dummy application of this gem

## Getting started

Phonelib was written and tested on Rails >= 3.1. You can install it by adding in to your Gemfile with:

```ruby
gem 'phonelib'
```

Run the bundle command to install it.

### ActiveRecord Integration

This gem adds validator for active record.
Basic usage:
```ruby
validates :attribute, phone: true
```
This will enable Phonelib validator for field "attribute". This validator checks that passed value is valid phone number.
Please note that passing blank value also fails.

Additional options:
```ruby
validates :attribute, phone: { possible: true, allow_blank: true }
```
`possible: true` - enables validation to check whether the passed number is a possible phone number (not strict check).
Refer to [Google libphonenumber](http://code.google.com/p/libphonenumber/) for more information on it.

`allow_blank: true` - when no value passed then validation passes

### Basic usage

To check if phone number is valid simply run:

```ruby
Phonelib.valid?('123456789') #returns true or false
```

Additional methods:

```ruby
Phonelib.valid? '123456789'      # checks if passed value is valid number
Phonelib.invalid? '123456789'    # checks if passed value is invalid number
Phonelib.possible? '123456789'   # checks if passed value is possible number
Phonelib.impossible? '123456789' # checks if passed value is impossible number
```

There is also option to check if provided phone is valid for specified country.
Country should be specified as two letters country code (like "US" for United States).

```ruby
Phonelib.valid_for_country? '123456789', 'XX'   # checks if passed value is valid number for specified country
Phonelib.invalid_for_country? '123456789', 'XX' # checks if passed value is invalid number for specified country
```

Additionally you can run:

```ruby
phone = Phonelib.parse('123456789')
```

Returned value is object of `Phonelib::Phone` class which have following methods:

```ruby
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

```ruby
phone.types # returns array of all valid types
phone.type  # returns first element from array of all valid types
```

Possible types:
* `:premiumRate` - Premium Rate
* `:tollFree` - Toll Free
* `:sharedCost` - Shared Cost
* `:voip` - VoIP
* `:personalNumber` - Personal Number
* `:pager` - Pager
* `:uan` - UAN
* `:voicemail` - VoiceMail
* `:fixedLine` - Fixed Line
* `:mobile` - Mobile
* `:fixedOrMobile` - Fixed Line or Mobile (if both mobile and fixed pattern matches)

Also you can fetch all matched countries

```ruby
phone.countries # returns array of all matched countries
phone.country   # returns first element from array of all matched countries
```

Phone class has following attributes

```ruby
phone.original        # string that was passed as phone number
phone.sanitized       # sanitized phone number (only digits left)
phone.national_number # phone number without country code
```

### How it works

Gem includes data from Google libphonenumber which has regex patterns for validations.
Valid patterns are more specific to phone type and country.
Possible patterns as usual are patterns with number of digits in number.