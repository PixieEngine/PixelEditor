namespace "Pixie.Editor.Pixel", (Pixel) ->
  Pixel.Pixel = (I={}) ->
    {x, y, color, oldColor, changed} = I

    color ||= Color(0, 0, 0, 0)
    oldColor ||= Color(0, 0, 0, 0)

    self =
      color: (newColor, blendMode="additive") ->
        if arguments.length >= 1
          oldColor = color
          newColor = Color(newColor.r, newColor.g, newColor.b, newColor.a)

          color = ColorUtil[blendMode](oldColor, newColor)

          changed?(self)

          return self
        else
          return color

      oldColor: ->
        oldColor

      x: x
      y: y

      toString: ->
        "[Pixel: " + [x, y].join(",") + "]"
