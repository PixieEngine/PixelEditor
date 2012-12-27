# Pixie Pixel Editor

Our pixel editor enables you to quickly and easily create simple pixel art online.

Download your finished work to your computer or share it with your friends.

This simple and fun editor is easy to use, especially for beginners.

## Installation

Add this line to your application's Gemfile:

    gem 'pixel_editor', :git => 'git://github.com/PixieEngine/PixelEditor.git'

And then execute:

    $ bundle

## Usage

Include the scripts:

    #= require pixie/editor/pixel/create

In the page where you want to create the pixel editor:

    pixie = Pixie.Editor.Pixel.create()
    $("body").append(pixie)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
