#
# A small collection of methods that are invoked by sinatra,
# but aren't core to our main application.
#
module Helpers

  #
  # Format the given number of seconds into something more friendly.
  #
  def seconds_to_ago( a )
    case a
    when 0 then
      'just now'
    when 1 then
      'a second ago'
    when 2..59 then
      a.to_s+' seconds ago'
    when 60..119 then
      'a minute ago' #120 = 2 minutes
    when 120..3540 then
      (a/60).to_i.to_s+' minutes ago'
    when 3541..7100 then
      'an hour ago' # 3600 = 1 hour
    when 7101..82800 then
      ((a+99)/3600).to_i.to_s+' hours ago'
    when 82801..172000 then
      'a day ago' # 86400 = 1 day
    when 172001..518400 then
      ((a+800)/(60*60*24)).to_i.to_s+' days ago'
    when 518400..1036800 then
      'a week ago'
    else
      ((a+180000)/(60*60*24*7)).to_i.to_s+' weeks ago'
    end
  end


  #
  # Given a date-string such as "2014-02-03 17:22:13 +0000" work out
  # how long ago that was.
  #
  def time_ago( str )
    # convert the given date to seconds-since-epoch
    past = Time.parse(str).to_i

    # convert the current date to seconds-since-epoch
    now = Time.now.to_i

    # Calculate the time-different in seconds.
    seconds = now - past

    # format that
    seconds_to_ago( seconds )
  end
end
