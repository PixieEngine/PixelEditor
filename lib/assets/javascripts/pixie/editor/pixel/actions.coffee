# Default actions for the pixel editor
namespace "Pixie.Editor.Pixel", (Pixel) ->
  Pixel.actions = (($) ->
    return actions =
      guides:
        hotkeys: ['g']
        menu: false
        perform: (canvas) ->
          canvas.toggleGuides()
        undoable: false
      undo:
        hotkeys: ['ctrl+z', 'meta+z']
        perform: (canvas) ->
          canvas.undo()
        undoable: false
      redo:
        hotkeys: ["ctrl+y", "meta+z"]
        perform: (canvas) ->
          canvas.redo()
        undoable: false
      clear:
        perform: (canvas) ->
          canvas.clear()
      resize:
        perform: (canvas) ->
          if newSize = prompt('New Dimensions', "#{canvas.width()}x#{canvas.height()}")
            return alert "Please specify a width x height" unless (/\d+x\d+$/).test(newSize)

            [x, y] = newSize.split('x')

            canvas.resize(parseInt(x), parseInt(y), true)
      preview:
        menu: false
        perform: (canvas) ->
          canvas.preview()
        undoable: false
      opacify:
        hotkeys: ["+", "="]
        menu: false
        perform: (canvas) ->
          canvas.opacity(canvas.opacity() + 0.1)
        undoable: false
      transparentize:
        hotkeys: ["-"]
        menu: false
        perform: (canvas) ->
          canvas.opacity(canvas.opacity() - 0.1)
        undoable: false
      left:
        hotkeys: ["left"]
        menu: false
        perform: (canvas) ->
          deferredColors = []

          canvas.height().times (y) ->
            deferredColors[y] = canvas.getPixel(0, y).color()

          canvas.eachPixel (pixel, x, y) ->
            rightPixel = canvas.getPixel(x + 1, y)

            if rightPixel
              pixel.color(rightPixel.color(), 'replace')
            else
              pixel.color(Color(), 'replace')

          deferredColors.each (color, y) ->
            canvas.getPixel(canvas.width() - 1, y).color(color)
      right:
        hotkeys: ["right"]
        menu: false
        perform: (canvas) ->
          width = canvas.width()
          height = canvas.height()

          deferredColors = []

          height.times (y) ->
            deferredColors[y] = canvas.getPixel(width - 1, y).color()

          x = width - 1

          while x >= 0
            y = 0

            while y < height
              currentPixel = canvas.getPixel(x, y)
              leftPixel = canvas.getPixel(x - 1, y)
              if leftPixel
                currentPixel.color leftPixel.color(), "replace"
              else
                currentPixel.color Color(), "replace"
              y++
            x--

          $.each deferredColors, (y, color) ->
            canvas.getPixel(0, y).color color
      up:
        hotkeys: ["up"]
        menu: false
        perform: (canvas) ->
          deferredColors = []

          canvas.width().times (x) ->
            deferredColors[x] = canvas.getPixel(x, 0).color()

          canvas.eachPixel (pixel, x, y) ->
            lowerPixel = canvas.getPixel(x, y + 1)
            if lowerPixel
              pixel.color lowerPixel.color(), "replace"
            else
              pixel.color Color(), "replace"

          $.each deferredColors, (x, color) ->
            canvas.getPixel(x, canvas.height() - 1).color color
      down:
        hotkeys: ["down"]
        menu: false
        perform: (canvas) ->
          width = canvas.width()
          height = canvas.height()

          deferredColors = []

          canvas.width().times (x) ->
            deferredColors[x] = canvas.getPixel(x, height - 1).color()

          x = 0

          while x < width
            y = height - 1

            while y >= 0
              currentPixel = canvas.getPixel(x, y)
              upperPixel = canvas.getPixel(x, y - 1)
              if upperPixel
                currentPixel.color upperPixel.color(), "replace"
              else
                currentPixel.color Color(), "replace"
              y--
            x++

          $.each deferredColors, (x, color) ->
            canvas.getPixel(x, 0).color color
  )(jQuery)
