require "chunky_png"
require "pp"
require "pry"

palette = {}
ARGV.each_slice(2) do |bw, sample|

  red = ChunkyPNG::Image.from_file bw
  sample = ChunkyPNG::Image.from_file sample

  red.pixels.each.with_index do |pixelvalue, i|
    px = ChunkyPNG::Color.parse(pixelvalue)
    sampled_color = sample.pixels[i]
    next if ChunkyPNG::Color.a(sampled_color) == 0
    if !palette[ChunkyPNG::Color.r(pixelvalue)]
      palette[ChunkyPNG::Color.r(pixelvalue)] = Hash.new(0)
    end
    palette[ChunkyPNG::Color.r(pixelvalue)][ChunkyPNG::Color.to_hex(sampled_color, false)] += 1
  end
end

palette = palette.sort

palette.map! do |ref, samples|
  sample = samples.sort_by{|x, y| y}.last.first
  [ref, sample]
end

pp Hash[palette]

