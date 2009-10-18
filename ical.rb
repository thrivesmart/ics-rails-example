# this uses the http://rubyforge.org/projects/icalendar gem.
# it's probably only testing on the 1.0.1 version (not the latest)

class Controller
  def action
    respond_to do |format|
      
      format.ics { render :text => @event.to_ics(params[:outlook] ? true : false) }
      
    end
  end
end

class ViewHelper

  def add_to_g_cal(event)
    "http://www.google.com/calendar/event?action=TEMPLATE&text=#{url_encode(event.name)}" + 
    "&dates=#{event.ics_start_datetime}%2f#{event.ics_end_datetime}" +
    "&details=#{url_encode(event.ics_description)}" + "&location=#{url_encode(event.ics_location)}"
  end
  
  def add_to_y_cal(event)
    "http://calendar.yahoo.com?v=60&VIEW=d" +
      "&TITLE=#{url_encode(event.name)}" +
      "&ST=#{event.ics_start_datetime}" +
      "&DUR=#{yahoo_duration(event)}" +
      "&DESC=#{url_encode(event.ics_details_str)}" +
      "&in_loc=#{url_encode(event.location_str)}"
  end
  
  def g_cal_subscribe(event)
    "http://www.google.com/calendar/render?cid=#{formatted_event_url(event, "ics")}"
  end
  
  def yahoo_duration(event)
    duration_sec = (event.utc_end_datetime - event.utc_start_datetime).round
    return 0 if duration_sec.nil? || duration_sec == 0
    
    duration_hrs = duration_sec / 3600
    duration_mins = duration_sec / 60 - (duration_hrs * 60)
    
    "#{format_yahoo_duration(duration_hrs)}" + "#{format_yahoo_duration(duration_mins)}"
  end
  
  def format_yahoo_duration(val)
    val < 10 ? "0#{val}": val
  end
  
end

class Model
  
  require 'icalendar'
  include Icalendar
  
  def to_ics(for_outlook = false)
    cal = Calendar.new
  
    event = Event.new
    event.dtstart ics_start_datetime, {:TZID => self.timezone }
    event.dtend ics_end_datetime, { :TZID => self.timezone }
    event.summary = self.name
  
    event.location = ics_location  
    event.url = ics_url
    event.description = ics_description
  
    cal.add_event(event)
    cal_out = cal.to_ical
    cal_out = cal_out.gsub('VERSION:2.0', '') if for_outlook

    cal_out
  end
  
  def ics_url
    "http://#{HOST_CONSTANT}/projects/#{self.project.to_param}/project_events/#{self.to_param}"
  end
  
  def ics_location
    (self.address1.blank? ? "" : "#{self.address1}, " ) +
      (self.address2.blank? ? "" : "#{self.address2}, ") +
      (self.city.blank? ?  "" : "#{self.city}, " ) +
      (self.state.blank? ? "" : self.state )
  end
  
  def ics_description
    "#{self.short_description}\n\n#{self.long_description}\n\nMore details at #{ics_url}"
  end
  
  def ics_start_datetime
    self.class.ics_datetime(self.utc_start_datetime) # Note: utc_start_datetime should be different than the local time of the event
  end
 
  def ics_end_datetime
    self.class.ics_datetime(self.utc_end_datetime) # Note: utc_end_datetime should be different than the local time of the event
  end
    
  def self.ics_datetime(utc_time_obj)
    time_obj.strftime('%Y%m%dT%H%M%SZ')
  end
end