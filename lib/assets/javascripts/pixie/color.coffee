( ->
  RGBA_REGEXP = /^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+(?:\.\d+)?))?\)$/

  padString = (hexString) ->
    if hexString.length is 1 then pad = "0" else pad = ""

    pad + hexString

  hexFromNumber = (number) ->
    padString(number.toString(16))

  Color = (r, g, b, a = 1) ->
    __proto__: Color::
    r: r
    g: g
    b: b
    a: a

  Color:: =
    channels: ->
      [@r, @g, @b, @a]

    equal: (other) ->
      other.r is @r &&
      other.g is @g &&
      other.b is @b &&
      other.a is @a

    toHex: (leadingHash) ->
      hexString = "##{hexFromNumber(@r)}#{hexFromNumber(@g)}#{hexFromNumber(@b)}"

      if leadingHash is false
        hexString.slice(1)
      else
        hexString

    toString: ->
      "rgba(#{@r}, #{@g}, #{@b}, #{@a})"

  Color.parseFromRGB = (rgbString) ->
    channels = rgbString.match(RGBA_REGEXP).slice(1)

    r = parseInt(channels[0])
    g = parseInt(channels[1])
    b = parseInt(channels[2])

    if channels[3]?
      a = parseFloat(channels[3])
    else
      a = 1

    return Color(r, g, b, a)

  (exports ? this)["Color"] = Color
)()

