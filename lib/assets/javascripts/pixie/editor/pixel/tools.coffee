# All the default editor tools for the pixel editor

namespace "Pixie.Editor.Pixel", (Pixel) ->
  colorNeighbors = (color) ->
    @color(color)
    @canvas.getNeighbors(@x, @y).each (neighbor) ->
      neighbor?.color(color)

  erase = (pixel, opacity) ->
    inverseOpacity = (1 - opacity)
    pixelColor = pixel.color()

    pixel.color(Color(pixelColor.r, pixelColor.g, pixelColor.b, pixelColor.a * inverseOpacity), "replace")

  floodFill = (e, newColor, pixel) ->
    originalColor = this.color()
    return if newColor.equal(originalColor)

    q = []
    pixel.color(newColor)
    q.push(pixel)

    canvas = this.canvas

    while(q.length)
      pixel = q.pop()

      neighbors = canvas.getNeighbors(pixel.x, pixel.y)

      neighbors.each (neighbor) ->
        if neighbor?.color().equal(originalColor)
          neighbor.color(newColor)
          q.push(neighbor)

    return

  # gross code courtesy of http://en.wikipedia.org/wiki/Midpoint_circle_algorithm
  circle = (canvas, color, center, endPoint) ->
    {x:x0, y:y0} = center
    {x:x1, y:y1} = endPoint

    radius = endPoint.subtract(center).magnitude().floor()

    f = 1 - radius
    ddFx = 1
    ddFy = -2 * radius

    x = 0
    y = radius

    canvas.getPixel(x0, y0 + radius)?.color(color)
    canvas.getPixel(x0, y0 - radius)?.color(color)
    canvas.getPixel(x0 + radius, y0)?.color(color)
    canvas.getPixel(x0 - radius, y0)?.color(color)

    while x < y
      if f > 0
        y--
        ddFy += 2
        f += ddFy

      x++
      ddFx += 2
      f += ddFx

      canvas.getPixel(x0 + x, y0 + y)?.color(color)
      canvas.getPixel(x0 - x, y0 + y)?.color(color)
      canvas.getPixel(x0 + x, y0 - y)?.color(color)
      canvas.getPixel(x0 - x, y0 - y)?.color(color)
      canvas.getPixel(x0 + y, y0 + x)?.color(color)
      canvas.getPixel(x0 - y, y0 + x)?.color(color)
      canvas.getPixel(x0 + y, y0 - x)?.color(color)
      canvas.getPixel(x0 - y, y0 - x)?.color(color)

  line = (canvas, color, p0, p1) ->
    {x:x0, y:y0} = p0
    {x:x1, y:y1} = p1

    dx = (x1 - x0).abs()
    dy = (y1 - y0).abs()
    sx = (x1 - x0).sign()
    sy = (y1 - y0).sign()
    err = dx - dy

    while !(x0 == x1 and y0 == y1)
      e2 = 2 * err

      if e2 > -dy
        err -= dy
        x0 += sx

      if e2 < dx
        err += dx
        y0 += sy

      canvas.getPixel(x0, y0).color(color)

  pencilTool = do ->
    center = Point(0, 0)
    lastPosition = Point(0, 0)

    hotkeys: ['p', '1']
    mousedown: (e, color) ->
      currentPosition = Point(@x, @y)

      if e.shiftKey
        line(@canvas, color, lastPosition, currentPosition)
      else if e.altKey
        circle(@canvas, color, center, currentPosition)
      else
        @color(color)
        center = Point(@x, @y)

      lastPosition = currentPosition
    mouseenter: (e, color) ->
      currentPosition = Point(@x, @y)

      line(@canvas, color, lastPosition, currentPosition)
      lastPosition = currentPosition

  Pixel.tools = tools =
    pencil: pencilTool

    mirror_pencil:
      hotkeys: ['m', '2']
      mousedown: (e, color) ->
        mirrorCoordinate = @canvas.width() - @x - 1
        @color(color)
        @canvas.getPixel(mirrorCoordinate, @y).color(color)
      mouseenter: (e, color) ->
        mirrorCoordinate = @canvas.width() - @x - 1
        @color(color)
        @canvas.getPixel(mirrorCoordinate, @y).color(color)
    brush:
      hotkeys: ['b', '3']
      mousedown: (e, color) ->
        colorNeighbors.call(this, color)
      mouseenter: (e, color) ->
        colorNeighbors.call(this, color)
    dropper:
      hotkeys: ['i', '4']
      mousedown: (e) ->
        @canvas.color(@color())
        @canvas.setTool(tools.pencil) unless e.shiftKey
    eraser:
      hotkeys: ['e', '5']
      mousedown: (e, color, pixel) ->
        erase(pixel, color.a)
      mouseenter: (e, color, pixel) ->
        erase(pixel, color.a)
    fill:
      hotkeys: ['f', '6']
      mousedown: floodFill
      mouseenter: floodFill
    zoom_in:
      hotkeys: ['z', '7']
      mousedown: ->
        @canvas.zoomIn()
    zoom_out:
      hotkeys: ['shift+z', '8']
      mousedown: ->
        @canvas.zoomOut()
