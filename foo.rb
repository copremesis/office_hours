
#!!"Su: Mo: 8:30-5:30 Tu: 8:30-5:30 We: 8:30-5:30 Th: 8:30-5:30 Fr: 8:30-5:30 Sa: 10-5".match(/^((Mo|Tu|We|Th?|Fr|Sa|Su):\s+(\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?|b\.a\.|\-\-)\s*)+$/)
#!!"Mo: 8:30-5:30 Tu: 8:30-5:30 We: 8:30-5:30 Th: 8:30-5:30 Fr: 8:30-5:30 Sa: 10-5".match(/^((Mo|Tu|We|Th?|Fr|Sa|Su):\s+(\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?|b\.a\.|\-\-)\s*)+$/)



def candidate?(str)
  !!str.match(/^((Mo|Tu|We|Th?|Fr|Sa|Su):\s+(\d{1,2}(:\d{2})?-\d{1,2}(:\d{2})?|b\.a\.|\-\-)\s*)+\s*$/)
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

#str = "Mo: 8:30-4:30 Tu: 8:30-4:30 We: 8:30-4:30 Th: 8:30-4:30 Fr: 8:30-4:30"
#str = "Mo: 8:30-4:30 Tu: 8:30-4:30 We: 8:30-4:30 Th: 8:30-4:30 Fr: 8:30-4:30 "
#str = "Mo: 8:30-4:30 Tu: 8:30-4:30 We: 8:30-4:30 Th: 8:30-4:30 Fr: 8:30-4:30 Sa:"

puts [candidate?(str), CompressHours.is_candidate_for_compression?(str)].inspect
compressor = CompressHours.new
compressor.compress_hours(pairify(str))

