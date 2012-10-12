namespace "Pixie.Editor.Pixel", (Pixel) ->
  Pixel.Layer = (I) ->
    layer = $ "<canvas />",
      class: "layer"

    layerWidth = -> I.width * I.pixelWidth
    layerHeight = -> I.height * I.pixelHeight
    layerElement = layer.get(0)
    layerElement.width = layerWidth()
    layerElement.height = layerHeight()

    context = layerElement.getContext("2d")

    return Object.extend layer,
      context: context

      resize: ->
        layerElement.width = layerWidth()
        layerElement.height = layerHeight()
