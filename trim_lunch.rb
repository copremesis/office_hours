


require 'rubygems'
require 'awesome_print'



=begin
ap foo = {
  'm' => map_day('m'),
  't' => map_day('t'),
  'w' => map_day('w'),
  'th' => map_day('th'),
  'f' => map_day('f'),
  'sa' => map_day('sa'),
  'su' => map_day('su'),
}
=end

  



class TrimLunch
  attr_accessor :remove_lunch
  def initialize
    @tests = {
      :test1 => {
        :in => 'Tu 9-12, Tu 1:30-4, W 9-12, W 1:30-4, Th 9-12, Th 1:30-4, F 9-12, F 1:30-4',
        :out => 'Tu: 9-4, W: 9-4, Th: 9-4, F: 9-4'
      },
      :test2 => {
        :in => 'M 9-11 M 12-5, Tu 9-11 Tu 12-5, W 9-11 W 12-5, Th 9-11 Th 12-5, F 9-11 F 12-5, Sa: 12-1, Sa: 1:30-5',
        :out => 'M: 9-5, Tu: 9-5, W: 9-5, Th: 9-5, F: 9-5, Sa: 12-5'
      },
      :test3 => {
        :in => 'M 9-12, M 1-6, Tu 9-12, Tu 1-6, W 9-12, W 1-6, Th 9-12, Th 1-6, F 9-12, F 1-6',
        :out => 'M: 9-6, Tu: 9-6, W: 9-6, Th: 9-6, F: 9-6'
      },

      :test4 => {
        :in => 'M-Tu 8:30-5:30, W 8:30-12, W 2-5:30, Th-F 8:30-5:30, Sa: 10-2',
        :out => 'M-Tu: 8:30-5:30, W: 8:30-5:30, Th-F: 8:30-5:30, Sa: 10-2',
      },

      :test5 => {
        :in => 'M 10-1, M 2-6, Tu 10-1, Tu 2-6, W 10-1, W 2-6, Th 10-1, Th 2-6, F 10-1, F 2-6, Sa: 10-4, Su: 12-4',
        :out =>'M: 10-6, Tu: 10-6, W: 10-6, Th: 10-6, F: 10-6, Sa: 10-4, Su: 12-4'
      },
      :test6 => {
        :in => 'M 9:30-1, M 1:30-5:30, Tu 9:30-1, Tu 1:30-5:30, W 9:30-1, W 1:30-5:30, Th 9:30-1, Th 1:30-5:30, F 9:30-1, F 1:30-5:30, Sat 10-1:30, Sat 2-3',
        :out => 'M: 9:30-5:30, Tu: 9:30-5:30, W: 9:30-5:30, Th: 9:30-5:30, F: 9:30-5:30, Sat: 10-3'
      },
      :test7 => {
        :in => 'M 9-1 M 2-5:30 Tu 9-1 Tu 2-5 W 10-1 W 2-5:30 T 9-1 T 2-5:30 F 9-1 F 2-5:30 Sa: 10-1 Sa: 2-5:30',
        :out => 'M: 9-5:30, Tu: 9-5, W: 10-5:30, T: 9-5:30, F: 9-5:30, Sa: 10-5:30',
      },
      :test8 => {
        :in => 'Tu 9-1, Tu 2-6, W 9-1, W 2-6, Th 9-1, Th 2-6, F 9-1, F 2-6, Sat 9-1, Sat 2-6',
        :out => 'Tu: 9-6, W: 9-6, Th: 9-6, F: 9-6, Sat: 9-6'
      },

      :test9 => {
        :in => 'M 9-1, M 1:30-5:30, Tu 9-1, Tu 1:30-5:30, W 9-1, W 1:30-5:30, Th 9-1, Th 1:30-5:30, F 9-1, F 1:30-5:30, Sat 10-4',
        :out => 'M: 9-5:30, Tu: 9-5:30, W: 9-5:30, Th: 9-5:30, F: 9-5:30, Sat: 10-4',
      }
    }

    @pairify = lambda {|str|
      rez = []
      ss = []
      str.gsub(/,/, '').split(' ').each {|e|
        if ss.size == 2
          rez << ss
          ss = []
        end
        ss << e
      }
      rez << ss
      rez.map {|v| p,q = v; [p,q].join(' ')}.join(', ')
    }

    @remove_lunch = lambda {|str|
      h = {}
      @pairify.call(str.gsub(/,/, '')).split(/, /).each {|tuple|
        d,range = tuple.split(/\s/)
        d.gsub!(/[:]/, '')
        h[d] = h[d] || [] #initialize to array
        h[d].push(range)
      }
      h.each {|day, hours|
        if hours.size == 2 #only fix if there's more than one
          morning, afternoon = hours
          h[day] = [morning.split(/-/)[0], afternoon.split(/-/)[1]].join('-')
        end
      }
      h.map {|d,h| [d, h].join(': ')}.join(', ')
    }
  end

  def self.lunch_candidate?(str)
    tokens = str.split(/\s/)
    [/m\w*/i, /tu\w*/i, /w\w*/i, /th\w*/i, /fr\w*/i, /sa\w*/i, /su\w*/i].map {|regex|
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
    dup.squeeze(':')
  end

  def run_tests
    @tests.each {|name, test|
      puts ['in',  test[:in]].join(': ')
      if(TrimLunch.lunch_candidate?(test[:in]))
        res = @remove_lunch.call(test[:in])
        puts ['out',  res].join(': ')
        puts ['*out',  fix_day(test[:out])].join(': ')
        puts res == test[:out]
      else
        puts 'whoops'
      end
    }
  end

  def clean(str)
    fix_day(@remove_lunch.call(str))
  end

end

if __FILE__ == $0
  foo = TrimLunch.new
  foo.run_tests
  #puts foo.remove_lunch.call('M 9-1, M 2-6, Tu 9-1, Tu 2-6, W 9-1, W 2-6, Th 9-1, Th 2-6, F 9-1, F 2-6, Sat 9-1, Sat 2-6, Sun 9-1, Sun 2-6')
  puts foo.clean('M 9-1, M 2-6, Tu 9-1, Tu 2-6, W 9-1, W 2-6, Th 9-1, Th 2-6, F 9-1, F 2-6, Sat 9-1, Sat 2-6, Sun 9-1, Sun 2-6')
end

