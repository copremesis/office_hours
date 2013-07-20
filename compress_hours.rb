
class CompressHours

  def self.is_candidate_for_compression?(str)
    !!str.match(/^((Mo|Tu|We|Th?|Fr|Sa|Su):\s+(\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?|b\.a\.|\-\-)\s*)+\s*$/)
                              #lunches use T for thursday so this needs to allow this for compression
  end

  def initialize
    @day_flags = {
      'Mo:' => 1 << 0,
      'Tu:' => 1 << 1,
      'We:' => 1 << 2,
      'Th:' => 1 << 3,
      'Fr:' => 1 << 4,
      'Sa:' => 1 << 5,
      'Su:' => 1 << 6 
    }
  end

  def show_me_bits(flag)
    foo = flag
    day_codes = (0..6).map {|x| 1 << x}
    days = Array.new(6) {0}
    day_codes.reverse.each {|bit|
      if bit <= foo
        foo ^= bit
        days[day_codes.index(bit)] = 1
      end
    }
    days
  end

  def remove_subset_ranges(range_set)
    h = {}
    keys = []
    range_set.each {|set|
      s,e = set
      keys << s
      h[s] = e
    }
    min = keys.min
    h.delete_if {|k,v| k != min }
    h.map{|k,v| [k,v]}
  end

  def adjacency_ranges(bit_array)
    ones = []
    ranges = []
    flag = false
    bit_array.each_with_index {|bit, i|
      ones << i if bit == 1
    }
    ones.each { |d|
      ranges << [d, d+1] if  ones.include?(d+1) #two day
      ranges << [d, d+2] if  ones.include?(d+1) && ones.include?(d+2)
      ranges << [d, d+3] if  ones.include?(d+1) && ones.include?(d+2) && ones.include?(d+3)
      ranges << [d, d+4] if  ones.include?(d+1) && ones.include?(d+2) && ones.include?(d+3) && ones.include?(d+4)
      ranges << [d, d+5] if  ones.include?(d+1) && ones.include?(d+2) && ones.include?(d+3) && ones.include?(d+4) && ones.include?(d+5) 
      ranges << [d, d+6] if  ones.include?(d+1) && ones.include?(d+2) && ones.include?(d+3) && ones.include?(d+4) && ones.include?(d+5)  && ones.include?(d+6)
    }
    remove_subset_ranges(ranges)
  end

  def disjunct_days(code)
    disjunky = []
    map = ['M','T','W', 'TH', 'F', 'Sa', 'Su']
    show_me_bits(code).each_with_index {|bit, index|
      bit == 1 && (disjunky << index)
    }
    disjunky.map {|e|  map[e] }.join('&') + ':'
  end

  def day_range(range)
    map = ['M','T','W', 'TH', 'F', 'Sa', 'Su']
    s,e = range
    [map[s], map[e]].join('-') + ':'
  end

  def build_range_hash
    h = {}
    (0...6).each {|day_no|
      ((day_no+1)..6).each{ |next_day_index|
        h[(day_no..next_day_index).inject(0) {|s,k| s + 2**k}] = day_range([day_no,next_day_index])
      }
    }
    h
  end

  def compress_hours(str)
    consecutive_days = build_range_hash()
    x = str.split(/,\s*/)
    ranges = x.map {|item| item.split(/\s/, 2)[1] }.uniq
    days = x.map {|item| item.split(/\s/, 2)[0] }
    work_hash  = {}
    ranges.each {|range|
      work_hash[range] = x.reduce(0x0) {|s,item| 
        day_code =  ((!!item.match(range))? @day_flags[item.split(/\s/, 2)[0]] : 0)
        s | day_code.to_i
      }
    }
    day_codes = (0..6).map {|x| 1 << x}
    days = Array.new(6) {0}
    build = work_hash.map {|time, bitflag|
      ranges =  adjacency_ranges(show_me_bits(bitflag))
      x = ranges.map {|range| s,e = range; (s..e).inject(0x0) {|s, k| s | 1<<k} }
      f = []
      x.each { |v| f << bitflag - v; f << v}
      f << bitflag if x.empty?
      f.delete_if{|e| e==0} #remove any zeros? ... not sure why this works ... we don't need a zero in there ... 
      [f.map {|code| @day_flags.invert[code] ||  consecutive_days[code] || disjunct_days(code) || '' }.join('&'), time].join(' ')
    }.join(' ')
    return build
  end
end

