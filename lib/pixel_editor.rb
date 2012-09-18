require "pixel_editor/version"

module PixelEditor
  # Sneaky require for Rails engine environment
  if defined? ::Rails::Engine
    require "pixel_editor/rails"
  elsif defined? ::Sprockets
    require "pixel_editor/sprockets"
  end
end
