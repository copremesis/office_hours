require File.join(Dir.pwd, 'compress_hours.rb')

class OfficeHours
  def initialize
    @reggies = {    #in                                             #out
      :to       =>  [/\b+to\b+/,                                    '-'],
      :clsd_day =>  [/(closed)\b((sun|mon|tue|wed|thu|fri)\w*ay)/i, [$2, $1].join(' ')],
      :tus_sun  =>  [/Tu-Sun/,                                      'T-Su:'],
      :fri_sat  =>  [/F-Sat/,                                       'F-St:'],
      :tue_sat  =>  [/Tu-Sat/,                                      'T-St:'],
      :mon_sat  =>  [/M-Sat/,                                       'M-St:'],
      :mon_fri  =>  [/mon\w*\-fri\w*/i,                             'M-F:'],
      :mon_sun  =>  [/M\w*-Sun\w*/,                                 'M-Su:'],
      :sat_sun  =>  [/Sat\.?-Sun/,                                  'Sa-Su:'],
      :range    =>  [/wed-fri/i,                                    'W-F'],
      :saturday =>  [/sat\w*['s]*[\.,:]?/i,                         ', Sa:'],
      :monday   =>  [/mon\w*['s]*[\.,:]?/i,                         ', Mo:'],
      :sunday   =>  [/sun\w*['s]*[\.,:]?/i,                         ', Su:'],
      :tuesday  =>  [/tue\w*['s]*[\.,:]?/i,                         ', Tu:'],
      :wednesday=>  [/wed\w*['s]*[\.,:]?/i,                         ', We:'],
      :thursday =>  [/thu\w*['s]*[\.,:]?/i,                         ', Th:'],
      :friday   =>  [/fri\w*['s]*[\.,:]?/i,                         ', Fr:'],
      :exc_holi =>  [/exc\w*\sholi/i,                               ''],
      :except   =>  [/exc\w*(\sions:)?/i,                           ''],
      :closed   =>  [/clo\w*/i,                                     '--'],
      :am_pm    =>  [/(\s*(a\.?m\.?|p\.?m\.?)\s*)/i,                ''],
      :OO       =>  [/:00[ap]?/,                                    ''],
      :pre_O    =>  [/\b0|^0/,                                      ' '],
      :by_app   =>  [/by\b+app\w*/i,                                'b.a.'],
#      :dangler   => [/^\w{2}:\s+(\w)/,                              "\\1"]
      
    }
  end

  def create_spacing(text)
    fix = text.dup
    while(fix.match /(\w{2}:)(\d+)/)
      fix.sub!(/(\w{2}:)(\d+)/,[$1, $2].join(' '))
    end
    fix
  end

  def fix_whack_ranges(text)
    fix = text.dup
    while(fix.match /(\d{1,2})\s*-\s+(\d{1,2})\b/)
      fix.sub!(/(\d{1,2})\s*-\s+(\d{1,2})/, [$1, $2].join('-'))
      #puts fix
    end
    fix
  end

  def remove_useless_text(text)
    text = create_spacing(text)
    text = fix_whack_ranges(text)
    words = text.split(/\s/)
    rez = words.map {|word|
      case word
      #when /((Mon?|Tue?|Wed?|Thu?|Fri?|Sat?|Sun?):|\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?[,]?|\s*-+\s*|[A-Za-z]+-[A-Za-z]+[,:]?|[^ ]*(Tu?|T[Hh]|We?|Fr?|Mo?)[^ ]*|b\.a\.)/
      when /((Mon?|Tue?|Wed?|Thu?|Fri?|Sat?|Sun?):|\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?[,]?|\s*-+\s*|[^ ]*(Tu?|T[Hh]|W|Fr?|Mo?)[^ hie]*|b\.a\.)/
        #puts 'keeping: ' + word
        $1
      else
        ''
      end
    }.join(' ').squeeze(' ').strip
    #puts rez
    rez
  end

  def lunch_candidate(str)
    tokens = str.split(/\s/)
    [/m\w*/i, /tu\w*/i, /we\w*/i, /th\w*/i, /fr\w*/i, /sa\w*/i, /su\w*/i].map {|regex|
      tokens.grep(regex).size
    }.include?(2)
  end

  def fix_day(str)
    dup = str.dup
    filter = {
      :mon => [/m\w*[^-]/i, 'Mo:'],
      :tue => [/tu/i, 'Tu:'],
      :wed => [/we?\w*[^-]/i, 'We:'],
      :thu => [/th/i, 'Th:'],
      :fri => [/fr?\w*[^-]/i, 'Fr:'],
      :sat => [/sa\w*[^-]/i, 'Sa:'],
      :sun => [/su\w*[^-]/i, 'Su:'],
    }
    filter.each {|name, subst|
      r, s = subst
      dup.gsub!(r, s)
    }
    rez = dup.squeeze(':')
    #dangling T:
    rez.sub!(/T:/, 'Th:') if !!rez.match(/Tu/) && !!rez.match(/T:/)
    rez
  end

  def remove_lunch(str)
    h = {}
    pairify(str.gsub(/,/, '') || '').split(/, /).each {|tuple|
      d,range = tuple.split(/\s/)
      d.gsub!(/[:]/, '')
      h[d] = h[d] || [] #initialize to array
      h[d].push(range)
    }
    h.each {|day, hours|
      if hours.size == 2 #only fix if there's more than one
        morning, afternoon = hours
        h[day] = [(morning || '').split(/-/)[0], (afternoon || '').split(/-/)[1]].join('-') 
      end
    }
    fix_day(h.map {|d,h| [d, h].join(': ')}.join(' ') || str)
  end

  def is_disaster(str, hours)
    case (!!str.match(/[mwfsu]+/i) ^ !!str.match(/\d+-\d*/) || str.size == 0 )
    when true
      File.open('/tmp/roberr', 'a') {|fd| fd.puts([hours, str].join(': ')) }
      'Call us'
    else
      str
    end
  end

  def parse(hours)
    fix = hours.dup || ''
    @reggies.each {|name, substitution_replacement|
      s, r, = substitution_replacement
      case(name)
      when :_24_hours
        fix = (!!fix.match(s))? 'Open 24 hours.' : fix
      else
        silent_death(name) {
          fix.gsub!(s,r)
        }
      end
      #puts [s.inspect, fix].inspect
    }
    res = remove_useless_text(fix.squeeze(' ').squeeze(':'))

    #Danglers
    res.gsub!(/,/, '')
    res.gsub!(/^\w{2}([:\-]*\s)+([MWTFS])/, "\\2") #leftmost
    res.gsub!(/\s+\w{2}:?\s*-?$/, '') #rightmost
    res.gsub!(/\w{2}:\s-\s/, '') #inner 
    res.strip!

    puts ['after parsing',res].join(': ')
    if lunch_candidate(res)
      #puts res
      res = remove_lunch(res)
      #puts res
      puts ['after trim lunch',res].join(': ')
    end

    
 
    if CompressHours.is_candidate_for_compression?(res.gsub(/,/, ''))
puts "YES!!!"
      compressor = CompressHours.new
puts res
puts "res = compressor.compress_hours(pairify(res))"
      res = compressor.compress_hours(pairify(res))
      puts ['after compression',res].join(': ')
    else
puts "cannot compress #{res}"
    end
    res = rm_apps_n_clsd(res)
    res = dangling_words(res)
    res = is_disaster(res, hours)
    #res.gsub(/0(\d)/, '\1')
    res.gsub(/^Sa-\s+/, '')
  end

  private

  def silent_death(message)
    begin
      yield
    rescue => e
      puts [message, e.backtrace].join("\n")
    end
  end

  def pairify(str)
    rez = []
    ss = []
    str.gsub(/,/, '').split(' ').each {|e|
      if ss.size ==2
        rez << ss
        ss = []
      end
      ss << e
    }
    rez << ss
    rez.map {|v| p,q = v; [p,q].join(' ')}.join(', ')
  end

  def dangling_words(text)
    fix = text.dup
    while(fix.match(/((Mo|Tu|We|Th|Fr|Sa|Su|):|b\.a\.|--?)\s*$/))
      fix.sub!(/((Mo|Tu|We|Th|Fr|Sa|Su|):|b\.a\.|--?)\s*$/, '')
    end
    fix
  end

  def rm_apps_n_clsd(text)
    text.gsub(/\w{1,2}:?\s*(b\.a\.|--)[^ ]*/, '').strip.gsub(/,/, '')
  end
end


if __FILE__ == $0
  require 'json'
  #distinct_hours = JSON.parse(File.read('hours'))
  distinct_hours = JSON.parse(File.read('rent_wiki_hours.json'))
  office_hours = OfficeHours.new
  x = {}
  distinct_hours.each {|hours|
    x[hours] = office_hours.parse(hours)
  }
  File.open('/tmp/bar.html', 'w') {|fd|
    fd.puts '<html><body><table style="font-size:x-small; border=\'1px solid black\'">'
    fd.puts x.map {|before, after| "<tr><td>#{before}</td><td>#{after}</td><td>#{(1.0 - after.size/before.size.to_f).round(2)}</td></tr>" }
    fd.puts '</table></body></html>'
  }
  #smoke test
  #puts OfficeHours.new.parse('M-F: 10:00 - 06:00 The White Sox never fell further than 21/2 games out of first place in 2008, thanks to their ability to surviSat: 10:00 - 05:00 Sun: 01:00 - 05:00')
  #puts OfficeHours.new.parse('M 9-11:30, M 12-5, Tu 9-11:30, Tu 12-5, W 9-11:30, W 12-5, Th 9-11:30, Th 12-5, F 9-11:30, F 12-5, Sat 12-1, Sat 1:30-5')
  #puts OfficeHours.new.parse('M-F: 09:00  - 05:00  Except Evenings by appointmentSat: By AppointmentSun: By Appointment')
  #puts OfficeHours.new.parse('09:00  - 05:00')

  #puts 'hi'
  #puts OfficeHours.new.parse('SUN Closed, MON 09:30 AM to 06:30 PM, TUES 09:30 AM to 06:30 PM, WED 09:30 AM to 06:30 AM, THURS 09:30 AM to 06:30 PM, FRI 08:30 AM to 05:30 PM, SAT 08:30 AM to 05:30 PM')
  #puts 'hi'
end


#puts [OfficeHours.new.parse('SUN 09:00 AM to 05:30 PM, MON 09:00 AM to 05:30 PM, TUES 09:00 AM to 05:30 PM, WED 09:00 AM to 05:30 PM, THURS 09:00 AM to 05:30 PM, FRI 09:00 AM to 05:30 PM, SAT 09:00 AM to 05:30 PM'), 'M-Su: 9-5:30'].inspect
#puts [OfficeHours.new.parse('SUN 09:00 AM to 05:30 PM, MON 09:00 AM to 05:30 PM, TUES 09:00 AM to 05:30 PM, WED 09:00 AM to 05:30 PM, THURS 09:00 AM to 05:30 PM, FRI 09:00 AM to 05:30 PM, SAT 09:00 AM to 05:30 PM'), 'M-Su: 9-5:30'].inspect

#puts [OfficeHours.new.parse('SUN call, MON 06:00 PM to 08:00 PM, TUES 06:00 PM to 08:00 PM, WED 06:00 PM to 08:00 PM, THURS 06:00 PM to 08:00 PM, FRI 06:00 PM to 08:00 PM, SAT call'), 'M-F 6-8 Sa-Su CALL'].inspect

#puts [OfficeHours.new.parse('SUN call, MON 08:30 AM to 05:30 PM, TUES 08:30 AM to 05:30 PM, WED 08:30 AM to 05:30 PM, THURS 08:30 AM to 05:30 PM, FRI 08:30 AM to 05:30 PM, SAT 10:00 AM to 05:00 PM'), 'M-F 8:30-5:30 Sa: 10-5'].inspect

#puts [OfficeHours.new.parse('SUN call, MON 08:30 AM to 04:30 PM, TUES 08:30 AM to 04:30 PM, WED 08:30 AM to 04:30 PM, THURS 08:30 AM to 04:30 PM, FRI 08:30 AM to 04:30 PM, SAT call'), 'M-F: 8:30-4:30'].inspect

#puts [OfficeHours.new.parse('SUN call, MON 09:00 AM to 05:30 PM, TUES 09:00 AM to 05:30 PM, WED 09:00 AM to 05:30 PM, THURS 09:00 AM to 05:30 PM, FRI 09:00 AM to 05:30 PM, SAT 0 AM: AM to 0 AM: AM'), 'M-F: 9-5:30'].inspect

puts [OfficeHours.new.parse('SUN call, MON 09:00 AM to 02:00 PM, TUES to , WED 09:00 AM to 02:00 PM, THURS to , FRI 09:00 AM to 02:00 PM, SAT call'), "M&W&F: 9-2"].inspect
