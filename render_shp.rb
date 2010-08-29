require "rubygems"
require "rubygame"

class Pallette
  def initialize(filename)
    @array = []
    File.open(filename).read.unpack("C768").each_slice(3) {|a| @array << a}
  end

  def to_s
    @array.count.to_s
    @array.map(&:to_s).join("\n")
  end

  def color(n)
    @array[n]
  end

  def render

  end
end

Rubygame.init

screen = Rubygame::Screen.open([160,160])
pallette = Pallette.new(ARGV[0])

0.upto(15) do |x|
  0.upto(15) do |y|
    screen.draw_box_s([x*10,y*10],[(x+1)*10,(y+1)*10],pallette.color((x*16) + y))
  end
end

screen.flip
while(true) do end
