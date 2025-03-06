require 'sinatra'
require 'sinatra/reloader'
require_relative 'image_processor'

set :bind, '0.0.0.0'
set :port, 4567

get '/' do
  erb :index
end

post '/process' do
  if params[:image] && params[:image][:tempfile]
    image_file = params[:image][:tempfile]
    logger.info "Received image: #{params[:image][:filename]}"
    
    # Extract optional parameters
    options = {
      size: params[:size],
      colors: params[:colors],
      format: params[:format],
      grayscale: params[:grayscale],
      palette_swap: params[:palette_swap],
      palette: params[:palette]&.dig(:tempfile)
    }.compact # Remove any nil values
    
    processor = ImageProcessor.new(image_file.path, options)
    result = processor.process
    
    content_type :json
    result.to_json
  else
    logger.error "No image file received"
    redirect '/'
  end
end

post '/select' do
  if params[:choice] && (3..6).include?(params[:choice].to_i)
    choice = params[:choice].to_i
    @selected_image = params[:images][choice.to_s]
    erb :success
  else
    redirect '/'
  end
end

get '/success' do
  erb :success
end 