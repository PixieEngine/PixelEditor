( ->
  rgbParser = /^rgba?\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),?\s*(\d?\.?\d*)?\)$/
  hslParser = /^hsla?\((\d{1,3}),\s*(\d?\.?\d*),\s*(\d?\.?\d*),?\s*(\d?\.?\d*)?\)$/

  parseRGB = (colorString) ->
    return undefined unless channels = rgbParser.exec(colorString)

    parsedColor = (parseFloat channel for channel in channels[1..4])

    parsedColor[3] = 1 if isNaN(parsedColor[3])

    return parsedColor

  parseHex = (hexString) ->
    hexString = hexString.replace(/#/, '')

    switch hexString.length
      when 3, 4
        if hexString.length == 4
          alpha = ((parseInt(hexString.substr(3, 1), 16) * 0x11) / 255)
        else
          alpha = 1

        rgb = (parseInt(hexString.substr(i, 1), 16) * 0x11 for i in [0..2])
        rgb.push(alpha)

        return rgb

      when 6, 8
        if hexString.length == 8
          alpha = (parseInt(hexString.substr(6, 2), 16) / 255)
        else
          alpha = 1

        rgb = (parseInt(hexString.substr(2 * i, 2), 16) for i in [0..2])
        rgb.push(alpha)

        return rgb

      else
        return undefined

  parseHSL = (colorString) ->
    return undefined unless channels = hslParser.exec(colorString)

    parsedColor = (parseFloat channel for channel in channels[1..4])

    parsedColor[3] = 1 if isNaN(parsedColor[3])

    return hslToRgb(parsedColor)

  hslToRgb = (hsl) ->
    [h, s, l, a] = hsl

    h = h % 360
    a = 1 unless a?

    r = g = b = null

    hueToRgb = (p, q, hue) ->
      hue = hue.mod(360)

      return p + (q - p) * (hue / 60) if hue < 60
      return q if hue < 180
      return p + (q - p) * ((240 - hue) / 60) if hue < 240
      return p

    if s == 0
      r = g = b = l
    else
      q = (if l < 0.5 then l * (1 + s) else l + s - l * s)
      p = 2 * l - q
      r = hueToRgb(p, q, h + 120)
      g = hueToRgb(p, q, h)
      b = hueToRgb(p, q, h - 120)

    rgbMap = ((channel * 255).round() for channel in [r, g, b])

    return rgbMap.concat(a)

  normalizeKey = (key) ->
    key.toString().toLowerCase().split(' ').join('')

  channelize = (color, alpha) ->
    return color.channels() if color.channels?
    if Object.isArray color
      if alpha?
        alpha = parseFloat(alpha)
      else if color[3]?
        alpha = parseFloat(color[3])
      else
        alpha = 1

      result = (parseFloat(channel) for channel in color[0..2]).concat(alpha)
    else
      result = lookup[normalizeKey(color)] || parseHex(color) || parseRGB(color) || parseHSL(color)

      if alpha?
        result[3] = parseFloat(alpha)

    return result

  ###*
  Create a new color. The constructor is very flexible. It accepts individual r, g, b, a values,
  arrays of r, g, b values, hex strings, rgb strings, hsl strings, other Color objects,
  and even the named colors from the xkcd survey: http://blog.xkcd.com/2010/05/03/color-survey-results/.
  If no arguments are given, defaults to transparent.

  <code><pre>
  individualRgb = Color(23, 56, 49, 0.4)

  individualRgb.toString()
  # => 'rgba(23, 56, 49, 0.4)'

  arrayRgb = Color([59, 100, 230])

  arrayRgb.toString()
  # => 'rgba(59, 100, 230, 1)'

  hex = Color('#ff0000')

  hex.toString()
  # => 'rgba(255, 0, 0, 1)'

  rgb = Color('rgb(0, 255, 0)')

  rgb.toString()
  # => 'rgba(0, 255, 0, 1)'

  hsl = Color('hsl(180, 1, 0.5)')

  hsl.toString()
  # => 'rgba(0, 255, 255, 1)'

  anotherColor = Color('blue')

  Color(anotherColor)
  # => a new color with the same r, g, b, and alpha values as `anotherColor`

  # You have access to all sorts of weird colors.
  # We give you all the named colors the browser recognizes
  # and the ones from this survey
  # http://blog.xkcd.com/2010/05/03/color-survey-results/
  namedBrown = Color('Fuzzy Wuzzy Brown')

  namedBrown.toHex()
  # => '#c45655'

  # Default behavior
  transparent = Color()

  transparent.toString()
  # => 'rgba(0, 0, 0, 0)'
  </pre></code>

  @name Color
  @param {Array|Number|String|Color} args... An Array, r, g, b values,
  a sequence of numbers defining r, g, b values, a hex or hsl string, another Color object, or a named color
  @constructor
  ###
  Color = (args...) ->
    parsedColor =
      switch args.length
        when 0
          [0, 0, 0, 0]
        when 1
          channelize(args.first())
        when 2
          channelize(args.first(), args.last())
        else
          channelize(args)

    throw "#{args.join(',')} is an unknown color" unless parsedColor

    __proto__: Color::
    r: parsedColor[0].round()
    g: parsedColor[1].round()
    b: parsedColor[2].round()
    a: parsedColor[3]

  Color:: =
    ###*
    Returns the rgba color channels in an array.

    <code><pre>
    transparent =  Color()

    transparent.channels()
    # => [0, 0, 0, 0]

    red = Color("#FF0000")

    red.channels()
    # => [255, 0, 0, 1]

    rgb = Color(200, 34, 2)

    rgb.channels()
    # => [200, 34, 2, 1]
    </pre></code>

    @name channels
    @methodOf Color#

    @returns {Array} Array of r, g, b, and alpha values of the color
    ###
    channels: ->
      [@r, @g, @b, @a]

    ###*
    A copy of the calling color that is its complementary color on the color wheel.

    <code><pre>
    red = Color(255, 0, 0)

    cyan = red.complement()

    cyan.toString()
    # => 'rgba(0, 255, 255, 1)'
    </pre></code>

    @name complement
    @methodOf Color#

    @returns {Color} new color that is a copy of the calling color with its hue shifted by 180 degrees on the color wheel
    ###
    complement: ->
      @copy().complement$()

    ###*
    Modifies the calling color to make it the complement of its previous value.

    <code><pre>
    red = Color(255, 0, 0)

    # modifies red in place to make it into cyan
    red.complement$()

    red.toString()
    # => 'rgba(0, 255, 255, 1)'
    </pre></code>

    @name complement$
    @methodOf Color#

    @returns {Color} the color hue shifted by 180 degrees on the color wheel. Modifies the existing color.
    ###
    complement$: ->
      @shiftHue$(180)

    ###*
    A copy of the calling color.

    <code><pre>
    color = Color(0, 100, 200)

    copy = color.copy()

    color == copy
    # => false

    color.equal(copy)
    # => true
    </pre></code>

    @name copy
    @methodOf Color#

    @returns {Color} A new color. A copy of the calling color
    ###
    copy: ->
      Color(@r, @g, @b, @a)

    ###*
    Returns a copy of the calling color darkened by `amount` (Lightness of the color ranges from 0 to 1).

    <code><pre>
    green = Color(0, 255, 0)

    darkGreen = green.darken(0.3)

    darkGreen.toString()
    # => 'rgba(0, 102, 0, 1)'
    </pre></code>

    @name darken
    @methodOf Color#
    @param {Number} amount Amount to darken color by (between 0 - 1)

    @returns {Color} A new color. The lightness value is reduced by `amount` from the original.
    ###
    darken: (amount) ->
      @copy().darken$(amount)

    ###*
    Modifies the color so that it is darkened by `amount` (Lightness of the color ranges from 0 to 1).

    <code><pre>
    green = Color(0, 255, 0)

    # Modifies green to be darkGreen
    green.darken$(0.3)

    green.toString()
    # => 'rgba(0, 102, 0, 1)'
    </pre></code>

    @name darken$
    @methodOf Color#
    @param {Number} amount Amount to darken color by (between 0 - 1)

    @returns {Color} the color with the lightness value reduced by `amount`
    ###
    darken$: (amount) ->
      hsl = @toHsl()
      hsl[2] -= amount

      [@r, @g, @b, @a] = hslToRgb(hsl)

      return this

    ###*
    A copy of the calling color with its saturation reduced by `amount`.

    <code><pre>
    blue = Color(0, 0, 255)

    desaturatedBlue = blue.desaturate(0.3)

    desaturatedBlue.toString()
    # => 'rgba(38, 38, 217, 1)'
    </pre></code>

    @name desaturate
    @methodOf Color#
    @param {Number} amount Amount to reduce color saturation by (between 0 - 1)

    @returns {Color} A copy of the color with the saturation value reduced by `amount`
    ###
    desaturate: (amount) ->
      @copy().desaturate$(amount)

    ###*
    The modified color with its saturation reduced by `amount`.

    <code><pre>
    blue = Color(0, 0, 255)

    # modifies blue to be desaturatedBlue
    blue.desaturate$(0.3)

    blue.toString()
    # => 'rgba(38, 38, 217, 1)'
    </pre></code>

    @name desaturate$
    @methodOf Color#
    @param {Number} amount Amount to reduce color saturation by (between 0 - 1)

    @returns {Color} the color with the saturation value reduced by `amount`
    ###
    desaturate$: (amount) ->
      hsl = @toHsl()
      hsl[1] -= amount

      [@r, @g, @b, @a] = hslToRgb(hsl)

      return this

    ###*
    Determine whether two colors are equal. Compares their r, g, b, and alpha values.

    <code><pre>
    hex = Color('#ffff00')
    rgb = Color(255, 255, 0)

    hex == rgb
    # => false

    hex.equal(rgb)
    # => true
    </pre></code>

    @name equal
    @methodOf Color#
    @param {Color} other the color to compare to the calling color

    @returns {Boolean} true if the r, g, b, a values of the colors agree, false otherwise
    ###
    equal: (other) ->
      other.r == @r &&
      other.g == @g &&
      other.b == @b &&
      other.a == @a

    ###*
    A copy of the calling color converted to grayscale.

    <code><pre>
    color = Color(255, 255, 0)

    gray = color.grayscale()

    gray.toString()
    # => 'rgba(128, 128, 128, 1)'
    </pre></code>

    @name grayscale
    @methodOf Color#

    @returns {Color} A copy of the calling color converted to grayscale.
    ###
    grayscale: ->
      @copy().grayscale$()

    ###*
    The calling color converted to grayscale.

    <code><pre>
    color = Color(255, 255, 0)

    # modifies color into gray
    color.grayscale$()

    color.toString()
    # => 'rgba(128, 128, 128, 1)'
    </pre></code>

    @name grayscale$
    @methodOf Color#

    @returns {Color} The calling color converted to grayscale.
    ###
    grayscale$: ->
      hsl = @toHsl()

      g = (hsl[2] * 255).round()

      @r = @g = @b = g

      return this

    ###*
    A getter / setter for the hue value of the color. Passing no argument returns the
    current hue value. Passing a value will set the hue to that value and return the color.

    <code><pre>
    magenta = Color(255, 0, 255)

    yellow = magenta.hue(60)

    yellow.toString()
    # => 'rgba(255, 255, 0, 1)'
    </pre></code>

    @name hue
    @methodOf Color#
    @param {Number} [newVal] the new hue value

    @returns {Color|Number} returns the color object if you pass a new hue value and returns the hue otherwise
    ###
    hue: (newVal) ->
      hsl = @toHsl()
      if newVal?
        hsl[0] = newVal

        [@r, @g, @b, @a] = hslToRgb(hsl)

        return this
      else
        return hsl[0]

    ###*
    A getter / setter for the lightness value of the color. Passing no argument returns the
    current lightness value. Passing a value will set the lightness to that value and return the color.

    <code><pre>
    magenta = Color(255, 0, 255)

    magenta.lightness()
    # => 0.9

    darkerMagenta = magenta.lightness(0.75)

    darkerMagenta.lightness()
    # => 0.75
    </pre></code>

    @name lightness
    @methodOf Color#
    @param {Number} [newVal] the new lightness value

    @returns {Color|Number} returns the color object if you pass a new lightness value and returns the lightness otherwise
    ###
    lightness: (newVal) ->
      hsl = @toHsl()
      if newVal?
        hsl[2] = newVal

        [@r, @g, @b, @a] = hslToRgb(hsl)

        return this
      else
        return hsl[2]

    ###*
    A copy of the calling color with its hue shifted by `degrees`. This differs from the hue setter in that it adds to the existing hue value and will wrap around 0 and 360.

    <code><pre>
    magenta = Color(255, 0, 255)

    magenta.hue()
    # => 300

    yellow = magenta.shiftHue(120)

    # since magenta's hue is 300 we have wrapped
    # around 360 to end up at 60
    yellow.hue()
    # => 60

    yellow.toString()
    # => 'rgba(255, 255, 0, 1)'
    </pre></code>

    @name shiftHue
    @methodOf Color#
    @param {Number} degrees number of degrees to shift the hue on the color wheel.

    @returns {Color} A copy of the color with its hue shifted by `degrees`
    ###
    shiftHue: (degrees) ->
      @copy().shiftHue$(degrees)

    ###*
    The calling color with its hue shifted by `degrees`. This differs from the hue setter in that it adds to the existing hue value and will wrap around 0 and 360.

    <code><pre>
    magenta = Color(255, 0, 255)

    magenta.hue()
    # => 300

    magenta.shiftHue$(120)

    # since magenta's hue is 300 we have wrapped
    # around 360 to end up at 60. Also we have
    # modified magenta in place to become yellow
    magenta.hue()
    # => 60

    magenta.toString()
    # => 'rgba(255, 255, 0, 1)'
    </pre></code>

    @name shiftHue$
    @methodOf Color#
    @param {Number} degrees number of degrees to shift the hue on the color wheel.

    @returns {Color} The color with its hue shifted by `degrees`
    ###
    shiftHue$: (degrees) ->
      hsl = @toHsl()

      hsl[0] = (hsl[0] + degrees.round()).mod 360

      [@r, @g, @b, @a] = hslToRgb(hsl)

      return this

    ###*
    Returns a copy of the calling color lightened by `amount` (Lightness of the color ranges from 0 to 1).

    <code><pre>
    green = Color(0, 255, 0)

    lightGreen = green.lighten(0.2)

    lightGreen.toString()
    # => 'rgba(102, 255, 102, 1)'
    </pre></code>

    @name lighten
    @methodOf Color#
    @param {Number} amount Amount to lighten color by (between 0 to 1)

    @returns {Color} A new color. The lightness value is increased by `amount` from the original.
    ###
    lighten: (amount) ->
      @copy().lighten$(amount)

    ###*
    The calling color lightened by `amount` (Lightness of the color ranges from 0 to 1).

    <code><pre>
    green = Color(0, 255, 0)

    green.lighten(0.2)

    # we have modified green in place
    # to become lightGreen
    green.toString()
    # => 'rgba(102, 255, 102, 1)'
    </pre></code>

    @name lighten$
    @methodOf Color#
    @param {Number} amount Amount to lighten color by (between 0 - 1)

    @returns {Color} The calling color with its lightness value increased by `amount`.
    ###
    lighten$: (amount) ->
      hsl = @toHsl()
      hsl[2] += amount

      [@r, @g, @b, @a] = hslToRgb(hsl)

      return this

    ###*
    A copy of the calling color mixed with `other` using `amount` as the
    mixing ratio. If amount is not passed, then the colors are mixed evenly.

    <code><pre>
    red = Color(255, 0, 0)
    yellow = Color(255, 255, 0)

    # With no amount argument the colors are mixed evenly
    orange = red.mixWith(yellow)

    orange.toString()
    # => 'rgba(255, 128, 0, 1)'

    # With an amount of 0.3 we are mixing the color 30% red and 70% yellow
    somethingCloseToOrange = red.mixWith(yellow, 0.3)

    somethingCloseToOrange.toString()
    # => rgba(255, 179, 0, 1)
    </pre></code>

    @name mixWith
    @methodOf Color#
    @param {Color} other the other color to mix
    @param {Number} [amount] the mixing ratio of the calling color to `other`

    @returns {Color} A new color that is a mix of the calling color and `other`
    ###
    mixWith: (other, amount) ->
      @copy().mixWith$(other, amount)

    ###*
    A copy of the calling color mixed with `other` using `amount` as the
    mixing ratio. If amount is not passed, then the colors are mixed evenly.

    <code><pre>
    red = Color(255, 0, 0)
    yellow = Color(255, 255, 0)
    anotherRed = Color(255, 0, 0)

    # With no amount argument the colors are mixed evenly
    red.mixWith$(yellow)

    # We have modified red in place to be orange
    red.toString()
    # => 'rgba(255, 128, 0, 1)'

    # With an amount of 0.3 we are mixing the color 30% red and 70% yellow
    anotherRed.mixWith$(yellow, 0.3)

    # We have modified `anotherRed` in place to be somethingCloseToOrange
    anotherRed.toString()
    # => rgba(255, 179, 0, 1)
    </pre></code>

    @name mixWith$
    @methodOf Color#
    @param {Color} other the other color to mix
    @param {Number} [amount] the mixing ratio of the calling color to `other`

    @returns {Color} The modified calling color after mixing it with `other`
    ###
    mixWith$: (other, amount) ->
      amount ||= 0.5

      [@r, @g, @b, @a] = [@r, @g, @b, @a].zip([other.r, other.g, other.b, other.a]).map (array) ->
        (array[0] * amount) + (array[1] * (1 - amount))

      [@r, @g, @b] = [@r, @g, @b].map (color) ->
        color.round()

      return this

    ###*
    A copy of the calling color with its saturation increased by `amount`.

    <code><pre>
    color = Color(50, 50, 200)

    color.saturation()
    # => 0.6

    saturatedColor = color.saturate(0.2)

    saturatedColor.saturation()
    # => 0.8

    saturatedColor.toString()
    # => rgba(25, 25, 225, 1)
    </pre></code>

    @name saturate
    @methodOf Color#
    @param {Number} amount the amount to increase saturation by

    @returns {Color} A copy of the calling color with its saturation increased by `amount`
    ###
    saturate: (amount) ->
      @copy().saturate$(amount)

    ###*
    The calling color with its saturation increased by `amount`.

    <code><pre>
    color = Color(50, 50, 200)

    color.saturation()
    # => 0.6

    color.saturate$(0.2)

    # We have modified color in place and increased its saturation to 0.8
    color.saturation()
    # => 0.8

    color.toString()
    # => rgba(25, 25, 225, 1)
    </pre></code>

    @name saturate$
    @methodOf Color#
    @param {Number} amount the amount to increase saturation by

    @returns {Color} The calling color with its saturation increased by `amount`
    ###
    saturate$: (amount) ->
      hsl = @toHsl()
      hsl[1] += amount

      [@r, @g, @b, @a] = hslToRgb(hsl)

      return this

    ###*
    A getter / setter for the saturation value of the color. Passing no argument returns the
    current saturation value. Passing a value will set the saturation to that value and return the color.

    <code><pre>
    hslColor = Color('hsl(60, 0.5, 0.5)')

    hslColor.saturation()
    # => 0.5
    </pre></code>

    @name saturation
    @methodOf Color#
    @param {Number} [newVal] the new saturation value

    @returns {Color|Number} returns the color object if you pass a new saturation value and returns the saturation otherwise
    ###
    saturation: (newVal) ->
      hsl = @toHsl()
      if newVal?
        hsl[1] = newVal

        [@r, @g, @b, @a] = hslToRgb(hsl)

        return this
      else
        return hsl[1]

    ###*
    returns the Hex representation of the color. Exclude the leading `#` by passing false.

    <code><pre>
    color = Color('hsl(60, 1, 0.5)')

    # passing nothing will leave the `#` intact
    color.toHex()
    # => '#ffff00'

    # passing false will remove the `#`
    color.toHex(false)
    # => 'ffff00'
    </pre></code>

    @name toHex
    @methodOf Color#
    @param {Boolean} [leadingHash] if passed as false excludes the leading `#` from the string

    @returns {String} returns the Hex representation of the color
    ###
    toHex: (leadingHash) ->
      padString = (hexString) ->
        if hexString.length == 1 then pad = "0" else pad = ""

        return pad + hexString

      hexFromNumber = (number) ->
        return padString(number.toString(16))

      if leadingHash == false
        "#{hexFromNumber(@r)}#{hexFromNumber(@g)}#{hexFromNumber(@b)}"
      else
        "##{hexFromNumber(@r)}#{hexFromNumber(@g)}#{hexFromNumber(@b)}"

    ###*
    returns an array of the hue, saturation, lightness, and alpha values of the color.

    <code><pre>
    magenta = Color(255, 0, 255)

    magenta.toHsl()
    # => [300, 1, 0.5, 1]
    </pre></code>

    @name toHsl
    @methodOf Color#

    @returns {Array} An array of the hue, saturation, lightness, and alpha values of the color.
    ###
    toHsl: ->
      [r, g, b] = (channel / 255 for channel in [@r, @g, @b])

      {min, max} = [r, g, b].extremes()

      hue = saturation = lightness = (max + min) / 2
      chroma = max - min

      if chroma.abs() < 0.00001
        hue = saturation = 0
      else
        saturation =
          if lightness > 0.5
            chroma / (1 - lightness)
          else
            chroma / lightness

        saturation /= 2

        switch max
          when r then hue = ((g - b) / chroma) + 0
          when g then hue = ((b - r) / chroma) + 2
          when b then hue = ((r - g) / chroma) + 4

        hue = (hue * 60).mod(360)

      return [hue, saturation, lightness, @a]

    ###*
    returns string rgba representation of the color.

    <code><pre>
    red = Color('#ff0000')

    red.toString()
    # => 'rgba(255, 0, 0, 1)'
    </pre></code>

    @name toString
    @methodOf Color#

    @returns {String} The rgba string representation of the color
    ###
    toString: ->
      "rgba(#{@r}, #{@g}, #{@b}, #{@a})"

    ###*
    A copy of the calling color with its alpha reduced by `amount`.

    <code><pre>
    color = Color(0, 0, 0, 1)

    color.a
    # => 1

    transparentColor = color.transparentize(0.5)

    transparentColor.a
    # => 0.5
    </pre></code>

    @name transparentize
    @methodOf Color#

    @returns {Color} A copy of the calling color with its alpha reduced by `amount`
    ###
    transparentize: (amount) ->
      @copy().transparentize$(amount)

    ###*
    The calling color with its alpha reduced by `amount`.

    <code><pre>
    color = Color(0, 0, 0, 1)

    color.a
    # => 1

    # We modify color in place
    color.transparentize$(0.5)

    color.a
    # => 0.5
    </pre></code>

    @name transparentize$
    @methodOf Color#

    @returns {Color} The calling color with its alpha reduced by `amount`
    ###
    transparentize$: (amount) ->
      @a = (@a - amount).clamp(0, 1)

      return this

    ###*
    A copy of the calling color with its alpha increased by `amount`.

    <code><pre>
    color = Color(0, 0, 0, 0)

    color.a
    # => 1

    opaqueColor = color.opacify(0.25)

    opaqueColor.a
    # => 0.25
    </pre></code>

    @name opacify
    @methodOf Color#

    @returns {Color} A copy of the calling color with its alpha increased by `amount`
    ###
    opacify: (amount) ->
      @copy().opacify$(amount)

    ###*
    The calling color with its alpha increased by `amount`.

    <code><pre>
    color = Color(0, 0, 0, 0)

    color.a
    # => 1

    # We modify color in place
    color.opacify$(0.25)

    color.a
    # => 0.25
    </pre></code>

    @name opacify$
    @methodOf Color#

    @returns {Color} The calling color with its alpha increased by `amount`
    ###
    opacify$: (amount) ->
      @a += amount

      return this

  lookup = {}

  names = [
    ["000000", "Black"]
    ["000080", "Navy Blue"]
    ["0000C8", "Dark Blue"]
    ["0000FF", "Blue"]
    ["000741", "Stratos"]
    ["001B1C", "Swamp"]
    ["002387", "Resolution Blue"]
    ["002900", "Deep Fir"]
    ["002E20", "Burnham"]
    ["002FA7", "International Klein Blue"]
    ["003153", "Prussian Blue"]
    ["003366", "Midnight Blue"]
    ["003399", "Smalt"]
    ["003532", "Deep Teal"]
    ["003E40", "Cyprus"]
    ["004620", "Kaitoke Green"]
    ["0047AB", "Cobalt"]
    ["004816", "Crusoe"]
    ["004950", "Sherpa Blue"]
    ["0056A7", "Endeavour"]
    ["00581A", "Camarone"]
    ["0066CC", "Science Blue"]
    ["0066FF", "Blue Ribbon"]
    ["00755E", "Tropical Rain Forest"]
    ["0076A3", "Allports"]
    ["007BA7", "Deep Cerulean"]
    ["007EC7", "Lochmara"]
    ["007FFF", "Azure Radiance"]
    ["008080", "Teal"]
    ["0095B6", "Bondi Blue"]
    ["009DC4", "Pacific Blue"]
    ["00A693", "Persian Green"]
    ["00A86B", "Jade"]
    ["00CC99", "Caribbean Green"]
    ["00CCCC", "Robin's Egg Blue"]
    ["00FF00", "Green"]
    ["00FF7F", "Spring Green"]
    ["00FFFF", "Cyan / Aqua"]
    ["010D1A", "Blue Charcoal"]
    ["011635", "Midnight"]
    ["011D13", "Holly"]
    ["012731", "Daintree"]
    ["01361C", "Cardin Green"]
    ["01371A", "County Green"]
    ["013E62", "Astronaut Blue"]
    ["013F6A", "Regal Blue"]
    ["014B43", "Aqua Deep"]
    ["015E85", "Orient"]
    ["016162", "Blue Stone"]
    ["016D39", "Fun Green"]
    ["01796F", "Pine Green"]
    ["017987", "Blue Lagoon"]
    ["01826B", "Deep Sea"]
    ["01A368", "Green Haze"]
    ["022D15", "English Holly"]
    ["02402C", "Sherwood Green"]
    ["02478E", "Congress Blue"]
    ["024E46", "Evening Sea"]
    ["026395", "Bahama Blue"]
    ["02866F", "Observatory"]
    ["02A4D3", "Cerulean"]
    ["03163C", "Tangaroa"]
    ["032B52", "Green Vogue"]
    ["036A6E", "Mosque"]
    ["041004", "Midnight Moss"]
    ["041322", "Black Pearl"]
    ["042E4C", "Blue Whale"]
    ["044022", "Zuccini"]
    ["044259", "Teal Blue"]
    ["051040", "Deep Cove"]
    ["051657", "Gulf Blue"]
    ["055989", "Venice Blue"]
    ["056F57", "Watercourse"]
    ["062A78", "Catalina Blue"]
    ["063537", "Tiber"]
    ["069B81", "Gossamer"]
    ["06A189", "Niagara"]
    ["073A50", "Tarawera"]
    ["080110", "Jaguar"]
    ["081910", "Black Bean"]
    ["082567", "Deep Sapphire"]
    ["088370", "Elf Green"]
    ["08E8DE", "Bright Turquoise"]
    ["092256", "Downriver"]
    ["09230F", "Palm Green"]
    ["09255D", "Madison"]
    ["093624", "Bottle Green"]
    ["095859", "Deep Sea Green"]
    ["097F4B", "Salem"]
    ["0A001C", "Black Russian"]
    ["0A480D", "Dark Fern"]
    ["0A6906", "Japanese Laurel"]
    ["0A6F75", "Atoll"]
    ["0B0B0B", "Cod Gray"]
    ["0B0F08", "Marshland"]
    ["0B1107", "Gordons Green"]
    ["0B1304", "Black Forest"]
    ["0B6207", "San Felix"]
    ["0BDA51", "Malachite"]
    ["0C0B1D", "Ebony"]
    ["0C0D0F", "Woodsmoke"]
    ["0C1911", "Racing Green"]
    ["0C7A79", "Surfie Green"]
    ["0C8990", "Blue Chill"]
    ["0D0332", "Black Rock"]
    ["0D1117", "Bunker"]
    ["0D1C19", "Aztec"]
    ["0D2E1C", "Bush"]
    ["0E0E18", "Cinder"]
    ["0E2A30", "Firefly"]
    ["0F2D9E", "Torea Bay"]
    ["10121D", "Vulcan"]
    ["101405", "Green Waterloo"]
    ["105852", "Eden"]
    ["110C6C", "Arapawa"]
    ["120A8F", "Ultramarine"]
    ["123447", "Elephant"]
    ["126B40", "Jewel"]
    ["130000", "Diesel"]
    ["130A06", "Asphalt"]
    ["13264D", "Blue Zodiac"]
    ["134F19", "Parsley"]
    ["140600", "Nero"]
    ["1450AA", "Tory Blue"]
    ["151F4C", "Bunting"]
    ["1560BD", "Denim"]
    ["15736B", "Genoa"]
    ["161928", "Mirage"]
    ["161D10", "Hunter Green"]
    ["162A40", "Big Stone"]
    ["163222", "Celtic"]
    ["16322C", "Timber Green"]
    ["163531", "Gable Green"]
    ["171F04", "Pine Tree"]
    ["175579", "Chathams Blue"]
    ["182D09", "Deep Forest Green"]
    ["18587A", "Blumine"]
    ["19330E", "Palm Leaf"]
    ["193751", "Nile Blue"]
    ["1959A8", "Fun Blue"]
    ["1A1A68", "Lucky Point"]
    ["1AB385", "Mountain Meadow"]
    ["1B0245", "Tolopea"]
    ["1B1035", "Haiti"]
    ["1B127B", "Deep Koamaru"]
    ["1B1404", "Acadia"]
    ["1B2F11", "Seaweed"]
    ["1B3162", "Biscay"]
    ["1B659D", "Matisse"]
    ["1C1208", "Crowshead"]
    ["1C1E13", "Rangoon Green"]
    ["1C39BB", "Persian Blue"]
    ["1C402E", "Everglade"]
    ["1C7C7D", "Elm"]
    ["1D6142", "Green Pea"]
    ["1E0F04", "Creole"]
    ["1E1609", "Karaka"]
    ["1E1708", "El Paso"]
    ["1E385B", "Cello"]
    ["1E433C", "Te Papa Green"]
    ["1E90FF", "Dodger Blue"]
    ["1E9AB0", "Eastern Blue"]
    ["1F120F", "Night Rider"]
    ["1FC2C2", "Java"]
    ["20208D", "Jacksons Purple"]
    ["202E54", "Cloud Burst"]
    ["204852", "Blue Dianne"]
    ["211A0E", "Eternity"]
    ["220878", "Deep Blue"]
    ["228B22", "Forest Green"]
    ["233418", "Mallard"]
    ["240A40", "Violet"]
    ["240C02", "Kilamanjaro"]
    ["242A1D", "Log Cabin"]
    ["242E16", "Black Olive"]
    ["24500F", "Green House"]
    ["251607", "Graphite"]
    ["251706", "Cannon Black"]
    ["251F4F", "Port Gore"]
    ["25272C", "Shark"]
    ["25311C", "Green Kelp"]
    ["2596D1", "Curious Blue"]
    ["260368", "Paua"]
    ["26056A", "Paris M"]
    ["261105", "Wood Bark"]
    ["261414", "Gondola"]
    ["262335", "Steel Gray"]
    ["26283B", "Ebony Clay"]
    ["273A81", "Bay of Many"]
    ["27504B", "Plantation"]
    ["278A5B", "Eucalyptus"]
    ["281E15", "Oil"]
    ["283A77", "Astronaut"]
    ["286ACD", "Mariner"]
    ["290C5E", "Violent Violet"]
    ["292130", "Bastille"]
    ["292319", "Zeus"]
    ["292937", "Charade"]
    ["297B9A", "Jelly Bean"]
    ["29AB87", "Jungle Green"]
    ["2A0359", "Cherry Pie"]
    ["2A140E", "Coffee Bean"]
    ["2A2630", "Baltic Sea"]
    ["2A380B", "Turtle Green"]
    ["2A52BE", "Cerulean Blue"]
    ["2B0202", "Sepia Black"]
    ["2B194F", "Valhalla"]
    ["2B3228", "Heavy Metal"]
    ["2C0E8C", "Blue Gem"]
    ["2C1632", "Revolver"]
    ["2C2133", "Bleached Cedar"]
    ["2C8C84", "Lochinvar"]
    ["2D2510", "Mikado"]
    ["2D383A", "Outer Space"]
    ["2D569B", "St Tropaz"]
    ["2E0329", "Jacaranda"]
    ["2E1905", "Jacko Bean"]
    ["2E3222", "Rangitoto"]
    ["2E3F62", "Rhino"]
    ["2E8B57", "Sea Green"]
    ["2EBFD4", "Scooter"]
    ["2F270E", "Onion"]
    ["2F3CB3", "Governor Bay"]
    ["2F519E", "Sapphire"]
    ["2F5A57", "Spectra"]
    ["2F6168", "Casal"]
    ["300529", "Melanzane"]
    ["301F1E", "Cocoa Brown"]
    ["302A0F", "Woodrush"]
    ["304B6A", "San Juan"]
    ["30D5C8", "Turquoise"]
    ["311C17", "Eclipse"]
    ["314459", "Pickled Bluewood"]
    ["315BA1", "Azure"]
    ["31728D", "Calypso"]
    ["317D82", "Paradiso"]
    ["32127A", "Persian Indigo"]
    ["32293A", "Blackcurrant"]
    ["323232", "Mine Shaft"]
    ["325D52", "Stromboli"]
    ["327C14", "Bilbao"]
    ["327DA0", "Astral"]
    ["33036B", "Christalle"]
    ["33292F", "Thunder"]
    ["33CC99", "Shamrock"]
    ["341515", "Tamarind"]
    ["350036", "Mardi Gras"]
    ["350E42", "Valentino"]
    ["350E57", "Jagger"]
    ["353542", "Tuna"]
    ["354E8C", "Chambray"]
    ["363050", "Martinique"]
    ["363534", "Tuatara"]
    ["363C0D", "Waiouru"]
    ["36747D", "Ming"]
    ["368716", "La Palma"]
    ["370202", "Chocolate"]
    ["371D09", "Clinker"]
    ["37290E", "Brown Tumbleweed"]
    ["373021", "Birch"]
    ["377475", "Oracle"]
    ["380474", "Blue Diamond"]
    ["381A51", "Grape"]
    ["383533", "Dune"]
    ["384555", "Oxford Blue"]
    ["384910", "Clover"]
    ["394851", "Limed Spruce"]
    ["396413", "Dell"]
    ["3A0020", "Toledo"]
    ["3A2010", "Sambuca"]
    ["3A2A6A", "Jacarta"]
    ["3A686C", "William"]
    ["3A6A47", "Killarney"]
    ["3AB09E", "Keppel"]
    ["3B000B", "Temptress"]
    ["3B0910", "Aubergine"]
    ["3B1F1F", "Jon"]
    ["3B2820", "Treehouse"]
    ["3B7A57", "Amazon"]
    ["3B91B4", "Boston Blue"]
    ["3C0878", "Windsor"]
    ["3C1206", "Rebel"]
    ["3C1F76", "Meteorite"]
    ["3C2005", "Dark Ebony"]
    ["3C3910", "Camouflage"]
    ["3C4151", "Bright Gray"]
    ["3C4443", "Cape Cod"]
    ["3C493A", "Lunar Green"]
    ["3D0C02", "Bean  "]
    ["3D2B1F", "Bistre"]
    ["3D7D52", "Goblin"]
    ["3E0480", "Kingfisher Daisy"]
    ["3E1C14", "Cedar"]
    ["3E2B23", "English Walnut"]
    ["3E2C1C", "Black Marlin"]
    ["3E3A44", "Ship Gray"]
    ["3EABBF", "Pelorous"]
    ["3F2109", "Bronze"]
    ["3F2500", "Cola"]
    ["3F3002", "Madras"]
    ["3F307F", "Minsk"]
    ["3F4C3A", "Cabbage Pont"]
    ["3F583B", "Tom Thumb"]
    ["3F5D53", "Mineral Green"]
    ["3FC1AA", "Puerto Rico"]
    ["3FFF00", "Harlequin"]
    ["401801", "Brown Pod"]
    ["40291D", "Cork"]
    ["403B38", "Masala"]
    ["403D19", "Thatch Green"]
    ["405169", "Fiord"]
    ["40826D", "Viridian"]
    ["40A860", "Chateau Green"]
    ["410056", "Ripe Plum"]
    ["411F10", "Paco"]
    ["412010", "Deep Oak"]
    ["413C37", "Merlin"]
    ["414257", "Gun Powder"]
    ["414C7D", "East Bay"]
    ["4169E1", "Royal Blue"]
    ["41AA78", "Ocean Green"]
    ["420303", "Burnt Maroon"]
    ["423921", "Lisbon Brown"]
    ["427977", "Faded Jade"]
    ["431560", "Scarlet Gum"]
    ["433120", "Iroko"]
    ["433E37", "Armadillo"]
    ["434C59", "River Bed"]
    ["436A0D", "Green Leaf"]
    ["44012D", "Barossa"]
    ["441D00", "Morocco Brown"]
    ["444954", "Mako"]
    ["454936", "Kelp"]
    ["456CAC", "San Marino"]
    ["45B1E8", "Picton Blue"]
    ["460B41", "Loulou"]
    ["462425", "Crater Brown"]
    ["465945", "Gray Asparagus"]
    ["4682B4", "Steel Blue"]
    ["480404", "Rustic Red"]
    ["480607", "Bulgarian Rose"]
    ["480656", "Clairvoyant"]
    ["481C1C", "Cocoa Bean"]
    ["483131", "Woody Brown"]
    ["483C32", "Taupe"]
    ["49170C", "Van Cleef"]
    ["492615", "Brown Derby"]
    ["49371B", "Metallic Bronze"]
    ["495400", "Verdun Green"]
    ["496679", "Blue Bayoux"]
    ["497183", "Bismark"]
    ["4A2A04", "Bracken"]
    ["4A3004", "Deep Bronze"]
    ["4A3C30", "Mondo"]
    ["4A4244", "Tundora"]
    ["4A444B", "Gravel"]
    ["4A4E5A", "Trout"]
    ["4B0082", "Pigment Indigo"]
    ["4B5D52", "Nandor"]
    ["4C3024", "Saddle"]
    ["4C4F56", "Abbey"]
    ["4D0135", "Blackberry"]
    ["4D0A18", "Cab Sav"]
    ["4D1E01", "Indian Tan"]
    ["4D282D", "Cowboy"]
    ["4D282E", "Livid Brown"]
    ["4D3833", "Rock"]
    ["4D3D14", "Punga"]
    ["4D400F", "Bronzetone"]
    ["4D5328", "Woodland"]
    ["4E0606", "Mahogany"]
    ["4E2A5A", "Bossanova"]
    ["4E3B41", "Matterhorn"]
    ["4E420C", "Bronze Olive"]
    ["4E4562", "Mulled Wine"]
    ["4E6649", "Axolotl"]
    ["4E7F9E", "Wedgewood"]
    ["4EABD1", "Shakespeare"]
    ["4F1C70", "Honey Flower"]
    ["4F2398", "Daisy Bush"]
    ["4F69C6", "Indigo"]
    ["4F7942", "Fern Green"]
    ["4F9D5D", "Fruit Salad"]
    ["4FA83D", "Apple"]
    ["504351", "Mortar"]
    ["507096", "Kashmir Blue"]
    ["507672", "Cutty Sark"]
    ["50C878", "Emerald"]
    ["514649", "Emperor"]
    ["516E3D", "Chalet Green"]
    ["517C66", "Como"]
    ["51808F", "Smalt Blue"]
    ["52001F", "Castro"]
    ["520C17", "Maroon Oak"]
    ["523C94", "Gigas"]
    ["533455", "Voodoo"]
    ["534491", "Victoria"]
    ["53824B", "Hippie Green"]
    ["541012", "Heath"]
    ["544333", "Judge Gray"]
    ["54534D", "Fuscous Gray"]
    ["549019", "Vida Loca"]
    ["55280C", "Cioccolato"]
    ["555B10", "Saratoga"]
    ["556D56", "Finlandia"]
    ["5590D9", "Havelock Blue"]
    ["56B4BE", "Fountain Blue"]
    ["578363", "Spring Leaves"]
    ["583401", "Saddle Brown"]
    ["585562", "Scarpa Flow"]
    ["587156", "Cactus"]
    ["589AAF", "Hippie Blue"]
    ["591D35", "Wine Berry"]
    ["592804", "Brown Bramble"]
    ["593737", "Congo Brown"]
    ["594433", "Millbrook"]
    ["5A6E9C", "Waikawa Gray"]
    ["5A87A0", "Horizon"]
    ["5B3013", "Jambalaya"]
    ["5C0120", "Bordeaux"]
    ["5C0536", "Mulberry Wood"]
    ["5C2E01", "Carnaby Tan"]
    ["5C5D75", "Comet"]
    ["5D1E0F", "Redwood"]
    ["5D4C51", "Don Juan"]
    ["5D5C58", "Chicago"]
    ["5D5E37", "Verdigris"]
    ["5D7747", "Dingley"]
    ["5DA19F", "Breaker Bay"]
    ["5E483E", "Kabul"]
    ["5E5D3B", "Hemlock"]
    ["5F3D26", "Irish Coffee"]
    ["5F5F6E", "Mid Gray"]
    ["5F6672", "Shuttle Gray"]
    ["5FA777", "Aqua Forest"]
    ["5FB3AC", "Tradewind"]
    ["604913", "Horses Neck"]
    ["605B73", "Smoky"]
    ["606E68", "Corduroy"]
    ["6093D1", "Danube"]
    ["612718", "Espresso"]
    ["614051", "Eggplant"]
    ["615D30", "Costa Del Sol"]
    ["61845F", "Glade Green"]
    ["622F30", "Buccaneer"]
    ["623F2D", "Quincy"]
    ["624E9A", "Butterfly Bush"]
    ["625119", "West Coast"]
    ["626649", "Finch"]
    ["639A8F", "Patina"]
    ["63B76C", "Fern"]
    ["6456B7", "Blue Violet"]
    ["646077", "Dolphin"]
    ["646463", "Storm Dust"]
    ["646A54", "Siam"]
    ["646E75", "Nevada"]
    ["6495ED", "Cornflower Blue"]
    ["64CCDB", "Viking"]
    ["65000B", "Rosewood"]
    ["651A14", "Cherrywood"]
    ["652DC1", "Purple Heart"]
    ["657220", "Fern Frond"]
    ["65745D", "Willow Grove"]
    ["65869F", "Hoki"]
    ["660045", "Pompadour"]
    ["660099", "Purple"]
    ["66023C", "Tyrian Purple"]
    ["661010", "Dark Tan"]
    ["66B58F", "Silver Tree"]
    ["66FF00", "Bright Green"]
    ["66FF66", "Screamin' Green"]
    ["67032D", "Black Rose"]
    ["675FA6", "Scampi"]
    ["676662", "Ironside Gray"]
    ["678975", "Viridian Green"]
    ["67A712", "Christi"]
    ["683600", "Nutmeg Wood Finish"]
    ["685558", "Zambezi"]
    ["685E6E", "Salt Box"]
    ["692545", "Tawny Port"]
    ["692D54", "Finn"]
    ["695F62", "Scorpion"]
    ["697E9A", "Lynch"]
    ["6A442E", "Spice"]
    ["6A5D1B", "Himalaya"]
    ["6A6051", "Soya Bean"]
    ["6B2A14", "Hairy Heath"]
    ["6B3FA0", "Royal Purple"]
    ["6B4E31", "Shingle Fawn"]
    ["6B5755", "Dorado"]
    ["6B8BA2", "Bermuda Gray"]
    ["6B8E23", "Olive Drab"]
    ["6C3082", "Eminence"]
    ["6CDAE7", "Turquoise Blue"]
    ["6D0101", "Lonestar"]
    ["6D5E54", "Pine Cone"]
    ["6D6C6C", "Dove Gray"]
    ["6D9292", "Juniper"]
    ["6D92A1", "Gothic"]
    ["6E0902", "Red Oxide"]
    ["6E1D14", "Moccaccino"]
    ["6E4826", "Pickled Bean"]
    ["6E4B26", "Dallas"]
    ["6E6D57", "Kokoda"]
    ["6E7783", "Pale Sky"]
    ["6F440C", "Cafe Royale"]
    ["6F6A61", "Flint"]
    ["6F8E63", "Highland"]
    ["6F9D02", "Limeade"]
    ["6FD0C5", "Downy"]
    ["701C1C", "Persian Plum"]
    ["704214", "Sepia"]
    ["704A07", "Antique Bronze"]
    ["704F50", "Ferra"]
    ["706555", "Coffee"]
    ["708090", "Slate Gray"]
    ["711A00", "Cedar Wood Finish"]
    ["71291D", "Metallic Copper"]
    ["714693", "Affair"]
    ["714AB2", "Studio"]
    ["715D47", "Tobacco Brown"]
    ["716338", "Yellow Metal"]
    ["716B56", "Peat"]
    ["716E10", "Olivetone"]
    ["717486", "Storm Gray"]
    ["718080", "Sirocco"]
    ["71D9E2", "Aquamarine Blue"]
    ["72010F", "Venetian Red"]
    ["724A2F", "Old Copper"]
    ["726D4E", "Go Ben"]
    ["727B89", "Raven"]
    ["731E8F", "Seance"]
    ["734A12", "Raw Umber"]
    ["736C9F", "Kimberly"]
    ["736D58", "Crocodile"]
    ["737829", "Crete"]
    ["738678", "Xanadu"]
    ["74640D", "Spicy Mustard"]
    ["747D63", "Limed Ash"]
    ["747D83", "Rolling Stone"]
    ["748881", "Blue Smoke"]
    ["749378", "Laurel"]
    ["74C365", "Mantis"]
    ["755A57", "Russett"]
    ["7563A8", "Deluge"]
    ["76395D", "Cosmic"]
    ["7666C6", "Blue Marguerite"]
    ["76BD17", "Lima"]
    ["76D7EA", "Sky Blue"]
    ["770F05", "Dark Burgundy"]
    ["771F1F", "Crown of Thorns"]
    ["773F1A", "Walnut"]
    ["776F61", "Pablo"]
    ["778120", "Pacifika"]
    ["779E86", "Oxley"]
    ["77DD77", "Pastel Green"]
    ["780109", "Japanese Maple"]
    ["782D19", "Mocha"]
    ["782F16", "Peanut"]
    ["78866B", "Camouflage Green"]
    ["788A25", "Wasabi"]
    ["788BBA", "Ship Cove"]
    ["78A39C", "Sea Nymph"]
    ["795D4C", "Roman Coffee"]
    ["796878", "Old Lavender"]
    ["796989", "Rum"]
    ["796A78", "Fedora"]
    ["796D62", "Sandstone"]
    ["79DEEC", "Spray"]
    ["7A013A", "Siren"]
    ["7A58C1", "Fuchsia Blue"]
    ["7A7A7A", "Boulder"]
    ["7A89B8", "Wild Blue Yonder"]
    ["7AC488", "De York"]
    ["7B3801", "Red Beech"]
    ["7B3F00", "Cinnamon"]
    ["7B6608", "Yukon Gold"]
    ["7B7874", "Tapa"]
    ["7B7C94", "Waterloo "]
    ["7B8265", "Flax Smoke"]
    ["7B9F80", "Amulet"]
    ["7BA05B", "Asparagus"]
    ["7C1C05", "Kenyan Copper"]
    ["7C7631", "Pesto"]
    ["7C778A", "Topaz"]
    ["7C7B7A", "Concord"]
    ["7C7B82", "Jumbo"]
    ["7C881A", "Trendy Green"]
    ["7CA1A6", "Gumbo"]
    ["7CB0A1", "Acapulco"]
    ["7CB7BB", "Neptune"]
    ["7D2C14", "Pueblo"]
    ["7DA98D", "Bay Leaf"]
    ["7DC8F7", "Malibu"]
    ["7DD8C6", "Bermuda"]
    ["7E3A15", "Copper Canyon"]
    ["7F1734", "Claret"]
    ["7F3A02", "Peru Tan"]
    ["7F626D", "Falcon"]
    ["7F7589", "Mobster"]
    ["7F76D3", "Moody Blue"]
    ["7FFF00", "Chartreuse"]
    ["7FFFD4", "Aquamarine"]
    ["800000", "Maroon"]
    ["800B47", "Rose Bud Cherry"]
    ["801818", "Falu Red"]
    ["80341F", "Red Robin"]
    ["803790", "Vivid Violet"]
    ["80461B", "Russet"]
    ["807E79", "Friar Gray"]
    ["808000", "Olive"]
    ["808080", "Gray"]
    ["80B3AE", "Gulf Stream"]
    ["80B3C4", "Glacier"]
    ["80CCEA", "Seagull"]
    ["81422C", "Nutmeg"]
    ["816E71", "Spicy Pink"]
    ["817377", "Empress"]
    ["819885", "Spanish Green"]
    ["826F65", "Sand Dune"]
    ["828685", "Gunsmoke"]
    ["828F72", "Battleship Gray"]
    ["831923", "Merlot"]
    ["837050", "Shadow"]
    ["83AA5D", "Chelsea Cucumber"]
    ["83D0C6", "Monte Carlo"]
    ["843179", "Plum"]
    ["84A0A0", "Granny Smith"]
    ["8581D9", "Chetwode Blue"]
    ["858470", "Bandicoot"]
    ["859FAF", "Bali Hai"]
    ["85C4CC", "Half Baked"]
    ["860111", "Red Devil"]
    ["863C3C", "Lotus"]
    ["86483C", "Ironstone"]
    ["864D1E", "Bull Shot"]
    ["86560A", "Rusty Nail"]
    ["868974", "Bitter"]
    ["86949F", "Regent Gray"]
    ["871550", "Disco"]
    ["87756E", "Americano"]
    ["877C7B", "Hurricane"]
    ["878D91", "Oslo Gray"]
    ["87AB39", "Sushi"]
    ["885342", "Spicy Mix"]
    ["886221", "Kumera"]
    ["888387", "Suva Gray"]
    ["888D65", "Avocado"]
    ["893456", "Camelot"]
    ["893843", "Solid Pink"]
    ["894367", "Cannon Pink"]
    ["897D6D", "Makara"]
    ["8A3324", "Burnt Umber"]
    ["8A73D6", "True V"]
    ["8A8360", "Clay Creek"]
    ["8A8389", "Monsoon"]
    ["8A8F8A", "Stack"]
    ["8AB9F1", "Jordy Blue"]
    ["8B00FF", "Electric Violet"]
    ["8B0723", "Monarch"]
    ["8B6B0B", "Corn Harvest"]
    ["8B8470", "Olive Haze"]
    ["8B847E", "Schooner"]
    ["8B8680", "Natural Gray"]
    ["8B9C90", "Mantle"]
    ["8B9FEE", "Portage"]
    ["8BA690", "Envy"]
    ["8BA9A5", "Cascade"]
    ["8BE6D8", "Riptide"]
    ["8C055E", "Cardinal Pink"]
    ["8C472F", "Mule Fawn"]
    ["8C5738", "Potters Clay"]
    ["8C6495", "Trendy Pink"]
    ["8D0226", "Paprika"]
    ["8D3D38", "Sanguine Brown"]
    ["8D3F3F", "Tosca"]
    ["8D7662", "Cement"]
    ["8D8974", "Granite Green"]
    ["8D90A1", "Manatee"]
    ["8DA8CC", "Polo Blue"]
    ["8E0000", "Red Berry"]
    ["8E4D1E", "Rope"]
    ["8E6F70", "Opium"]
    ["8E775E", "Domino"]
    ["8E8190", "Mamba"]
    ["8EABC1", "Nepal"]
    ["8F021C", "Pohutukawa"]
    ["8F3E33", "El Salva"]
    ["8F4B0E", "Korma"]
    ["8F8176", "Squirrel"]
    ["8FD6B4", "Vista Blue"]
    ["900020", "Burgundy"]
    ["901E1E", "Old Brick"]
    ["907874", "Hemp"]
    ["907B71", "Almond Frost"]
    ["908D39", "Sycamore"]
    ["92000A", "Sangria"]
    ["924321", "Cumin"]
    ["926F5B", "Beaver"]
    ["928573", "Stonewall"]
    ["928590", "Venus"]
    ["9370DB", "Medium Purple"]
    ["93CCEA", "Cornflower"]
    ["93DFB8", "Algae Green"]
    ["944747", "Copper Rust"]
    ["948771", "Arrowtown"]
    ["950015", "Scarlett"]
    ["956387", "Strikemaster"]
    ["959396", "Mountain Mist"]
    ["960018", "Carmine"]
    ["964B00", "Brown"]
    ["967059", "Leather"]
    ["9678B6", "Purple Mountain's Majesty"]
    ["967BB6", "Lavender Purple"]
    ["96A8A1", "Pewter"]
    ["96BBAB", "Summer Green"]
    ["97605D", "Au Chico"]
    ["9771B5", "Wisteria"]
    ["97CD2D", "Atlantis"]
    ["983D61", "Vin Rouge"]
    ["9874D3", "Lilac Bush"]
    ["98777B", "Bazaar"]
    ["98811B", "Hacienda"]
    ["988D77", "Pale Oyster"]
    ["98FF98", "Mint Green"]
    ["990066", "Fresh Eggplant"]
    ["991199", "Violet Eggplant"]
    ["991613", "Tamarillo"]
    ["991B07", "Totem Pole"]
    ["996666", "Copper Rose"]
    ["9966CC", "Amethyst"]
    ["997A8D", "Mountbatten Pink"]
    ["9999CC", "Blue Bell"]
    ["9A3820", "Prairie Sand"]
    ["9A6E61", "Toast"]
    ["9A9577", "Gurkha"]
    ["9AB973", "Olivine"]
    ["9AC2B8", "Shadow Green"]
    ["9B4703", "Oregon"]
    ["9B9E8F", "Lemon Grass"]
    ["9C3336", "Stiletto"]
    ["9D5616", "Hawaiian Tan"]
    ["9DACB7", "Gull Gray"]
    ["9DC209", "Pistachio"]
    ["9DE093", "Granny Smith Apple"]
    ["9DE5FF", "Anakiwa"]
    ["9E5302", "Chelsea Gem"]
    ["9E5B40", "Sepia Skin"]
    ["9EA587", "Sage"]
    ["9EA91F", "Citron"]
    ["9EB1CD", "Rock Blue"]
    ["9EDEE0", "Morning Glory"]
    ["9F381D", "Cognac"]
    ["9F821C", "Reef Gold"]
    ["9F9F9C", "Star Dust"]
    ["9FA0B1", "Santas Gray"]
    ["9FD7D3", "Sinbad"]
    ["9FDD8C", "Feijoa"]
    ["A02712", "Tabasco"]
    ["A1750D", "Buttered Rum"]
    ["A1ADB5", "Hit Gray"]
    ["A1C50A", "Citrus"]
    ["A1DAD7", "Aqua Island"]
    ["A1E9DE", "Water Leaf"]
    ["A2006D", "Flirt"]
    ["A23B6C", "Rouge"]
    ["A26645", "Cape Palliser"]
    ["A2AAB3", "Gray Chateau"]
    ["A2AEAB", "Edward"]
    ["A3807B", "Pharlap"]
    ["A397B4", "Amethyst Smoke"]
    ["A3E3ED", "Blizzard Blue"]
    ["A4A49D", "Delta"]
    ["A4A6D3", "Wistful"]
    ["A4AF6E", "Green Smoke"]
    ["A50B5E", "Jazzberry Jam"]
    ["A59B91", "Zorba"]
    ["A5CB0C", "Bahia"]
    ["A62F20", "Roof Terracotta"]
    ["A65529", "Paarl"]
    ["A68B5B", "Barley Corn"]
    ["A69279", "Donkey Brown"]
    ["A6A29A", "Dawn"]
    ["A72525", "Mexican Red"]
    ["A7882C", "Luxor Gold"]
    ["A85307", "Rich Gold"]
    ["A86515", "Reno Sand"]
    ["A86B6B", "Coral Tree"]
    ["A8989B", "Dusty Gray"]
    ["A899E6", "Dull Lavender"]
    ["A8A589", "Tallow"]
    ["A8AE9C", "Bud"]
    ["A8AF8E", "Locust"]
    ["A8BD9F", "Norway"]
    ["A8E3BD", "Chinook"]
    ["A9A491", "Gray Olive"]
    ["A9ACB6", "Aluminium"]
    ["A9B2C3", "Cadet Blue"]
    ["A9B497", "Schist"]
    ["A9BDBF", "Tower Gray"]
    ["A9BEF2", "Perano"]
    ["A9C6C2", "Opal"]
    ["AA375A", "Night Shadz"]
    ["AA4203", "Fire"]
    ["AA8B5B", "Muesli"]
    ["AA8D6F", "Sandal"]
    ["AAA5A9", "Shady Lady"]
    ["AAA9CD", "Logan"]
    ["AAABB7", "Spun Pearl"]
    ["AAD6E6", "Regent St Blue"]
    ["AAF0D1", "Magic Mint"]
    ["AB0563", "Lipstick"]
    ["AB3472", "Royal Heath"]
    ["AB917A", "Sandrift"]
    ["ABA0D9", "Cold Purple"]
    ["ABA196", "Bronco"]
    ["AC8A56", "Limed Oak"]
    ["AC91CE", "East Side"]
    ["AC9E22", "Lemon Ginger"]
    ["ACA494", "Napa"]
    ["ACA586", "Hillary"]
    ["ACA59F", "Cloudy"]
    ["ACACAC", "Silver Chalice"]
    ["ACB78E", "Swamp Green"]
    ["ACCBB1", "Spring Rain"]
    ["ACDD4D", "Conifer"]
    ["ACE1AF", "Celadon"]
    ["AD781B", "Mandalay"]
    ["ADBED1", "Casper"]
    ["ADDFAD", "Moss Green"]
    ["ADE6C4", "Padua"]
    ["ADFF2F", "Green Yellow"]
    ["AE4560", "Hippie Pink"]
    ["AE6020", "Desert"]
    ["AE809E", "Bouquet"]
    ["AF4035", "Medium Carmine"]
    ["AF4D43", "Apple Blossom"]
    ["AF593E", "Brown Rust"]
    ["AF8751", "Driftwood"]
    ["AF8F2C", "Alpine"]
    ["AF9F1C", "Lucky"]
    ["AFA09E", "Martini"]
    ["AFB1B8", "Bombay"]
    ["AFBDD9", "Pigeon Post"]
    ["B04C6A", "Cadillac"]
    ["B05D54", "Matrix"]
    ["B05E81", "Tapestry"]
    ["B06608", "Mai Tai"]
    ["B09A95", "Del Rio"]
    ["B0E0E6", "Powder Blue"]
    ["B0E313", "Inch Worm"]
    ["B10000", "Bright Red"]
    ["B14A0B", "Vesuvius"]
    ["B1610B", "Pumpkin Skin"]
    ["B16D52", "Santa Fe"]
    ["B19461", "Teak"]
    ["B1E2C1", "Fringy Flower"]
    ["B1F4E7", "Ice Cold"]
    ["B20931", "Shiraz"]
    ["B2A1EA", "Biloba Flower"]
    ["B32D29", "Tall Poppy"]
    ["B35213", "Fiery Orange"]
    ["B38007", "Hot Toddy"]
    ["B3AF95", "Taupe Gray"]
    ["B3C110", "La Rioja"]
    ["B43332", "Well Read"]
    ["B44668", "Blush"]
    ["B4CFD3", "Jungle Mist"]
    ["B57281", "Turkish Rose"]
    ["B57EDC", "Lavender"]
    ["B5A27F", "Mongoose"]
    ["B5B35C", "Olive Green"]
    ["B5D2CE", "Jet Stream"]
    ["B5ECDF", "Cruise"]
    ["B6316C", "Hibiscus"]
    ["B69D98", "Thatch"]
    ["B6B095", "Heathered Gray"]
    ["B6BAA4", "Eagle"]
    ["B6D1EA", "Spindle"]
    ["B6D3BF", "Gum Leaf"]
    ["B7410E", "Rust"]
    ["B78E5C", "Muddy Waters"]
    ["B7A214", "Sahara"]
    ["B7A458", "Husk"]
    ["B7B1B1", "Nobel"]
    ["B7C3D0", "Heather"]
    ["B7F0BE", "Madang"]
    ["B81104", "Milano Red"]
    ["B87333", "Copper"]
    ["B8B56A", "Gimblet"]
    ["B8C1B1", "Green Spring"]
    ["B8C25D", "Celery"]
    ["B8E0F9", "Sail"]
    ["B94E48", "Chestnut"]
    ["B95140", "Crail"]
    ["B98D28", "Marigold"]
    ["B9C46A", "Wild Willow"]
    ["B9C8AC", "Rainee"]
    ["BA0101", "Guardsman Red"]
    ["BA450C", "Rock Spray"]
    ["BA6F1E", "Bourbon"]
    ["BA7F03", "Pirate Gold"]
    ["BAB1A2", "Nomad"]
    ["BAC7C9", "Submarine"]
    ["BAEEF9", "Charlotte"]
    ["BB3385", "Medium Red Violet"]
    ["BB8983", "Brandy Rose"]
    ["BBD009", "Rio Grande"]
    ["BBD7C1", "Surf"]
    ["BCC9C2", "Powder Ash"]
    ["BD5E2E", "Tuscany"]
    ["BD978E", "Quicksand"]
    ["BDB1A8", "Silk"]
    ["BDB2A1", "Malta"]
    ["BDB3C7", "Chatelle"]
    ["BDBBD7", "Lavender Gray"]
    ["BDBDC6", "French Gray"]
    ["BDC8B3", "Clay Ash"]
    ["BDC9CE", "Loblolly"]
    ["BDEDFD", "French Pass"]
    ["BEA6C3", "London Hue"]
    ["BEB5B7", "Pink Swan"]
    ["BEDE0D", "Fuego"]
    ["BF5500", "Rose of Sharon"]
    ["BFB8B0", "Tide"]
    ["BFBED8", "Blue Haze"]
    ["BFC1C2", "Silver Sand"]
    ["BFC921", "Key Lime Pie"]
    ["BFDBE2", "Ziggurat"]
    ["BFFF00", "Lime"]
    ["C02B18", "Thunderbird"]
    ["C04737", "Mojo"]
    ["C08081", "Old Rose"]
    ["C0C0C0", "Silver"]
    ["C0D3B9", "Pale Leaf"]
    ["C0D8B6", "Pixie Green"]
    ["C1440E", "Tia Maria"]
    ["C154C1", "Fuchsia Pink"]
    ["C1A004", "Buddha Gold"]
    ["C1B7A4", "Bison Hide"]
    ["C1BAB0", "Tea"]
    ["C1BECD", "Gray Suit"]
    ["C1D7B0", "Sprout"]
    ["C1F07C", "Sulu"]
    ["C26B03", "Indochine"]
    ["C2955D", "Twine"]
    ["C2BDB6", "Cotton Seed"]
    ["C2CAC4", "Pumice"]
    ["C2E8E5", "Jagged Ice"]
    ["C32148", "Maroon Flush"]
    ["C3B091", "Indian Khaki"]
    ["C3BFC1", "Pale Slate"]
    ["C3C3BD", "Gray Nickel"]
    ["C3CDE6", "Periwinkle Gray"]
    ["C3D1D1", "Tiara"]
    ["C3DDF9", "Tropical Blue"]
    ["C41E3A", "Cardinal"]
    ["C45655", "Fuzzy Wuzzy Brown"]
    ["C45719", "Orange Roughy"]
    ["C4C4BC", "Mist Gray"]
    ["C4D0B0", "Coriander"]
    ["C4F4EB", "Mint Tulip"]
    ["C54B8C", "Mulberry"]
    ["C59922", "Nugget"]
    ["C5994B", "Tussock"]
    ["C5DBCA", "Sea Mist"]
    ["C5E17A", "Yellow Green"]
    ["C62D42", "Brick Red"]
    ["C6726B", "Contessa"]
    ["C69191", "Oriental Pink"]
    ["C6A84B", "Roti"]
    ["C6C3B5", "Ash"]
    ["C6C8BD", "Kangaroo"]
    ["C6E610", "Las Palmas"]
    ["C7031E", "Monza"]
    ["C71585", "Red Violet"]
    ["C7BCA2", "Coral Reef"]
    ["C7C1FF", "Melrose"]
    ["C7C4BF", "Cloud"]
    ["C7C9D5", "Ghost"]
    ["C7CD90", "Pine Glade"]
    ["C7DDE5", "Botticelli"]
    ["C88A65", "Antique Brass"]
    ["C8A2C8", "Lilac"]
    ["C8A528", "Hokey Pokey"]
    ["C8AABF", "Lily"]
    ["C8B568", "Laser"]
    ["C8E3D7", "Edgewater"]
    ["C96323", "Piper"]
    ["C99415", "Pizza"]
    ["C9A0DC", "Light Wisteria"]
    ["C9B29B", "Rodeo Dust"]
    ["C9B35B", "Sundance"]
    ["C9B93B", "Earls Green"]
    ["C9C0BB", "Silver Rust"]
    ["C9D9D2", "Conch"]
    ["C9FFA2", "Reef"]
    ["C9FFE5", "Aero Blue"]
    ["CA3435", "Flush Mahogany"]
    ["CABB48", "Turmeric"]
    ["CADCD4", "Paris White"]
    ["CAE00D", "Bitter Lemon"]
    ["CAE6DA", "Skeptic"]
    ["CB8FA9", "Viola"]
    ["CBCAB6", "Foggy Gray"]
    ["CBD3B0", "Green Mist"]
    ["CBDBD6", "Nebula"]
    ["CC3333", "Persian Red"]
    ["CC5500", "Burnt Orange"]
    ["CC7722", "Ochre"]
    ["CC8899", "Puce"]
    ["CCCAA8", "Thistle Green"]
    ["CCCCFF", "Periwinkle"]
    ["CCFF00", "Electric Lime"]
    ["CD5700", "Tenn"]
    ["CD5C5C", "Chestnut Rose"]
    ["CD8429", "Brandy Punch"]
    ["CDF4FF", "Onahau"]
    ["CEB98F", "Sorrell Brown"]
    ["CEBABA", "Cold Turkey"]
    ["CEC291", "Yuma"]
    ["CEC7A7", "Chino"]
    ["CFA39D", "Eunry"]
    ["CFB53B", "Old Gold"]
    ["CFDCCF", "Tasman"]
    ["CFE5D2", "Surf Crest"]
    ["CFF9F3", "Humming Bird"]
    ["CFFAF4", "Scandal"]
    ["D05F04", "Red Stage"]
    ["D06DA1", "Hopbush"]
    ["D07D12", "Meteor"]
    ["D0BEF8", "Perfume"]
    ["D0C0E5", "Prelude"]
    ["D0F0C0", "Tea Green"]
    ["D18F1B", "Geebung"]
    ["D1BEA8", "Vanilla"]
    ["D1C6B4", "Soft Amber"]
    ["D1D2CA", "Celeste"]
    ["D1D2DD", "Mischka"]
    ["D1E231", "Pear"]
    ["D2691E", "Hot Cinnamon"]
    ["D27D46", "Raw Sienna"]
    ["D29EAA", "Careys Pink"]
    ["D2B48C", "Tan"]
    ["D2DA97", "Deco"]
    ["D2F6DE", "Blue Romance"]
    ["D2F8B0", "Gossip"]
    ["D3CBBA", "Sisal"]
    ["D3CDC5", "Swirl"]
    ["D47494", "Charm"]
    ["D4B6AF", "Clam Shell"]
    ["D4BF8D", "Straw"]
    ["D4C4A8", "Akaroa"]
    ["D4CD16", "Bird Flower"]
    ["D4D7D9", "Iron"]
    ["D4DFE2", "Geyser"]
    ["D4E2FC", "Hawkes Blue"]
    ["D54600", "Grenadier"]
    ["D591A4", "Can Can"]
    ["D59A6F", "Whiskey"]
    ["D5D195", "Winter Hazel"]
    ["D5F6E3", "Granny Apple"]
    ["D69188", "My Pink"]
    ["D6C562", "Tacha"]
    ["D6CEF6", "Moon Raker"]
    ["D6D6D1", "Quill Gray"]
    ["D6FFDB", "Snowy Mint"]
    ["D7837F", "New York Pink"]
    ["D7C498", "Pavlova"]
    ["D7D0FF", "Fog"]
    ["D84437", "Valencia"]
    ["D87C63", "Japonica"]
    ["D8BFD8", "Thistle"]
    ["D8C2D5", "Maverick"]
    ["D8FCFA", "Foam"]
    ["D94972", "Cabaret"]
    ["D99376", "Burning Sand"]
    ["D9B99B", "Cameo"]
    ["D9D6CF", "Timberwolf"]
    ["D9DCC1", "Tana"]
    ["D9E4F5", "Link Water"]
    ["D9F7FF", "Mabel"]
    ["DA3287", "Cerise"]
    ["DA5B38", "Flame Pea"]
    ["DA6304", "Bamboo"]
    ["DA6A41", "Red Damask"]
    ["DA70D6", "Orchid"]
    ["DA8A67", "Copperfield"]
    ["DAA520", "Golden Grass"]
    ["DAECD6", "Zanah"]
    ["DAF4F0", "Iceberg"]
    ["DAFAFF", "Oyster Bay"]
    ["DB5079", "Cranberry"]
    ["DB9690", "Petite Orchid"]
    ["DB995E", "Di Serria"]
    ["DBDBDB", "Alto"]
    ["DBFFF8", "Frosted Mint"]
    ["DC143C", "Crimson"]
    ["DC4333", "Punch"]
    ["DCB20C", "Galliano"]
    ["DCB4BC", "Blossom"]
    ["DCD747", "Wattle"]
    ["DCD9D2", "Westar"]
    ["DCDDCC", "Moon Mist"]
    ["DCEDB4", "Caper"]
    ["DCF0EA", "Swans Down"]
    ["DDD6D5", "Swiss Coffee"]
    ["DDF9F1", "White Ice"]
    ["DE3163", "Cerise Red"]
    ["DE6360", "Roman"]
    ["DEA681", "Tumbleweed"]
    ["DEBA13", "Gold Tips"]
    ["DEC196", "Brandy"]
    ["DECBC6", "Wafer"]
    ["DED4A4", "Sapling"]
    ["DED717", "Barberry"]
    ["DEE5C0", "Beryl Green"]
    ["DEF5FF", "Pattens Blue"]
    ["DF73FF", "Heliotrope"]
    ["DFBE6F", "Apache"]
    ["DFCD6F", "Chenin"]
    ["DFCFDB", "Lola"]
    ["DFECDA", "Willow Brook"]
    ["DFFF00", "Chartreuse Yellow"]
    ["E0B0FF", "Mauve"]
    ["E0B646", "Anzac"]
    ["E0B974", "Harvest Gold"]
    ["E0C095", "Calico"]
    ["E0FFFF", "Baby Blue"]
    ["E16865", "Sunglo"]
    ["E1BC64", "Equator"]
    ["E1C0C8", "Pink Flare"]
    ["E1E6D6", "Periglacial Blue"]
    ["E1EAD4", "Kidnapper"]
    ["E1F6E8", "Tara"]
    ["E25465", "Mandy"]
    ["E2725B", "Terracotta"]
    ["E28913", "Golden Bell"]
    ["E292C0", "Shocking"]
    ["E29418", "Dixie"]
    ["E29CD2", "Light Orchid"]
    ["E2D8ED", "Snuff"]
    ["E2EBED", "Mystic"]
    ["E2F3EC", "Apple Green"]
    ["E30B5C", "Razzmatazz"]
    ["E32636", "Alizarin Crimson"]
    ["E34234", "Cinnabar"]
    ["E3BEBE", "Cavern Pink"]
    ["E3F5E1", "Peppermint"]
    ["E3F988", "Mindaro"]
    ["E47698", "Deep Blush"]
    ["E49B0F", "Gamboge"]
    ["E4C2D5", "Melanie"]
    ["E4CFDE", "Twilight"]
    ["E4D1C0", "Bone"]
    ["E4D422", "Sunflower"]
    ["E4D5B7", "Grain Brown"]
    ["E4D69B", "Zombie"]
    ["E4F6E7", "Frostee"]
    ["E4FFD1", "Snow Flurry"]
    ["E52B50", "Amaranth"]
    ["E5841B", "Zest"]
    ["E5CCC9", "Dust Storm"]
    ["E5D7BD", "Stark White"]
    ["E5D8AF", "Hampton"]
    ["E5E0E1", "Bon Jour"]
    ["E5E5E5", "Mercury"]
    ["E5F9F6", "Polar"]
    ["E64E03", "Trinidad"]
    ["E6BE8A", "Gold Sand"]
    ["E6BEA5", "Cashmere"]
    ["E6D7B9", "Double Spanish White"]
    ["E6E4D4", "Satin Linen"]
    ["E6F2EA", "Harp"]
    ["E6F8F3", "Off Green"]
    ["E6FFE9", "Hint of Green"]
    ["E6FFFF", "Tranquil"]
    ["E77200", "Mango Tango"]
    ["E7730A", "Christine"]
    ["E79F8C", "Tonys Pink"]
    ["E79FC4", "Kobi"]
    ["E7BCB4", "Rose Fog"]
    ["E7BF05", "Corn"]
    ["E7CD8C", "Putty"]
    ["E7ECE6", "Gray Nurse"]
    ["E7F8FF", "Lily White"]
    ["E7FEFF", "Bubbles"]
    ["E89928", "Fire Bush"]
    ["E8B9B3", "Shilo"]
    ["E8E0D5", "Pearl Bush"]
    ["E8EBE0", "Green White"]
    ["E8F1D4", "Chrome White"]
    ["E8F2EB", "Gin"]
    ["E8F5F2", "Aqua Squeeze"]
    ["E96E00", "Clementine"]
    ["E97451", "Burnt Sienna"]
    ["E97C07", "Tahiti Gold"]
    ["E9CECD", "Oyster Pink"]
    ["E9D75A", "Confetti"]
    ["E9E3E3", "Ebb"]
    ["E9F8ED", "Ottoman"]
    ["E9FFFD", "Clear Day"]
    ["EA88A8", "Carissma"]
    ["EAAE69", "Porsche"]
    ["EAB33B", "Tulip Tree"]
    ["EAC674", "Rob Roy"]
    ["EADAB8", "Raffia"]
    ["EAE8D4", "White Rock"]
    ["EAF6EE", "Panache"]
    ["EAF6FF", "Solitude"]
    ["EAF9F5", "Aqua Spring"]
    ["EAFFFE", "Dew"]
    ["EB9373", "Apricot"]
    ["EBC2AF", "Zinnwaldite"]
    ["ECA927", "Fuel Yellow"]
    ["ECC54E", "Ronchi"]
    ["ECC7EE", "French Lilac"]
    ["ECCDB9", "Just Right"]
    ["ECE090", "Wild Rice"]
    ["ECEBBD", "Fall Green"]
    ["ECEBCE", "Aths Special"]
    ["ECF245", "Starship"]
    ["ED0A3F", "Red Ribbon"]
    ["ED7A1C", "Tango"]
    ["ED9121", "Carrot Orange"]
    ["ED989E", "Sea Pink"]
    ["EDB381", "Tacao"]
    ["EDC9AF", "Desert Sand"]
    ["EDCDAB", "Pancho"]
    ["EDDCB1", "Chamois"]
    ["EDEA99", "Primrose"]
    ["EDF5DD", "Frost"]
    ["EDF5F5", "Aqua Haze"]
    ["EDF6FF", "Zumthor"]
    ["EDF9F1", "Narvik"]
    ["EDFC84", "Honeysuckle"]
    ["EE82EE", "Lavender Magenta"]
    ["EEC1BE", "Beauty Bush"]
    ["EED794", "Chalky"]
    ["EED9C4", "Almond"]
    ["EEDC82", "Flax"]
    ["EEDEDA", "Bizarre"]
    ["EEE3AD", "Double Colonial White"]
    ["EEEEE8", "Cararra"]
    ["EEEF78", "Manz"]
    ["EEF0C8", "Tahuna Sands"]
    ["EEF0F3", "Athens Gray"]
    ["EEF3C3", "Tusk"]
    ["EEF4DE", "Loafer"]
    ["EEF6F7", "Catskill White"]
    ["EEFDFF", "Twilight Blue"]
    ["EEFF9A", "Jonquil"]
    ["EEFFE2", "Rice Flower"]
    ["EF863F", "Jaffa"]
    ["EFEFEF", "Gallery"]
    ["EFF2F3", "Porcelain"]
    ["F091A9", "Mauvelous"]
    ["F0D52D", "Golden Dream"]
    ["F0DB7D", "Golden Sand"]
    ["F0DC82", "Buff"]
    ["F0E2EC", "Prim"]
    ["F0E68C", "Khaki"]
    ["F0EEFD", "Selago"]
    ["F0EEFF", "Titan White"]
    ["F0F8FF", "Alice Blue"]
    ["F0FCEA", "Feta"]
    ["F18200", "Gold Drop"]
    ["F19BAB", "Wewak"]
    ["F1E788", "Sahara Sand"]
    ["F1E9D2", "Parchment"]
    ["F1E9FF", "Blue Chalk"]
    ["F1EEC1", "Mint Julep"]
    ["F1F1F1", "Seashell"]
    ["F1F7F2", "Saltpan"]
    ["F1FFAD", "Tidal"]
    ["F1FFC8", "Chiffon"]
    ["F2552A", "Flamingo"]
    ["F28500", "Tangerine"]
    ["F2C3B2", "Mandys Pink"]
    ["F2F2F2", "Concrete"]
    ["F2FAFA", "Black Squeeze"]
    ["F34723", "Pomegranate"]
    ["F3AD16", "Buttercup"]
    ["F3D69D", "New Orleans"]
    ["F3D9DF", "Vanilla Ice"]
    ["F3E7BB", "Sidecar"]
    ["F3E9E5", "Dawn Pink"]
    ["F3EDCF", "Wheatfield"]
    ["F3FB62", "Canary"]
    ["F3FBD4", "Orinoco"]
    ["F3FFD8", "Carla"]
    ["F400A1", "Hollywood Cerise"]
    ["F4A460", "Sandy brown"]
    ["F4C430", "Saffron"]
    ["F4D81C", "Ripe Lemon"]
    ["F4EBD3", "Janna"]
    ["F4F2EE", "Pampas"]
    ["F4F4F4", "Wild Sand"]
    ["F4F8FF", "Zircon"]
    ["F57584", "Froly"]
    ["F5C85C", "Cream Can"]
    ["F5C999", "Manhattan"]
    ["F5D5A0", "Maize"]
    ["F5DEB3", "Wheat"]
    ["F5E7A2", "Sandwisp"]
    ["F5E7E2", "Pot Pourri"]
    ["F5E9D3", "Albescent White"]
    ["F5EDEF", "Soft Peach"]
    ["F5F3E5", "Ecru White"]
    ["F5F5DC", "Beige"]
    ["F5FB3D", "Golden Fizz"]
    ["F5FFBE", "Australian Mint"]
    ["F64A8A", "French Rose"]
    ["F653A6", "Brilliant Rose"]
    ["F6A4C9", "Illusion"]
    ["F6F0E6", "Merino"]
    ["F6F7F7", "Black Haze"]
    ["F6FFDC", "Spring Sun"]
    ["F7468A", "Violet Red"]
    ["F77703", "Chilean Fire"]
    ["F77FBE", "Persian Pink"]
    ["F7B668", "Rajah"]
    ["F7C8DA", "Azalea"]
    ["F7DBE6", "We Peep"]
    ["F7F2E1", "Quarter Spanish White"]
    ["F7F5FA", "Whisper"]
    ["F7FAF7", "Snow Drift"]
    ["F8B853", "Casablanca"]
    ["F8C3DF", "Chantilly"]
    ["F8D9E9", "Cherub"]
    ["F8DB9D", "Marzipan"]
    ["F8DD5C", "Energy Yellow"]
    ["F8E4BF", "Givry"]
    ["F8F0E8", "White Linen"]
    ["F8F4FF", "Magnolia"]
    ["F8F6F1", "Spring Wood"]
    ["F8F7DC", "Coconut Cream"]
    ["F8F7FC", "White Lilac"]
    ["F8F8F7", "Desert Storm"]
    ["F8F99C", "Texas"]
    ["F8FACD", "Corn Field"]
    ["F8FDD3", "Mimosa"]
    ["F95A61", "Carnation"]
    ["F9BF58", "Saffron Mango"]
    ["F9E0ED", "Carousel Pink"]
    ["F9E4BC", "Dairy Cream"]
    ["F9E663", "Portica"]
    ["F9E6F4", "Underage Pink"]
    ["F9EAF3", "Amour"]
    ["F9F8E4", "Rum Swizzle"]
    ["F9FF8B", "Dolly"]
    ["F9FFF6", "Sugar Cane"]
    ["FA7814", "Ecstasy"]
    ["FA9D5A", "Tan Hide"]
    ["FAD3A2", "Corvette"]
    ["FADFAD", "Peach Yellow"]
    ["FAE600", "Turbo"]
    ["FAEAB9", "Astra"]
    ["FAECCC", "Champagne"]
    ["FAF0E6", "Linen"]
    ["FAF3F0", "Fantasy"]
    ["FAF7D6", "Citrine White"]
    ["FAFAFA", "Alabaster"]
    ["FAFDE4", "Hint of Yellow"]
    ["FAFFA4", "Milan"]
    ["FB607F", "Brink Pink"]
    ["FB8989", "Geraldine"]
    ["FBA0E3", "Lavender Rose"]
    ["FBA129", "Sea Buckthorn"]
    ["FBAC13", "Sun"]
    ["FBAED2", "Lavender Pink"]
    ["FBB2A3", "Rose Bud"]
    ["FBBEDA", "Cupid"]
    ["FBCCE7", "Classic Rose"]
    ["FBCEB1", "Apricot Peach"]
    ["FBE7B2", "Banana Mania"]
    ["FBE870", "Marigold Yellow"]
    ["FBE96C", "Festival"]
    ["FBEA8C", "Sweet Corn"]
    ["FBEC5D", "Candy Corn"]
    ["FBF9F9", "Hint of Red"]
    ["FBFFBA", "Shalimar"]
    ["FC0FC0", "Shocking Pink"]
    ["FC80A5", "Tickle Me Pink"]
    ["FC9C1D", "Tree Poppy"]
    ["FCC01E", "Lightning Yellow"]
    ["FCD667", "Goldenrod"]
    ["FCD917", "Candlelight"]
    ["FCDA98", "Cherokee"]
    ["FCF4D0", "Double Pearl Lusta"]
    ["FCF4DC", "Pearl Lusta"]
    ["FCF8F7", "Vista White"]
    ["FCFBF3", "Bianca"]
    ["FCFEDA", "Moon Glow"]
    ["FCFFE7", "China Ivory"]
    ["FCFFF9", "Ceramic"]
    ["FD0E35", "Torch Red"]
    ["FD5B78", "Wild Watermelon"]
    ["FD7B33", "Crusta"]
    ["FD7C07", "Sorbus"]
    ["FD9FA2", "Sweet Pink"]
    ["FDD5B1", "Light Apricot"]
    ["FDD7E4", "Pig Pink"]
    ["FDE1DC", "Cinderella"]
    ["FDE295", "Golden Glow"]
    ["FDE910", "Lemon"]
    ["FDF5E6", "Old Lace"]
    ["FDF6D3", "Half Colonial White"]
    ["FDF7AD", "Drover"]
    ["FDFEB8", "Pale Prim"]
    ["FDFFD5", "Cumulus"]
    ["FE28A2", "Persian Rose"]
    ["FE4C40", "Sunset Orange"]
    ["FE6F5E", "Bittersweet"]
    ["FE9D04", "California"]
    ["FEA904", "Yellow Sea"]
    ["FEBAAD", "Melon"]
    ["FED33C", "Bright Sun"]
    ["FED85D", "Dandelion"]
    ["FEDB8D", "Salomie"]
    ["FEE5AC", "Cape Honey"]
    ["FEEBF3", "Remy"]
    ["FEEFCE", "Oasis"]
    ["FEF0EC", "Bridesmaid"]
    ["FEF2C7", "Beeswax"]
    ["FEF3D8", "Bleach White"]
    ["FEF4CC", "Pipi"]
    ["FEF4DB", "Half Spanish White"]
    ["FEF4F8", "Wisp Pink"]
    ["FEF5F1", "Provincial Pink"]
    ["FEF7DE", "Half Dutch White"]
    ["FEF8E2", "Solitaire"]
    ["FEF8FF", "White Pointer"]
    ["FEF9E3", "Off Yellow"]
    ["FEFCED", "Orange White"]
    ["FF0000", "Red"]
    ["FF007F", "Rose"]
    ["FF00CC", "Purple Pizzazz"]
    ["FF00FF", "Magenta / Fuchsia"]
    ["FF2400", "Scarlet"]
    ["FF3399", "Wild Strawberry"]
    ["FF33CC", "Razzle Dazzle Rose"]
    ["FF355E", "Radical Red"]
    ["FF3F34", "Red Orange"]
    ["FF4040", "Coral Red"]
    ["FF4D00", "Vermilion"]
    ["FF4F00", "International Orange"]
    ["FF6037", "Outrageous Orange"]
    ["FF6600", "Blaze Orange"]
    ["FF66FF", "Pink Flamingo"]
    ["FF681F", "Orange"]
    ["FF69B4", "Hot Pink"]
    ["FF6B53", "Persimmon"]
    ["FF6FFF", "Blush Pink"]
    ["FF7034", "Burning Orange"]
    ["FF7518", "Pumpkin"]
    ["FF7D07", "Flamenco"]
    ["FF7F00", "Flush Orange"]
    ["FF7F50", "Coral"]
    ["FF8C69", "Salmon"]
    ["FF9000", "Pizazz"]
    ["FF910F", "West Side"]
    ["FF91A4", "Pink Salmon"]
    ["FF9933", "Neon Carrot"]
    ["FF9966", "Atomic Tangerine"]
    ["FF9980", "Vivid Tangerine"]
    ["FF9E2C", "Sunshade"]
    ["FFA000", "Orange Peel"]
    ["FFA194", "Mona Lisa"]
    ["FFA500", "Web Orange"]
    ["FFA6C9", "Carnation Pink"]
    ["FFAB81", "Hit Pink"]
    ["FFAE42", "Yellow Orange"]
    ["FFB0AC", "Cornflower Lilac"]
    ["FFB1B3", "Sundown"]
    ["FFB31F", "My Sin"]
    ["FFB555", "Texas Rose"]
    ["FFB7D5", "Cotton Candy"]
    ["FFB97B", "Macaroni and Cheese"]
    ["FFBA00", "Selective Yellow"]
    ["FFBD5F", "Koromiko"]
    ["FFBF00", "Amber"]
    ["FFC0A8", "Wax Flower"]
    ["FFC0CB", "Pink"]
    ["FFC3C0", "Your Pink"]
    ["FFC901", "Supernova"]
    ["FFCBA4", "Flesh"]
    ["FFCC33", "Sunglow"]
    ["FFCC5C", "Golden Tainoi"]
    ["FFCC99", "Peach Orange"]
    ["FFCD8C", "Chardonnay"]
    ["FFD1DC", "Pastel Pink"]
    ["FFD2B7", "Romantic"]
    ["FFD38C", "Grandis"]
    ["FFD700", "Gold"]
    ["FFD800", "School bus Yellow"]
    ["FFD8D9", "Cosmos"]
    ["FFDB58", "Mustard"]
    ["FFDCD6", "Peach Schnapps"]
    ["FFDDAF", "Caramel"]
    ["FFDDCD", "Tuft Bush"]
    ["FFDDCF", "Watusi"]
    ["FFDDF4", "Pink Lace"]
    ["FFDEAD", "Navajo White"]
    ["FFDEB3", "Frangipani"]
    ["FFE1DF", "Pippin"]
    ["FFE1F2", "Pale Rose"]
    ["FFE2C5", "Negroni"]
    ["FFE5A0", "Cream Brulee"]
    ["FFE5B4", "Peach"]
    ["FFE6C7", "Tequila"]
    ["FFE772", "Kournikova"]
    ["FFEAC8", "Sandy Beach"]
    ["FFEAD4", "Karry"]
    ["FFEC13", "Broom"]
    ["FFEDBC", "Colonial White"]
    ["FFEED8", "Derby"]
    ["FFEFA1", "Vis Vis"]
    ["FFEFC1", "Egg White"]
    ["FFEFD5", "Papaya Whip"]
    ["FFEFEC", "Fair Pink"]
    ["FFF0DB", "Peach Cream"]
    ["FFF0F5", "Lavender blush"]
    ["FFF14F", "Gorse"]
    ["FFF1B5", "Buttermilk"]
    ["FFF1D8", "Pink Lady"]
    ["FFF1EE", "Forget Me Not"]
    ["FFF1F9", "Tutu"]
    ["FFF39D", "Picasso"]
    ["FFF3F1", "Chardon"]
    ["FFF46E", "Paris Daisy"]
    ["FFF4CE", "Barley White"]
    ["FFF4DD", "Egg Sour"]
    ["FFF4E0", "Sazerac"]
    ["FFF4E8", "Serenade"]
    ["FFF4F3", "Chablis"]
    ["FFF5EE", "Seashell Peach"]
    ["FFF5F3", "Sauvignon"]
    ["FFF6D4", "Milk Punch"]
    ["FFF6DF", "Varden"]
    ["FFF6F5", "Rose White"]
    ["FFF8D1", "Baja White"]
    ["FFF9E2", "Gin Fizz"]
    ["FFF9E6", "Early Dawn"]
    ["FFFACD", "Lemon Chiffon"]
    ["FFFAF4", "Bridal Heath"]
    ["FFFBDC", "Scotch Mist"]
    ["FFFBF9", "Soapstone"]
    ["FFFC99", "Witch Haze"]
    ["FFFCEA", "Buttery White"]
    ["FFFCEE", "Island Spice"]
    ["FFFDD0", "Cream"]
    ["FFFDE6", "Chilean Heath"]
    ["FFFDE8", "Travertine"]
    ["FFFDF3", "Orchid White"]
    ["FFFDF4", "Quarter Pearl Lusta"]
    ["FFFEE1", "Half and Half"]
    ["FFFEEC", "Apricot White"]
    ["FFFEF0", "Rice Cake"]
    ["FFFEF6", "Black White"]
    ["FFFEFD", "Romance"]
    ["FFFF00", "Yellow"]
    ["FFFF66", "Laser Lemon"]
    ["FFFF99", "Pale Canary"]
    ["FFFFB4", "Portafino"]
    ["FFFFF0", "Ivory"]
    ["FFFFFF", "White"]
    ["acc2d9", "cloudy blue"]
    ["56ae57", "dark pastel green"]
    ["b2996e", "dust"]
    ["a8ff04", "electric lime"]
    ["69d84f", "fresh green"]
    ["894585", "light eggplant"]
    ["70b23f", "nasty green"]
    ["d4ffff", "really light blue"]
    ["65ab7c", "tea"]
    ["952e8f", "warm purple"]
    ["fcfc81", "yellowish tan"]
    ["a5a391", "cement"]
    ["388004", "dark grass green"]
    ["4c9085", "dusty teal"]
    ["5e9b8a", "grey teal"]
    ["efb435", "macaroni and cheese"]
    ["d99b82", "pinkish tan"]
    ["0a5f38", "spruce"]
    ["0c06f7", "strong blue"]
    ["61de2a", "toxic green"]
    ["3778bf", "windows blue"]
    ["2242c7", "blue blue"]
    ["533cc6", "blue with a hint of purple"]
    ["9bb53c", "booger"]
    ["05ffa6", "bright sea green"]
    ["1f6357", "dark green blue"]
    ["017374", "deep turquoise"]
    ["0cb577", "green teal"]
    ["ff0789", "strong pink"]
    ["afa88b", "bland"]
    ["08787f", "deep aqua"]
    ["dd85d7", "lavender pink"]
    ["a6c875", "light moss green"]
    ["a7ffb5", "light seafoam green"]
    ["c2b709", "olive yellow"]
    ["e78ea5", "pig pink"]
    ["966ebd", "deep lilac"]
    ["ccad60", "desert"]
    ["ac86a8", "dusty lavender"]
    ["947e94", "purpley grey"]
    ["983fb2", "purply"]
    ["ff63e9", "candy pink"]
    ["b2fba5", "light pastel green"]
    ["63b365", "boring green"]
    ["8ee53f", "kiwi green"]
    ["b7e1a1", "light grey green"]
    ["ff6f52", "orange pink"]
    ["bdf8a3", "tea green"]
    ["d3b683", "very light brown"]
    ["fffcc4", "egg shell"]
    ["430541", "eggplant purple"]
    ["ffb2d0", "powder pink"]
    ["997570", "reddish grey"]
    ["ad900d", "baby shit brown"]
    ["c48efd", "liliac"]
    ["507b9c", "stormy blue"]
    ["7d7103", "ugly brown"]
    ["fffd78", "custard"]
    ["da467d", "darkish pink"]
    ["410200", "deep brown"]
    ["c9d179", "greenish beige"]
    ["fffa86", "manilla"]
    ["5684ae", "off blue"]
    ["6b7c85", "battleship grey"]
    ["6f6c0a", "browny green"]
    ["7e4071", "bruise"]
    ["009337", "kelley green"]
    ["d0e429", "sickly yellow"]
    ["fff917", "sunny yellow"]
    ["1d5dec", "azul"]
    ["054907", "darkgreen"]
    ["b5ce08", "green/yellow"]
    ["8fb67b", "lichen"]
    ["c8ffb0", "light light green"]
    ["fdde6c", "pale gold"]
    ["ffdf22", "sun yellow"]
    ["a9be70", "tan green"]
    ["6832e3", "burple"]
    ["fdb147", "butterscotch"]
    ["c7ac7d", "toupe"]
    ["fff39a", "dark cream"]
    ["850e04", "indian red"]
    ["efc0fe", "light lavendar"]
    ["40fd14", "poison green"]
    ["b6c406", "baby puke green"]
    ["9dff00", "bright yellow green"]
    ["3c4142", "charcoal grey"]
    ["f2ab15", "squash"]
    ["ac4f06", "cinnamon"]
    ["c4fe82", "light pea green"]
    ["2cfa1f", "radioactive green"]
    ["9a6200", "raw sienna"]
    ["ca9bf7", "baby purple"]
    ["875f42", "cocoa"]
    ["3a2efe", "light royal blue"]
    ["fd8d49", "orangeish"]
    ["8b3103", "rust brown"]
    ["cba560", "sand brown"]
    ["698339", "swamp"]
    ["0cdc73", "tealish green"]
    ["b75203", "burnt siena"]
    ["7f8f4e", "camo"]
    ["26538d", "dusk blue"]
    ["63a950", "fern"]
    ["c87f89", "old rose"]
    ["b1fc99", "pale light green"]
    ["ff9a8a", "peachy pink"]
    ["f6688e", "rosy pink"]
    ["76fda8", "light bluish green"]
    ["53fe5c", "light bright green"]
    ["4efd54", "light neon green"]
    ["a0febf", "light seafoam"]
    ["7bf2da", "tiffany blue"]
    ["bcf5a6", "washed out green"]
    ["ca6b02", "browny orange"]
    ["107ab0", "nice blue"]
    ["2138ab", "sapphire"]
    ["719f91", "greyish teal"]
    ["fdb915", "orangey yellow"]
    ["fefcaf", "parchment"]
    ["fcf679", "straw"]
    ["1d0200", "very dark brown"]
    ["cb6843", "terracota"]
    ["31668a", "ugly blue"]
    ["247afd", "clear blue"]
    ["ffffb6", "creme"]
    ["90fda9", "foam green"]
    ["86a17d", "grey/green"]
    ["fddc5c", "light gold"]
    ["78d1b6", "seafoam blue"]
    ["13bbaf", "topaz"]
    ["fb5ffc", "violet pink"]
    ["20f986", "wintergreen"]
    ["ffe36e", "yellow tan"]
    ["9d0759", "dark fuchsia"]
    ["3a18b1", "indigo blue"]
    ["c2ff89", "light yellowish green"]
    ["d767ad", "pale magenta"]
    ["720058", "rich purple"]
    ["ffda03", "sunflower yellow"]
    ["01c08d", "green/blue"]
    ["ac7434", "leather"]
    ["014600", "racing green"]
    ["9900fa", "vivid purple"]
    ["02066f", "dark royal blue"]
    ["8e7618", "hazel"]
    ["d1768f", "muted pink"]
    ["96b403", "booger green"]
    ["fdff63", "canary"]
    ["95a3a6", "cool grey"]
    ["7f684e", "dark taupe"]
    ["751973", "darkish purple"]
    ["089404", "true green"]
    ["ff6163", "coral pink"]
    ["598556", "dark sage"]
    ["214761", "dark slate blue"]
    ["3c73a8", "flat blue"]
    ["ba9e88", "mushroom"]
    ["021bf9", "rich blue"]
    ["734a65", "dirty purple"]
    ["23c48b", "greenblue"]
    ["8fae22", "icky green"]
    ["e6f2a2", "light khaki"]
    ["4b57db", "warm blue"]
    ["d90166", "dark hot pink"]
    ["015482", "deep sea blue"]
    ["9d0216", "carmine"]
    ["728f02", "dark yellow green"]
    ["ffe5ad", "pale peach"]
    ["4e0550", "plum purple"]
    ["f9bc08", "golden rod"]
    ["ff073a", "neon red"]
    ["c77986", "old pink"]
    ["d6fffe", "very pale blue"]
    ["fe4b03", "blood orange"]
    ["fd5956", "grapefruit"]
    ["fce166", "sand yellow"]
    ["b2713d", "clay brown"]
    ["1f3b4d", "dark blue grey"]
    ["699d4c", "flat green"]
    ["56fca2", "light green blue"]
    ["fb5581", "warm pink"]
    ["3e82fc", "dodger blue"]
    ["a0bf16", "gross green"]
    ["d6fffa", "ice"]
    ["4f738e", "metallic blue"]
    ["ffb19a", "pale salmon"]
    ["5c8b15", "sap green"]
    ["54ac68", "algae"]
    ["89a0b0", "bluey grey"]
    ["7ea07a", "greeny grey"]
    ["1bfc06", "highlighter green"]
    ["cafffb", "light light blue"]
    ["b6ffbb", "light mint"]
    ["a75e09", "raw umber"]
    ["152eff", "vivid blue"]
    ["8d5eb7", "deep lavender"]
    ["5f9e8f", "dull teal"]
    ["63f7b4", "light greenish blue"]
    ["606602", "mud green"]
    ["fc86aa", "pinky"]
    ["8c0034", "red wine"]
    ["758000", "shit green"]
    ["ab7e4c", "tan brown"]
    ["030764", "darkblue"]
    ["fe86a4", "rosa"]
    ["d5174e", "lipstick"]
    ["fed0fc", "pale mauve"]
    ["680018", "claret"]
    ["fedf08", "dandelion"]
    ["fe420f", "orangered"]
    ["6f7c00", "poop green"]
    ["ca0147", "ruby"]
    ["1b2431", "dark"]
    ["00fbb0", "greenish turquoise"]
    ["db5856", "pastel red"]
    ["ddd618", "piss yellow"]
    ["41fdfe", "bright cyan"]
    ["cf524e", "dark coral"]
    ["21c36f", "algae green"]
    ["a90308", "darkish red"]
    ["6e1005", "reddy brown"]
    ["fe828c", "blush pink"]
    ["4b6113", "camouflage green"]
    ["4da409", "lawn green"]
    ["beae8a", "putty"]
    ["0339f8", "vibrant blue"]
    ["a88f59", "dark sand"]
    ["5d21d0", "purple/blue"]
    ["feb209", "saffron"]
    ["4e518b", "twilight"]
    ["964e02", "warm brown"]
    ["85a3b2", "bluegrey"]
    ["ff69af", "bubble gum pink"]
    ["c3fbf4", "duck egg blue"]
    ["2afeb7", "greenish cyan"]
    ["005f6a", "petrol"]
    ["0c1793", "royal"]
    ["ffff81", "butter"]
    ["f0833a", "dusty orange"]
    ["f1f33f", "off yellow"]
    ["b1d27b", "pale olive green"]
    ["fc824a", "orangish"]
    ["71aa34", "leaf"]
    ["b7c9e2", "light blue grey"]
    ["4b0101", "dried blood"]
    ["a552e6", "lightish purple"]
    ["af2f0d", "rusty red"]
    ["8b88f8", "lavender blue"]
    ["9af764", "light grass green"]
    ["a6fbb2", "light mint green"]
    ["ffc512", "sunflower"]
    ["750851", "velvet"]
    ["c14a09", "brick orange"]
    ["fe2f4a", "lightish red"]
    ["0203e2", "pure blue"]
    ["0a437a", "twilight blue"]
    ["a50055", "violet red"]
    ["ae8b0c", "yellowy brown"]
    ["fd798f", "carnation"]
    ["bfac05", "muddy yellow"]
    ["3eaf76", "dark seafoam green"]
    ["c74767", "deep rose"]
    ["b9484e", "dusty red"]
    ["647d8e", "grey/blue"]
    ["bffe28", "lemon lime"]
    ["d725de", "purple/pink"]
    ["b29705", "brown yellow"]
    ["673a3f", "purple brown"]
    ["a87dc2", "wisteria"]
    ["fafe4b", "banana yellow"]
    ["c0022f", "lipstick red"]
    ["0e87cc", "water blue"]
    ["8d8468", "brown grey"]
    ["ad03de", "vibrant purple"]
    ["8cff9e", "baby green"]
    ["94ac02", "barf green"]
    ["c4fff7", "eggshell blue"]
    ["fdee73", "sandy yellow"]
    ["33b864", "cool green"]
    ["fff9d0", "pale"]
    ["758da3", "blue/grey"]
    ["f504c9", "hot magenta"]
    ["77a1b5", "greyblue"]
    ["8756e4", "purpley"]
    ["889717", "baby shit green"]
    ["c27e79", "brownish pink"]
    ["017371", "dark aquamarine"]
    ["9f8303", "diarrhea"]
    ["f7d560", "light mustard"]
    ["bdf6fe", "pale sky blue"]
    ["75b84f", "turtle green"]
    ["9cbb04", "bright olive"]
    ["29465b", "dark grey blue"]
    ["696006", "greeny brown"]
    ["adf802", "lemon green"]
    ["c1c6fc", "light periwinkle"]
    ["35ad6b", "seaweed green"]
    ["fffd37", "sunshine yellow"]
    ["a442a0", "ugly purple"]
    ["f36196", "medium pink"]
    ["947706", "puke brown"]
    ["fff4f2", "very light pink"]
    ["1e9167", "viridian"]
    ["b5c306", "bile"]
    ["feff7f", "faded yellow"]
    ["cffdbc", "very pale green"]
    ["0add08", "vibrant green"]
    ["87fd05", "bright lime"]
    ["1ef876", "spearmint"]
    ["7bfdc7", "light aquamarine"]
    ["bcecac", "light sage"]
    ["bbf90f", "yellowgreen"]
    ["ab9004", "baby poo"]
    ["1fb57a", "dark seafoam"]
    ["00555a", "deep teal"]
    ["a484ac", "heather"]
    ["c45508", "rust orange"]
    ["3f829d", "dirty blue"]
    ["548d44", "fern green"]
    ["c95efb", "bright lilac"]
    ["3ae57f", "weird green"]
    ["016795", "peacock blue"]
    ["87a922", "avocado green"]
    ["f0944d", "faded orange"]
    ["5d1451", "grape purple"]
    ["25ff29", "hot green"]
    ["d0fe1d", "lime yellow"]
    ["ffa62b", "mango"]
    ["01b44c", "shamrock"]
    ["ff6cb5", "bubblegum"]
    ["6b4247", "purplish brown"]
    ["c7c10c", "vomit yellow"]
    ["b7fffa", "pale cyan"]
    ["aeff6e", "key lime"]
    ["ec2d01", "tomato red"]
    ["76ff7b", "lightgreen"]
    ["730039", "merlot"]
    ["040348", "night blue"]
    ["df4ec8", "purpleish pink"]
    ["6ecb3c", "apple"]
    ["8f9805", "baby poop green"]
    ["5edc1f", "green apple"]
    ["d94ff5", "heliotrope"]
    ["c8fd3d", "yellow/green"]
    ["070d0d", "almost black"]
    ["4984b8", "cool blue"]
    ["51b73b", "leafy green"]
    ["ac7e04", "mustard brown"]
    ["4e5481", "dusk"]
    ["876e4b", "dull brown"]
    ["58bc08", "frog green"]
    ["2fef10", "vivid green"]
    ["2dfe54", "bright light green"]
    ["0aff02", "fluro green"]
    ["9cef43", "kiwi"]
    ["18d17b", "seaweed"]
    ["35530a", "navy green"]
    ["1805db", "ultramarine blue"]
    ["6258c4", "iris"]
    ["ff964f", "pastel orange"]
    ["ffab0f", "yellowish orange"]
    ["8f8ce7", "perrywinkle"]
    ["24bca8", "tealish"]
    ["3f012c", "dark plum"]
    ["cbf85f", "pear"]
    ["ff724c", "pinkish orange"]
    ["280137", "midnight purple"]
    ["b36ff6", "light urple"]
    ["48c072", "dark mint"]
    ["bccb7a", "greenish tan"]
    ["a8415b", "light burgundy"]
    ["06b1c4", "turquoise blue"]
    ["cd7584", "ugly pink"]
    ["f1da7a", "sandy"]
    ["ff0490", "electric pink"]
    ["805b87", "muted purple"]
    ["50a747", "mid green"]
    ["a8a495", "greyish"]
    ["cfff04", "neon yellow"]
    ["ffff7e", "banana"]
    ["ff7fa7", "carnation pink"]
    ["ef4026", "tomato"]
    ["3c9992", "sea"]
    ["886806", "muddy brown"]
    ["04f489", "turquoise green"]
    ["fef69e", "buff"]
    ["cfaf7b", "fawn"]
    ["3b719f", "muted blue"]
    ["fdc1c5", "pale rose"]
    ["20c073", "dark mint green"]
    ["9b5fc0", "amethyst"]
    ["0f9b8e", "blue/green"]
    ["742802", "chestnut"]
    ["9db92c", "sick green"]
    ["a4bf20", "pea"]
    ["cd5909", "rusty orange"]
    ["ada587", "stone"]
    ["be013c", "rose red"]
    ["b8ffeb", "pale aqua"]
    ["dc4d01", "deep orange"]
    ["a2653e", "earth"]
    ["638b27", "mossy green"]
    ["419c03", "grassy green"]
    ["b1ff65", "pale lime green"]
    ["9dbcd4", "light grey blue"]
    ["fdfdfe", "pale grey"]
    ["77ab56", "asparagus"]
    ["464196", "blueberry"]
    ["990147", "purple red"]
    ["befd73", "pale lime"]
    ["32bf84", "greenish teal"]
    ["af6f09", "caramel"]
    ["a0025c", "deep magenta"]
    ["ffd8b1", "light peach"]
    ["7f4e1e", "milk chocolate"]
    ["bf9b0c", "ocher"]
    ["6ba353", "off green"]
    ["f075e6", "purply pink"]
    ["7bc8f6", "lightblue"]
    ["475f94", "dusky blue"]
    ["f5bf03", "golden"]
    ["fffeb6", "light beige"]
    ["fffd74", "butter yellow"]
    ["895b7b", "dusky purple"]
    ["436bad", "french blue"]
    ["d0c101", "ugly yellow"]
    ["c6f808", "greeny yellow"]
    ["f43605", "orangish red"]
    ["02c14d", "shamrock green"]
    ["b25f03", "orangish brown"]
    ["2a7e19", "tree green"]
    ["490648", "deep violet"]
    ["536267", "gunmetal"]
    ["5a06ef", "blue/purple"]
    ["cf0234", "cherry"]
    ["c4a661", "sandy brown"]
    ["978a84", "warm grey"]
    ["1f0954", "dark indigo"]
    ["03012d", "midnight"]
    ["2bb179", "bluey green"]
    ["c3909b", "grey pink"]
    ["a66fb5", "soft purple"]
    ["770001", "blood"]
    ["922b05", "brown red"]
    ["7d7f7c", "medium grey"]
    ["990f4b", "berry"]
    ["8f7303", "poo"]
    ["c83cb9", "purpley pink"]
    ["fea993", "light salmon"]
    ["acbb0d", "snot"]
    ["c071fe", "easter purple"]
    ["ccfd7f", "light yellow green"]
    ["00022e", "dark navy blue"]
    ["828344", "drab"]
    ["ffc5cb", "light rose"]
    ["ab1239", "rouge"]
    ["b0054b", "purplish red"]
    ["99cc04", "slime green"]
    ["937c00", "baby poop"]
    ["019529", "irish green"]
    ["ef1de7", "pink/purple"]
    ["000435", "dark navy"]
    ["42b395", "greeny blue"]
    ["9d5783", "light plum"]
    ["c8aca9", "pinkish grey"]
    ["c87606", "dirty orange"]
    ["aa2704", "rust red"]
    ["e4cbff", "pale lilac"]
    ["fa4224", "orangey red"]
    ["0804f9", "primary blue"]
    ["5cb200", "kermit green"]
    ["76424e", "brownish purple"]
    ["6c7a0e", "murky green"]
    ["fbdd7e", "wheat"]
    ["2a0134", "very dark purple"]
    ["044a05", "bottle green"]
    ["fd4659", "watermelon"]
    ["0d75f8", "deep sky blue"]
    ["fe0002", "fire engine red"]
    ["cb9d06", "yellow ochre"]
    ["fb7d07", "pumpkin orange"]
    ["b9cc81", "pale olive"]
    ["edc8ff", "light lilac"]
    ["61e160", "lightish green"]
    ["8ab8fe", "carolina blue"]
    ["920a4e", "mulberry"]
    ["fe02a2", "shocking pink"]
    ["9a3001", "auburn"]
    ["65fe08", "bright lime green"]
    ["befdb7", "celadon"]
    ["b17261", "pinkish brown"]
    ["885f01", "poo brown"]
    ["02ccfe", "bright sky blue"]
    ["c1fd95", "celery"]
    ["836539", "dirt brown"]
    ["fb2943", "strawberry"]
    ["84b701", "dark lime"]
    ["b66325", "copper"]
    ["7f5112", "medium brown"]
    ["5fa052", "muted green"]
    ["6dedfd", "robin's egg"]
    ["0bf9ea", "bright aqua"]
    ["c760ff", "bright lavender"]
    ["ffffcb", "ivory"]
    ["f6cefc", "very light purple"]
    ["155084", "light navy"]
    ["f5054f", "pink red"]
    ["645403", "olive brown"]
    ["7a5901", "poop brown"]
    ["a8b504", "mustard green"]
    ["3d9973", "ocean green"]
    ["000133", "very dark blue"]
    ["76a973", "dusty green"]
    ["2e5a88", "light navy blue"]
    ["0bf77d", "minty green"]
    ["bd6c48", "adobe"]
    ["ac1db8", "barney"]
    ["2baf6a", "jade green"]
    ["26f7fd", "bright light blue"]
    ["aefd6c", "light lime"]
    ["9b8f55", "dark khaki"]
    ["ffad01", "orange yellow"]
    ["c69c04", "ocre"]
    ["f4d054", "maize"]
    ["de9dac", "faded pink"]
    ["05480d", "british racing green"]
    ["c9ae74", "sandstone"]
    ["60460f", "mud brown"]
    ["98f6b0", "light sea green"]
    ["8af1fe", "robin egg blue"]
    ["2ee8bb", "aqua marine"]
    ["11875d", "dark sea green"]
    ["fdb0c0", "soft pink"]
    ["b16002", "orangey brown"]
    ["f7022a", "cherry red"]
    ["d5ab09", "burnt yellow"]
    ["86775f", "brownish grey"]
    ["c69f59", "camel"]
    ["7a687f", "purplish grey"]
    ["042e60", "marine"]
    ["c88d94", "greyish pink"]
    ["a5fbd5", "pale turquoise"]
    ["fffe71", "pastel yellow"]
    ["6241c7", "bluey purple"]
    ["fffe40", "canary yellow"]
    ["d3494e", "faded red"]
    ["985e2b", "sepia"]
    ["a6814c", "coffee"]
    ["ff08e8", "bright magenta"]
    ["9d7651", "mocha"]
    ["feffca", "ecru"]
    ["98568d", "purpleish"]
    ["9e003a", "cranberry"]
    ["287c37", "darkish green"]
    ["b96902", "brown orange"]
    ["ba6873", "dusky rose"]
    ["ff7855", "melon"]
    ["94b21c", "sickly green"]
    ["c5c9c7", "silver"]
    ["661aee", "purply blue"]
    ["6140ef", "purpleish blue"]
    ["9be5aa", "hospital green"]
    ["7b5804", "shit brown"]
    ["276ab3", "mid blue"]
    ["feb308", "amber"]
    ["8cfd7e", "easter green"]
    ["6488ea", "soft blue"]
    ["056eee", "cerulean blue"]
    ["b27a01", "golden brown"]
    ["0ffef9", "bright turquoise"]
    ["fa2a55", "red pink"]
    ["820747", "red purple"]
    ["7a6a4f", "greyish brown"]
    ["f4320c", "vermillion"]
    ["a13905", "russet"]
    ["6f828a", "steel grey"]
    ["a55af4", "lighter purple"]
    ["ad0afd", "bright violet"]
    ["004577", "prussian blue"]
    ["658d6d", "slate green"]
    ["ca7b80", "dirty pink"]
    ["005249", "dark blue green"]
    ["2b5d34", "pine"]
    ["bff128", "yellowy green"]
    ["b59410", "dark gold"]
    ["2976bb", "bluish"]
    ["014182", "darkish blue"]
    ["bb3f3f", "dull red"]
    ["fc2647", "pinky red"]
    ["a87900", "bronze"]
    ["82cbb2", "pale teal"]
    ["667c3e", "military green"]
    ["fe46a5", "barbie pink"]
    ["fe83cc", "bubblegum pink"]
    ["94a617", "pea soup green"]
    ["a88905", "dark mustard"]
    ["7f5f00", "shit"]
    ["9e43a2", "medium purple"]
    ["062e03", "very dark green"]
    ["8a6e45", "dirt"]
    ["cc7a8b", "dusky pink"]
    ["9e0168", "red violet"]
    ["fdff38", "lemon yellow"]
    ["c0fa8b", "pistachio"]
    ["eedc5b", "dull yellow"]
    ["7ebd01", "dark lime green"]
    ["3b5b92", "denim blue"]
    ["01889f", "teal blue"]
    ["3d7afd", "lightish blue"]
    ["5f34e7", "purpley blue"]
    ["6d5acf", "light indigo"]
    ["748500", "swamp green"]
    ["706c11", "brown green"]
    ["3c0008", "dark maroon"]
    ["cb00f5", "hot purple"]
    ["002d04", "dark forest green"]
    ["658cbb", "faded blue"]
    ["749551", "drab green"]
    ["b9ff66", "light lime green"]
    ["9dc100", "snot green"]
    ["faee66", "yellowish"]
    ["7efbb3", "light blue green"]
    ["7b002c", "bordeaux"]
    ["c292a1", "light mauve"]
    ["017b92", "ocean"]
    ["fcc006", "marigold"]
    ["657432", "muddy green"]
    ["d8863b", "dull orange"]
    ["738595", "steel"]
    ["aa23ff", "electric purple"]
    ["08ff08", "fluorescent green"]
    ["9b7a01", "yellowish brown"]
    ["f29e8e", "blush"]
    ["6fc276", "soft green"]
    ["ff5b00", "bright orange"]
    ["fdff52", "lemon"]
    ["866f85", "purple grey"]
    ["8ffe09", "acid green"]
    ["eecffe", "pale lavender"]
    ["510ac9", "violet blue"]
    ["4f9153", "light forest green"]
    ["9f2305", "burnt red"]
    ["728639", "khaki green"]
    ["de0c62", "cerise"]
    ["916e99", "faded purple"]
    ["ffb16d", "apricot"]
    ["3c4d03", "dark olive green"]
    ["7f7053", "grey brown"]
    ["77926f", "green grey"]
    ["010fcc", "true blue"]
    ["ceaefa", "pale violet"]
    ["8f99fb", "periwinkle blue"]
    ["c6fcff", "light sky blue"]
    ["5539cc", "blurple"]
    ["544e03", "green brown"]
    ["017a79", "bluegreen"]
    ["01f9c6", "bright teal"]
    ["c9b003", "brownish yellow"]
    ["929901", "pea soup"]
    ["0b5509", "forest"]
    ["a00498", "barney purple"]
    ["2000b1", "ultramarine"]
    ["94568c", "purplish"]
    ["c2be0e", "puke yellow"]
    ["748b97", "bluish grey"]
    ["665fd1", "dark periwinkle"]
    ["9c6da5", "dark lilac"]
    ["c44240", "reddish"]
    ["a24857", "light maroon"]
    ["825f87", "dusty purple"]
    ["c9643b", "terra cotta"]
    ["90b134", "avocado"]
    ["01386a", "marine blue"]
    ["25a36f", "teal green"]
    ["59656d", "slate grey"]
    ["75fd63", "lighter green"]
    ["21fc0d", "electric green"]
    ["5a86ad", "dusty blue"]
    ["fec615", "golden yellow"]
    ["fffd01", "bright yellow"]
    ["dfc5fe", "light lavender"]
    ["b26400", "umber"]
    ["7f5e00", "poop"]
    ["de7e5d", "dark peach"]
    ["048243", "jungle green"]
    ["ffffd4", "eggshell"]
    ["3b638c", "denim"]
    ["b79400", "yellow brown"]
    ["84597e", "dull purple"]
    ["411900", "chocolate brown"]
    ["7b0323", "wine red"]
    ["04d9ff", "neon blue"]
    ["667e2c", "dirty green"]
    ["fbeeac", "light tan"]
    ["d7fffe", "ice blue"]
    ["4e7496", "cadet blue"]
    ["874c62", "dark mauve"]
    ["d5ffff", "very light blue"]
    ["826d8c", "grey purple"]
    ["ffbacd", "pastel pink"]
    ["d1ffbd", "very light green"]
    ["448ee4", "dark sky blue"]
    ["05472a", "evergreen"]
    ["d5869d", "dull pink"]
    ["3d0734", "aubergine"]
    ["4a0100", "mahogany"]
    ["f8481c", "reddish orange"]
    ["02590f", "deep green"]
    ["89a203", "vomit green"]
    ["e03fd8", "purple pink"]
    ["d58a94", "dusty pink"]
    ["7bb274", "faded green"]
    ["526525", "camo green"]
    ["c94cbe", "pinky purple"]
    ["db4bda", "pink purple"]
    ["9e3623", "brownish red"]
    ["b5485d", "dark rose"]
    ["735c12", "mud"]
    ["9c6d57", "brownish"]
    ["028f1e", "emerald green"]
    ["b1916e", "pale brown"]
    ["49759c", "dull blue"]
    ["a0450e", "burnt umber"]
    ["39ad48", "medium green"]
    ["b66a50", "clay"]
    ["8cffdb", "light aqua"]
    ["a4be5c", "light olive green"]
    ["cb7723", "brownish orange"]
    ["05696b", "dark aqua"]
    ["ce5dae", "purplish pink"]
    ["c85a53", "dark salmon"]
    ["96ae8d", "greenish grey"]
    ["1fa774", "jade"]
    ["7a9703", "ugly green"]
    ["ac9362", "dark beige"]
    ["01a049", "emerald"]
    ["d9544d", "pale red"]
    ["fa5ff7", "light magenta"]
    ["82cafc", "sky"]
    ["acfffc", "light cyan"]
    ["fcb001", "yellow orange"]
    ["910951", "reddish purple"]
    ["fe2c54", "reddish pink"]
    ["c875c4", "orchid"]
    ["cdc50a", "dirty yellow"]
    ["fd411e", "orange red"]
    ["9a0200", "deep red"]
    ["be6400", "orange brown"]
    ["030aa7", "cobalt blue"]
    ["fe019a", "neon pink"]
    ["f7879a", "rose pink"]
    ["887191", "greyish purple"]
    ["b00149", "raspberry"]
    ["12e193", "aqua green"]
    ["fe7b7c", "salmon pink"]
    ["ff9408", "tangerine"]
    ["6a6e09", "brownish green"]
    ["8b2e16", "red brown"]
    ["696112", "greenish brown"]
    ["e17701", "pumpkin"]
    ["0a481e", "pine green"]
    ["343837", "charcoal"]
    ["ffb7ce", "baby pink"]
    ["6a79f7", "cornflower"]
    ["5d06e9", "blue violet"]
    ["3d1c02", "chocolate"]
    ["82a67d", "greyish green"]
    ["be0119", "scarlet"]
    ["c9ff27", "green yellow"]
    ["373e02", "dark olive"]
    ["a9561e", "sienna"]
    ["caa0ff", "pastel purple"]
    ["ca6641", "terracotta"]
    ["02d8e9", "aqua blue"]
    ["88b378", "sage green"]
    ["980002", "blood red"]
    ["cb0162", "deep pink"]
    ["5cac2d", "grass"]
    ["769958", "moss"]
    ["a2bffe", "pastel blue"]
    ["10a674", "bluish green"]
    ["06b48b", "green blue"]
    ["af884a", "dark tan"]
    ["0b8b87", "greenish blue"]
    ["ffa756", "pale orange"]
    ["a2a415", "vomit"]
    ["154406", "forrest green"]
    ["856798", "dark lavender"]
    ["34013f", "dark violet"]
    ["632de9", "purple blue"]
    ["0a888a", "dark cyan"]
    ["6f7632", "olive drab"]
    ["d46a7e", "pinkish"]
    ["1e488f", "cobalt"]
    ["bc13fe", "neon purple"]
    ["7ef4cc", "light turquoise"]
    ["76cd26", "apple green"]
    ["74a662", "dull green"]
    ["80013f", "wine"]
    ["b1d1fc", "powder blue"]
    ["ffffe4", "off white"]
    ["0652ff", "electric blue"]
    ["045c5a", "dark turquoise"]
    ["5729ce", "blue purple"]
    ["069af3", "azure"]
    ["ff000d", "bright red"]
    ["f10c45", "pinkish red"]
    ["5170d7", "cornflower blue"]
    ["acbf69", "light olive"]
    ["6c3461", "grape"]
    ["5e819d", "greyish blue"]
    ["601ef9", "purplish blue"]
    ["b0dd16", "yellowish green"]
    ["cdfd02", "greenish yellow"]
    ["2c6fbb", "medium blue"]
    ["c0737a", "dusty rose"]
    ["d6b4fc", "light violet"]
    ["020035", "midnight blue"]
    ["703be7", "bluish purple"]
    ["fd3c06", "red orange"]
    ["960056", "dark magenta"]
    ["40a368", "greenish"]
    ["03719c", "ocean blue"]
    ["fc5a50", "coral"]
    ["ffffc2", "cream"]
    ["7f2b0a", "reddish brown"]
    ["b04e0f", "burnt sienna"]
    ["a03623", "brick"]
    ["87ae73", "sage"]
    ["789b73", "grey green"]
    ["ffffff", "white"]
    ["98eff9", "robin's egg blue"]
    ["658b38", "moss green"]
    ["5a7d9a", "steel blue"]
    ["380835", "eggplant"]
    ["fffe7a", "light yellow"]
    ["5ca904", "leaf green"]
    ["d8dcd6", "light grey"]
    ["a5a502", "puke"]
    ["d648d7", "pinkish purple"]
    ["047495", "sea blue"]
    ["b790d4", "pale purple"]
    ["5b7c99", "slate blue"]
    ["607c8e", "blue grey"]
    ["0b4008", "hunter green"]
    ["ed0dd9", "fuchsia"]
    ["8c000f", "crimson"]
    ["ffff84", "pale yellow"]
    ["bf9005", "ochre"]
    ["d2bd0a", "mustard yellow"]
    ["ff474c", "light red"]
    ["0485d1", "cerulean"]
    ["ffcfdc", "pale pink"]
    ["040273", "deep blue"]
    ["a83c09", "rust"]
    ["90e4c1", "light teal"]
    ["516572", "slate"]
    ["fac205", "goldenrod"]
    ["d5b60a", "dark yellow"]
    ["363737", "dark grey"]
    ["4b5d16", "army green"]
    ["6b8ba4", "grey blue"]
    ["80f9ad", "seafoam"]
    ["a57e52", "puce"]
    ["a9f971", "spring green"]
    ["c65102", "dark orange"]
    ["e2ca76", "sand"]
    ["b0ff9d", "pastel green"]
    ["9ffeb0", "mint"]
    ["fdaa48", "light orange"]
    ["fe01b1", "bright pink"]
    ["c1f80a", "chartreuse"]
    ["36013f", "deep purple"]
    ["341c02", "dark brown"]
    ["b9a281", "taupe"]
    ["8eab12", "pea green"]
    ["9aae07", "puke green"]
    ["02ab2e", "kelly green"]
    ["7af9ab", "seafoam green"]
    ["137e6d", "blue green"]
    ["aaa662", "khaki"]
    ["610023", "burgundy"]
    ["014d4e", "dark teal"]
    ["8f1402", "brick red"]
    ["4b006e", "royal purple"]
    ["580f41", "plum"]
    ["8fff9f", "mint green"]
    ["dbb40c", "gold"]
    ["a2cffe", "baby blue"]
    ["c0fb2d", "yellow green"]
    ["be03fd", "bright purple"]
    ["840000", "dark red"]
    ["d0fefe", "pale blue"]
    ["3f9b0b", "grass green"]
    ["01153e", "navy"]
    ["04d8b2", "aquamarine"]
    ["c04e01", "burnt orange"]
    ["0cff0c", "neon green"]
    ["0165fc", "bright blue"]
    ["cf6275", "rose"]
    ["ffd1df", "light pink"]
    ["ceb301", "mustard"]
    ["380282", "indigo"]
    ["aaff32", "lime"]
    ["53fca1", "sea green"]
    ["8e82fe", "periwinkle"]
    ["cb416b", "dark pink"]
    ["677a04", "olive green"]
    ["ffb07c", "peach"]
    ["c7fdb5", "pale green"]
    ["ad8150", "light brown"]
    ["ff028d", "hot pink"]
    ["000000", "black"]
    ["cea2fd", "lilac"]
    ["001146", "navy blue"]
    ["0504aa", "royal blue"]
    ["e6daa6", "beige"]
    ["ff796c", "salmon"]
    ["6e750e", "olive"]
    ["650021", "maroon"]
    ["01ff07", "bright green"]
    ["35063e", "dark purple"]
    ["ae7181", "mauve"]
    ["06470c", "forest green"]
    ["13eac9", "aqua"]
    ["00ffff", "cyan"]
    ["d1b26f", "tan"]
    ["00035b", "dark blue"]
    ["c79fef", "lavender"]
    ["06c2ac", "turquoise"]
    ["033500", "dark green"]
    ["9a0eea", "violet"]
    ["bf77f6", "light purple"]
    ["89fe05", "lime green"]
    ["929591", "grey"]
    ["75bbfd", "sky blue"]
    ["ffff14", "yellow"]
    ["c20078", "magenta"]
    ["96f97b", "light green"]
    ["f97306", "orange"]
    ["029386", "teal"]
    ["95d0fc", "light blue"]
    ["e50000", "red"]
    ["653700", "brown"]
    ["ff81c0", "pink"]
    ["0343df", "blue"]
    ["15b01a", "green"]
    ["7e1e9c", "purple"]
    ["FF5E99", "paul irish pink"]
    ["00000000", "transparent"]
  ]

  names.each (element) ->
    lookup[normalizeKey(element[1])] = parseHex(element[0])

  ###*
  returns a random color.

  <code><pre>
  Color.random().toString()
  # => 'rgba(213, 144, 202, 1)'

  Color.random().toString()
  # => 'rgba(1, 211, 24, 1)'
  </pre></code>

  @name random
  @methodOf Color

  @returns {Color} A random color.
  ###
  Color.random = ->
    Color(rand(256), rand(256), rand(256))

  ###*
  Mix two colors. Behaves just like `#mixWith` except that you are passing two colors.

  <code><pre>
  red = Color(255, 0, 0)
  yellow = Color(255, 255, 0)

  # With no amount argument the colors are mixed evenly
  orange = Color.mix(red, yellow)

  orange.toString()
  # => 'rgba(255, 128, 0, 1)'

  # With an amount of 0.3 we are mixing the color 30% red and 70% yellow
  somethingCloseToOrange = Color.mix(red, yellow, 0.3)

  somethingCloseToOrange.toString()
  # => rgba(255, 179, 0, 1)
  </pre></code>

  @name mix
  @methodOf Color
  @see Color#mixWith
  @param {Color} color1 the first color to mix
  @param {Color} color2 the second color to mix
  @param {Number} amount the ratio to mix the colors

  @returns {Color} A new color that is the two colors mixed at the ratio defined by `amount`
  ###
  Color.mix = (color1, color2, amount) ->
    amount ||= 0.5

    newColors = [color1.r, color1.g, color1.b, color1.a].zip([color2.r, color2.g, color2.b, color2.a]).map (array) ->
      (array[0] * amount) + (array[1] * (1 - amount))

    return Color(newColors)

  (exports ? this)["Color"] = Color
)()

