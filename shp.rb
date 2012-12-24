require "pry"
require "chunky_png"
require "json"
# See asc1-techinfo/SHP.htm

module ByteHelpers
  def next_uint32
    @io.read(4).unpack("V").first
  end

  def next_uint16
    @io.read(2).unpack("v").first
  end

  def next_int32
    int = next_uint32
    if int & 0x8000_0000 == 0x8000_0000
      int - 0x1_0000_0000
    else
      int
    end
  end

  def next_byte
    @io.read(1).unpack("C").first
  end
end

class SHP

  include ByteHelpers

  def initialize io, verbose = true
    @io = io
    @verbose = verbose

    read_magic
    check_magic
    read_image_count
    read_offsets
    read_images
  end


  class Image

    include ByteHelpers

    def initialize offset, io, verbose
      @io = io
      @verbose = verbose
      @offset = offset

      @io.seek(@offset[:image])
      read_header
      set_palette
      decode_lines
    end

    def set_palette
      if @offset[:palette] == 0
        @palette = Hash.new(0) # Default color is black
        default = eval(open("default_palette.hash").read)
        default = default.map {|k,v| [k,ChunkyPNG::Color.from_hex(v)]}
        @bg_color = 0
        @palette.merge! Hash[default]
      else
        raise "not implemented yet"
      end
    end

    # Width and height are one larger than the value in the header
    def read_header
      @height = next_uint16 + 1
      puts "Height: #{@height}" if @verbose

      @width = next_uint16 + 1
      puts "Width: #{@width}" if @verbose

      @yoffset = next_uint16
      @xoffset = next_uint16
      puts "Offsets: #{@xoffset}, #{@yoffset}" if @verbose

      @xstart = next_int32
      @ystart = next_int32
      puts "Start: #{@xstart}, #{@ystart}" if @verbose

      @xend = next_int32
      @yend = next_int32

      puts "End: #{@xend}, #{@yend}" if @verbose
    end

    def decode_rle rest
      #puts "Rest is #{rest}"
      byte = next_byte
      if (rest < 0)
        puts "Something went wrong, ending line."
        raise "FAILURE"
        return [[0],true]
      end
      if byte == 0
        #puts "Filling #{rest} with bg color..."
        return [Array.new(rest, @bg_color), true]
      end

      if byte == 1
        length = next_byte
        #puts "Filling length #{length} with bg color..."
        return [Array.new(length, @bg_color), false]
      end

      if byte & 0b0000_0001 == 0
        color = next_byte
        length = byte >> 1

        #puts "Filling #{length} with #{color}"
        return [Array.new(length, color), false]
      end

      if byte & 0b0000_0001 == 1
        length = byte >> 1
        #puts "Reading #{length} direct bytes"

        arr = []
        length.times do
          arr.push next_byte
        end
        return [arr, false]
      end
    end

    def decode_lines
      @lines = []
      @height.times do
        line = []
        ended = false
        while !ended do
          pixels, ended = decode_rle(@width - line.size)
          line += pixels
        end
        @lines.push(line)
      end
    end

    def to_png filename = "Image.png"
      png = ChunkyPNG::Image.new(@width, @height, ChunkyPNG::Color::TRANSPARENT)
      @lines.each.with_index do |line, y|
        line.each.with_index do |value, x|
          png[x,y] = @palette[value]
        end
      end
      png.save filename
    end

    def to_s

    end

  end

  def read_images
    @images = @offsets.map do |offset|
      Image.new(offset, @io, @verbose)
    end
  end

  def export_images folder, basename
    @images.each.with_index do |img, i|
      img.to_png(File.join(folder, basename + "_#{i}.png"))
    end
  end

  def read_magic
    @magic = next_uint32
  end

  def read_image_count
    @image_count = next_uint32
    puts "Images in file: #{@image_count}" if @verbose
  end

  def read_offsets
    @offsets = []
    @image_count.times do
      image = next_uint32
      palette = next_uint32
      obj = {image: image, palette: palette}
      @offsets.push obj
      puts "Read #{obj.inspect}" if @verbose
    end
    puts "Read #{@offsets.count} offsets..." if @verbose
  end

  def check_magic
    if @magic != 0x30312E31
      puts "Wrong magic, not a .shp file." if @verbose
      raise "WRONG MAGIC"
    else
      puts "Magic found, seems to be a shp file." if @verbose
    end
  end

  private

end


