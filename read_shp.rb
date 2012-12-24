require "./shp.rb"

ARGV.each do |arg|
  begin
    shp = SHP.new(open(arg))
    shp.export_images "renders", File.basename(arg)
  rescue => e
    puts "Could not read #{arg}"
  end
end
