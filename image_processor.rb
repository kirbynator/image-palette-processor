require 'mini_magick'
require 'base64'
require 'tempfile'
require 'chunky_png'


class ImageProcessor
  DEFAULT_SIZE = "32x32"
  DEFAULT_COLORS = "6"
  DEFAULT_FORMAT = "png"
  DEFAULT_PALETTE = "64colors.gpl"

  def initialize(image_path, options = {})
    @image_path = image_path
    @size = options[:size] || DEFAULT_SIZE
    @colors = options[:colors] || DEFAULT_COLORS
    @format = options[:format] || DEFAULT_FORMAT
    @grayscale = options[:grayscale] == "true"
    @palette_swap = options[:palette_swap] == "true"
    @palette_file = options[:palette]
    validate_input
    @palette = extract_palette(@palette_file || DEFAULT_PALETTE) if @palette_swap && !@grayscale
  end

  def extract_palette(palette_path)
    colors = []
    if palette_path.is_a?(Tempfile)
      File.readlines(palette_path.path).each do |line|
        next if line.start_with?("GIMP Palette") || line.strip.empty? || line.start_with?("#")
        parts = line.strip.split
        colors << ChunkyPNG::Color.rgb(parts[0].to_i, parts[1].to_i, parts[2].to_i) if parts.size >= 3
      end
    else
      File.readlines(palette_path).each do |line|
        next if line.start_with?("GIMP Palette") || line.strip.empty? || line.start_with?("#")
        parts = line.strip.split
        colors << ChunkyPNG::Color.rgb(parts[0].to_i, parts[1].to_i, parts[2].to_i) if parts.size >= 3
      end
    end
    colors
  end

  def map_to_palette(image)
    # First ensure we have a PNG
    temp_input = Tempfile.new(['input', '.png'])
    image.format('png')
    image.write(temp_input.path)
    
    # Convert to ChunkyPNG image
    png = ChunkyPNG::Image.from_file(temp_input.path)
    
    # Map each pixel to the closest palette color
    png.height.times do |y|
      png.width.times do |x|
        original = png[x, y]
        png[x, y] = closest_palette_color(original)
      end
    end
    
    # Save the processed image
    temp_output = Tempfile.new(['output', '.png'])
    png.save(temp_output.path)
    
    # Convert back to MiniMagick image
    result = MiniMagick::Image.open(temp_output.path)
    result.format('png')
    
    # Cleanup
    temp_input.close
    temp_input.unlink
    temp_output.close
    temp_output.unlink
    
    result
  end

  def closest_palette_color(color)
    r, g, b = ChunkyPNG::Color.r(color), ChunkyPNG::Color.g(color), ChunkyPNG::Color.b(color)
    @palette.min_by { |pal|
      pr, pg, pb = ChunkyPNG::Color.r(pal), ChunkyPNG::Color.g(pal), ChunkyPNG::Color.b(pal)
      (r - pr) ** 2 + (g - pg) ** 2 + (b - pb) ** 2
    }
  end

  def process
    begin
      # Load the image and convert to PNG immediately
      image = MiniMagick::Image.open(@image_path)
      image.format(@format)
      
      # Process the image
      image.resize(@size)
      
      if @grayscale
        # Apply grayscale processing
        image.combine_options do |c|
          c.colorspace "Gray"
          c.colors @colors
          c.dither "None"
          c.quality "100"
        end
      else
        # Apply color palette processing
        image.combine_options do |c|
          c.colors @colors
          c.dither "None"
          c.quality "100"
        end
        image = map_to_palette(image) if @palette_swap
      end
      
      # Save to temporary file
      temp_file = Tempfile.new(['image', '.png'], binmode: true)
      image.write(temp_file.path)
      
      # Convert to base64
      base64_data = File.open(temp_file.path, 'rb') { |f| Base64.strict_encode64(f.read) }
      
      {
        data: "data:image/png;base64,#{base64_data}",
        width: image.width,
        height: image.height
      }
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end

  private

  def validate_input
    unless File.exist?(@image_path)
      raise ArgumentError, "Input file does not exist: #{@image_path}"
    end
    if File.size(@image_path).zero?
      raise ArgumentError, "Input file is empty: #{@image_path}"
    end
  end
end