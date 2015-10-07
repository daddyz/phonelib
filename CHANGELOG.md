## Upcoming Changes (unreleased)

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
