require "pp"
require "fileutils"

if ARGV.size < 1 then
  puts "usage: decob.rb <cobfile>"
  exit
end


class Archived_file

  def initialize(data,fileend,filehandle)
    @filehandle = filehandle
    @filename = data[0].split("\\")
    @filestart = data[1]
    @fileend = fileend
    @filesize = @fileend - @filestart
  end

  def save(folder="")
    puts "Saving #{@filename.last}"
    begin
      outname = File.join(folder,@filename)
      FileUtils.mkdir_p(File.dirname(outname))
      out = File.new(File.join(folder,@filename),"w")
      @filehandle.seek(@filestart)
      out.write(@filehandle.read(@filesize))
      out.close
    rescue => e
      puts "Some error: #{e}"
      pp self
    end
  end
end

class Cob
  attr_accessor :files

  def initialize(filename)
    @file = File.new(filename) 
    parse
  end

  def parse
    count = @file.read(4).unpack("V").first
    @files = []
    count.times do
      @files << [@file.read(50).unpack("A50").first]
    end
    count.times do |index|
      @files[index] << @file.read(4).unpack("V").first
    end

    f = @files
    @files = []
    
    f.count.times do |index|
      fileend = (index < f.count ? @file.size : (f[index][1] - 1))
      @files << Archived_file.new(f[index],fileend,@file) 
    end
  end

  def extract(folder="")
    @files.each{|f| f.save(folder)}
  end
end

c = Cob.new(ARGV[0])
c.extract("extract")
