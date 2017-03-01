## Upcoming Changes (unreleased)

## 0.6.10 - March 1, 2017
- updated data
- added ```Phone.to_s``` method, it will return ```e164``` in case number is valid or ```original``` otherwise
- added ```Phonelib.vanity_conversion``` setting, that defines whether to convert chars in phone number to appropriate numbers. Default is ```false```

## 0.6.9 - January 18, 2017
- fixed missing spaces in ```geo_name``` method results
- added ```:country_specifier``` parameter to validator, allows to specify country for validation (PR #97)
- added ```Phonelib.override_phone_data``` for defining a file holding exceptions for google's libphonenumber library's data (PR #96)

## 0.6.8 - November 28, 2016
- updated data

## 0.6.6 - November 3, 2016
- allowing to pass ```strict: true``` to validator
- added ```raw_national``` method for returning unformatted national number part of international number

## 0.6.5 - August 25, 2016
- allowing + in the beginning of number when strict check is on

## 0.6.4 - August 25, 2016
- updated data

## 0.6.3 - August 8, 2016
- fixing to override default country when + passed in the beginning of phone
- fixed error when int passed as phone number
- fixed error when ```";"``` passed as phone number
- fixed ```area_code``` method behaviour
- changed documentation to yard

## 0.6.2 - June 14, 2016
- fixed bug in ```international``` method when no country can be defined

## 0.6.1 - June 4, 2016
- updated data
- added method ```full_national``` which returns national number with extension
- fixed methods returning formatted numbers with extension not to put ";" sign in case extension is empty
- fixed ```international``` and ```e164``` methods to return number with country code if it's not present in number

## 0.6.0 - April 20, 2016
- updated data
- fixed bad behaviour, when country valid regex didn't match, but some type's regex was matching
- added more strict behaviour when country passed - don't try to detect country when it was specified for parsing

## 0.5.6 - March 7, 2016
- updated data
- added flag ```Phonelib.strict_check``` to disable sanitizing of phone number being passed for parsing
- added boolean param for ```national``` and ```international``` methods, if ```false``` passed, it will return unformatted phone representation

## 0.5.5 - January 16, 2016
- updated data

## 0.5.4 - November 03, 2015
- fixed bug in validator for types when type is ```:fixed_or_mobile```
- added ```full_e164``` and ```full_international``` methods to return phone number with extensions
- added ```Phonelib.extension_separator=``` method to define extension separator while formatting
- added ```Phonelib.extension_separate_symbols=``` method to define extension separating symbols for parsing

## 0.5.2 - October 07, 2015
- Fixed parsing with national code for CN

## 0.5.1 - October 07, 2015
- Added setting to use special numbers types for phone parsing. Disabled by default. In order to enable use ```Phonelib.parse_special = true``` in initializer.
- Fixed behaviour of double country codes in phones for IN, DE, BR
- Updated phone data

## 0.5.0 - September 04, 2015
- Added method ```valid_country``` for returning country for parsed phone just in case phone number was valid
- Changed behavior of method ```country```, now it returns main country for international code in case there is such country, or first country from array
- Added ```local_number``` method to ```Phone```, returns local number without area code
- Added ```area_code``` method to ```Phone```, returns area code of phone or nil if none present for parsed number
- Added ```extension``` method to ```Phone```, returns extension passed for parsing after ```#``` or ```;``` signs
- Updated phones data

## 0.4.9 - July 28, 2015

- Parsing of phone may return type ```:fixed_or_mobile``` even when patterns are different but valid for both ```:mobile``` and ```:fixed_line```. Previously it could be only when patterns match
- Added changelog

## 0.4.8 - July 27, 2015

- Updated data and added test for TT phone
