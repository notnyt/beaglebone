#!/usr/bin/env ruby
require 'beaglebone'
require 'pp'

include  Beaglebone

#analog testing
#oo methods

#analog read
p9_33 = AINPin.new(:P9_33)
loop do
  puts p9_33.read
  sleep 0.01
end

exit

#waiting for analog input change
p9_33 = AINPin.new(:P9_33)
pp p9_33.wait_for_change(10, 0.01)
pp p9_33.wait_for_change(10, 0.01)
pp p9_33.wait_for_change(10, 0.01)


#background analog input with callback

#wait for threshold
callback = lambda { |pin, mv_last, mv, state_last, state, count|
  puts "[#{count}] #{pin} #{state_last} -> #{state}     #{mv_last} -> #{mv}"
}
p9_33 = AINPin.new(:P9_33)
p9_33.run_on_threshold(callback, 400, 1200, 5, 0.001)

sleep 5
p9_33.stop_wait

pp p9_33.wait_for_threshold(200, 1600, 100, 0.01)
pp p9_33.wait_for_threshold(200, 1600, 100, 0.01)
pp p9_33.wait_for_threshold(200, 1600, 100, 0.01)

#wait for change
callback = lambda { |pin, mv_last, mv, count| puts "[#{count}] #{pin} #{mv_last} -> #{mv}" }

p9_33 = AINPin.new(:P9_33)

p9_33.run_on_change(callback, 10, 0.1)
sleep 5
p9_33.stop_wait

exit



#procedural methods

#analog read
loop do
  puts AIN.read(:P9_33)
  sleep 0.01
end
exit

#wait for analog input to hit a certrain threshold limit
pp AIN.wait_for_threshold(:P9_33, 200, 1600, 100, 0.01)
pp AIN.wait_for_threshold(:P9_33, 200, 1600, 100, 0.01)
pp AIN.wait_for_threshold(:P9_33, 200, 1600, 100, 0.01)
pp AIN.wait_for_threshold(:P9_33, 200, 1600, 100, 0.01)
pp AIN.wait_for_threshold(:P9_33, 200, 1600, 100, 0.01)
exit

#waiting for analog input change
pp AIN.wait_for_change(:P9_33, 10, 0.01)
pp AIN.wait_for_change(:P9_33, 10, 0.01)
pp AIN.wait_for_change(:P9_33, 10, 0.01)

exit

#background analog input
callback = lambda { |pin, mv_last, mv, count| puts "[#{count}] #{pin} #{mv_last} -> #{mv}" }
AIN.run_on_change(callback, :P9_33, 10, 0.1)
sleep 5
AIN.stop_wait(:P9_33)

#run when reaching a certain threshold
callback = lambda { |pin, mv_last, mv, state_last, state, count|
  puts "[#{count}] #{pin} #{state_last} -> #{state}     #{mv_last} -> #{mv}"
}
AIN.run_on_threshold(callback, :P9_33, 400, 1200, 5, 0.001)
loop do sleep(4000);end

exit
