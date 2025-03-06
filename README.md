# Image Palette Processor

A web application that processes images with customizable color palettes, grayscale conversion, and size adjustments.

## Features

- Upload and preview images
- Resize images to custom dimensions
- Convert images to grayscale
- Apply custom color palettes (GPL format)
- Adjust number of colors
- Change output format
- Real-time image preview
- Default 64-color palette included

## Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/image-palette-processor.git
cd image-palette-processor
```

2. Install dependencies:
```bash
bundle install
```

3. Run the application:
```bash
ruby app.rb
```

4. Open your browser and navigate to `http://localhost:4567`

## Usage

1. Upload an image using the file input
2. Adjust the image size (default: 32x32)
3. Set the number of colors (default: 6)
4. Choose between grayscale or palette swap
5. Upload a custom GPL palette file (optional)
6. Set the output format (default: png)
7. Click "Process Image" to see the result

## Requirements

- Ruby 2.7 or higher
- ImageMagick
- Bundler

## Dependencies

- Sinatra
- MiniMagick
- ChunkyPNG

## License

MIT License - feel free to use this project for your own purposes. 