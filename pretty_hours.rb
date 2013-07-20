

require 'rubygems'
require 'json'
require 'awesome_print'
require 'pp'

load '/Users/robertortiz/ahl/engineering/pdflib/compress_hours.rb'


distinct_hours = JSON.parse(File.read('hours'))


sizes = distinct_hours.map {|x| x.size}
[sizes.min, sizes.max, sizes.size]
#nil

#hour condenser:
#ap distinct_hours

template1 = "M-F: 09:00  - 06:00  Except Tues and Thurs: 9:00  - 7:00 Sat: 10:00  - 05:00 Sun: Closed"
puts template1


def wtf?(message)
  begin
    yield
  rescue => e
    puts [message, e.backtrace].join(":\n")
  end
end

@dangling_words = lambda {|text|
  foo = text.dup
  while(foo.match(/((Mo|Tu|We|Th|Fr|Sa|Su|):|b\.a\.)$/))
    foo.sub!(/((Mo|Tu|We|Th|Fr|Sa|Su|):|b\.a\.)$/, '')
  end
  foo
}

@rm_apps_n_clsd = lambda {|text|
   text.gsub(/\w{2}:\s+(b\.a\.|--)/, '').strip
}

@create_spacing = lambda {|text|
  foo = text.dup
  while(foo.match /(\w{2}:)(\d+)/)
    foo.sub!(/(\w{2}:)(\d+)/,[$1, $2].join(' '))
  end
  foo
}

@fix_whack_ranges = lambda {|text|
  foo = text.dup
  while(foo.match /(\d{1,2})\s*-\s+(\d{1,2})\b/)
    foo.sub!(/(\d{1,2})\s*-\s+(\d{1,2})/, [$1, $2].join('-'))
    #puts foo
  end
  foo
}


@remove_useless_text = lambda {|text|
  text = @create_spacing.call(text)
  text = @fix_whack_ranges.call(text)
  words = text.split(/\s/)
  rez = words.map {|word|
    case word
    when /((Mon?|Tue?|Wed?|Thu?|Fri?|Sat?|Sun?):|\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?[,]?|\s*-+\s*|[A-Za-z]+-[A-Za-z]+[,:]?|[^ ]*(Tu?|T[Hh]|W|F|M)[^ ]*|b\.a\.)/
      $1
    else
      #puts 'omitting ...' + word
      ''
    end
  }.join(' ').squeeze(' ').strip
  rez
}

@is_candidate_for_compression = lambda {|str|
  !!str.match(/^((Mo|Tu|We|Th|Fr|Sa|Su):\s+(\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?|b\.a\.|\-\-)\s*)+$/)
}

def pretty(hours)
  foo = hours.dup || ''
  reggies = {     #in                                         #out
    :clsd_day => [/(closed)\s((sun|mon|tue|wed|thu|fri)\w*ay)/i, [$2, $1].join(' ')],
    :tus_sun =>  [/Tu-Sun/, 'T-Su:'],
    :fri_sat =>  [/F-Sat/, 'F-St:'],
    :tue_sat =>  [/Tu-Sat/, 'T-St:'],
    :mon_sat =>  [/M-Sat/, 'M-St:'],
    :mon_fri => [/Mon\w*-Fri\w*/, 'M-F:'],
    :mon_fri => [/M\w*-Sun\w*/, 'M-F:'],
    :sat_sun => [/Sat\.?-Sun/, 'Sa-Su:'],
    #abbrevated or removed items
    :range => [/wed-fri/i, 'W-F'],
    :saturday =>  [/sat\w*['s]*[\.,:]?/i,     ', Sa:'],
    :monday   =>  [/mon\w*['s]*[\.,:]?/i,     ', Mo:'],
    :sunday   =>  [/sun\w*['s]*[\.,:]?/i,     ', Su:'],
    :tuesday  =>  [/tue\w*['s]*[\.,:]?/i,     ', Tu:'],
    :wednesday=>  [/wed\w*['s]*[\.,:]?/i,     ', We:'],
    :thursday =>  [/thu\w*['s]*[\.,:]?/i,     ', Th:'],
    :friday   =>  [/fri\w*['s]*[\.,:]?/i,     ', Fr:'],
#    :and      =>  [/and/i,                   '&'],
    :exc_holi =>  [/exc\w*\sholi/i,          ''],
    :except =>    [/exc\w*(\sions:)?/i,                ''],
    :closed =>    [/clo\w*/i,                '--'],
    :OO     =>    [/:00/,                    ''],
    :pre_O  =>    [/\s0/,             ' '],
#    :not_sp =>    [/not\ssp\w*/i,    '--'],
    :am_pm  =>    [/(\s*(am|pm)\s*)/i,       ''],
    :by_app =>    [/by\s+app\w*/i,    'b.a.'],
    :to => [/\bto\b/, ' - '],
#    :call_4 =>    [/call for app\w*/i,          'by app. '],
    #forseen ragnes
  }
  reggies.each {|name, substitution_replacement|
    #ap substitution_replacement
    s, r, = substitution_replacement
    case(name)
    when :_24_hours
      foo = (!!foo.match(s))? 'Open 24 hours.' : foo
    else
      wtf?(name) {
        #puts r
        foo.gsub!(s,r)
      }
    end
  }
  res = @remove_useless_text.call(foo.squeeze(' ').squeeze(':'))
  #puts '###' + res
  if @is_candidate_for_compression.call(res.gsub(/,/, ''))
    #puts res
    res = @compress_hours.call(@pairify.call(res))
  end
  res = @rm_apps_n_clsd.call(res)
  @dangling_words.call(res)
end

#x = {template1 => pretty(template1)}
#ap x
x = {}
distinct_hours.each {|hours|
  x[hours] = pretty(hours)
}
#pp x
nil

=begin
#sort by largest
z = {}
x.each {|k,v|
  z[k] = v if x.map {|k,v| v.size}.max
}
=end

File.open('/tmp/bar.html', 'w') {|fd|
  fd.puts '<html><body><table style="font-size:x-small; border=\'1px solid black\'">'
  #fd.puts x.values.map {|hours| "<h6> #{hours} </h6>" }.join("\n")
  fd.puts x.map {|before, after| "<tr><td>#{before}</td><td>#{after}</td></tr>" }
  fd.puts '</table></body></html>'
}




test1 = {
  :in => 'M-F 8:30-5:30, Sat 10-2, Closed Sun.',
  :out => 'M-F 8:30-5:30, Sa: 10-2, Su: --'
  #"M-F 8:30-5:30, Sa: 10-2, -- Su:" we need a closed weekday switcher
}

test2 = {
  :in => 'M-F: 10:00 - 06:00 Except Tuesday 10:00 - 7:00Sat: 10:00 - 05:00 Sun: 12:00 - 05:00 ',
 #:out => 'M-F: 10-6, Tu: 10-7, Sa: 10-5, Su: 12-5'
  :out => 'M-F: 10-6 Tu: 10-7, Sa: 10-5 Su: 12-5'
}

test3 = {
  :in => 'M-Sat 10-7, Sun 10-5',
  :out => 'M-St: 10-7, Su: 10-5'
}

test4 = {
  :in => 'Monday 8:30AM-5:30PM Tuesday 9:00AM-6:00PM Wednesday 8:30AM-5:30PM Thursday 8:30AM-5:30PM Friday 8:30AM-5:30PM Saturday 10:00AM-5:00PM ',
  #:out => 'Mo: 8:30-5:30 Tu: 9-6 We: 8:30-5:30 Th: 8:30-5:30 Fr: 8:30-5:30 Sa: 10-5'
  :out => "Mo:&W-F: 8:30-5:30 Tu: 9-6 Sa: 10-5"
}

test5 = {
  :in => 'M-F: 08:30 - 05:30 Except DO NOT SHOW AFTER DARKSat: 10:00 - 05:00 Sun: 12:00 - 04:00',
  :out => 'M-F: 8:30-5:30 Sa: 10-5 Su: 12-4'
}

test6 = {
  :in => 'M-F: 8:30- 5:00 Evenings and Saturday by Appointm',
  :out => "M-F: 8:30-5 Sa: b.a."
}

test7 = {
  :in => 'M-F 8:30-5 Sat.10-2:00',
  :out => 'M-F 8:30-5 Sa: 10-2'
}

test8 = {
  :in => 'SUN 09:00 AM to 05:30 PM, MON 09:00 AM to 05:30 PM, TUES 09:00 AM to 05:30 PM, WED 09:00 AM to 05:30 PM, THURS 09:00 AM to 05:30 PM, FRI 09:00 AM to 05:30 PM, SAT 09:00 AM to 05:30 PM',
  :out => 'M-Su: 9-5:30'
}


def verify(test)
  res = pretty(test[:in])
  puts [res, test[:out]].inspect
  res == test[:out]
end

puts verify(test1)
puts verify(test2)
puts verify(test3)
puts verify(test4)
puts verify(test5)
puts verify(test6)
puts verify(test7)
puts verify(test8)
