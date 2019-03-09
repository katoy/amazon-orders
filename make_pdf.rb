
SPACE = ' '.freeze
WORK_DIR = './tmp'

Dir.glob("#{WORK_DIR}/order*.png").sort.each_slice(2).with_index do |a, idx|
  png = "#{WORK_DIR}/z_#{format('%03d.png', idx)}"
  puts "#{a} => z_#{'%03d.png' % (idx + 1)}"
  if a.size == 2
    system "convert #{a.join(SPACE)} -append #{png}"
  else
    system "convert #{a.join(SPACE)} #{png}"
  end
end

Dir.glob("#{WORK_DIR}/z_*.png").sort.each_slice(10).map.with_index do |ary, idx|
  pdf = "#{WORK_DIR}/#{'%03d.pdf' % (idx + 1)}"
  puts "#{pdf} <= #{ary}"
  system "pdfjam --paper a4paper --outfile #{pdf} #{ary.join(SPACE)}"
end
