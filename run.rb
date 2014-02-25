require 'phonelib'
require 'pp'

#pp Phonelib.default_country
1.upto(50000) do
  phone = Phonelib.parse('0541234567', 'il')
end
=begin
pp phone.valid?
pp phone.country
pp phone.type
pp phone
pp phone.national
pp phone.international
=end
