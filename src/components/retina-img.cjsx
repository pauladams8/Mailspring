_ = require 'underscore'
React = require 'react'
{Utils} = require "nylas-exports"

StylesImpactedByZoom = [
  'top',
  'left',
  'right',
  'bottom',
  'paddingTop',
  'paddingLeft',
  'paddingRight',
  'paddingBottom',
  'marginTop',
  'marginBottom',
  'marginLeft',
  'marginRight'
]

# We don't want to call `getLoadSettings` for each and every RetinaImg
# instance because it's a fairly expensive operation. Since the
# resourcePath can't change once the app has booted, it's safe to set the
# constant at require-time
DEFAULT_RESOURCE_PATH = NylasEnv.getLoadSettings().resourcePath

Mode =
  ContentPreserve: 'original'
  ContentLight: 'light'
  ContentDark: 'dark'
  ContentIsMask: 'mask'

###
Public: RetinaImg wraps the DOM's standard `<img`> tag and implements a `UIImage` style
interface. Rather than specifying an image `src`, RetinaImg allows you to provide
an image name. Like UIImage on iOS, it automatically finds the best image for the current
display based on pixel density. Given `image.png`, on a Retina screen, it looks for
`image@2x.png`, `image.png`, `image@1x.png` in that order. It uses a lookup table and caches
image names, so images generally resolve immediately.

RetinaImg also introduces the concept of image `modes`. Specifying an image mode
is important for theming: it describes the content of your image, allowing theme
developers to properly adjust it. The four modes are described below:

- ContentPreserve: Your image contains color or should not be adjusted by any theme.

- ContentLight: Your image is a grayscale image with light colors, intended to be shown
  against a dark background. If a theme developer changes the background to be light, they
  can safely apply CSS filters to invert or darken this image. This mode adds the
  `content-light` CSS class to the image.

- ContentDark: Your image is a grayscale image with dark colors, intended to be shown
  against a light background. If a theme developer changes the background to be dark, they
  can safely apply CSS filters to invert or brighten this image. This mode adds the
  `content-dark` CSS class to the image.

- ContentIsMask: This image provides alpha information only, and color should
  be based on the `background-color` of the RetinaImg. This mode adds the
  `content-mask` CSS class to the image, and leverages `-webkit-mask-image`.

  Example: Icons displayed within buttons specify ContentIsMask, and their
  color is declared via CSS to be the same as the button text color. Changing
  `@text-color-subtle` in a theme changes both button text and button icons!

   ```css
   .btn-icon {
     color: @text-color-subtle;
     img.content-mask { background-color:@text-color-subtle; }
   }
   ```

Section: Component Kit
###
class RetinaImg extends React.Component
  @displayName: 'RetinaImg'
  @Mode: Mode

  ###
  Public: React `props` supported by RetinaImg:

   - `mode` (required) One of the RetinaImg.Mode constants. See above for details.
   - `name` (optional) A {String} image name to display.
   - `url` (optional) A {String} url of an image to display.
      May be an http, https, or `nylas://<packagename>/<path within package>` URL.
   - `fallback` (optional) A {String} image name to use when `name` cannot be found.
   - `selected` (optional) Appends "-selected" to the end of the image name when when true
   - `active` (optional) Appends "-active" to the end of the image name when when true
   - `style` (optional) An {Object} with additional styles to apply to the image.
   - `resourcePath` (options) Changes the default lookup location used to find the images.
  ###
  @propTypes:
    mode: React.PropTypes.string.isRequired
    name: React.PropTypes.string
    url: React.PropTypes.string
    className: React.PropTypes.string
    style: React.PropTypes.object
    fallback: React.PropTypes.string
    selected: React.PropTypes.bool
    active: React.PropTypes.bool
    resourcePath: React.PropTypes.string

  shouldComponentUpdate: (nextProps) =>
    not _.isEqual(@props, nextProps)

  render: =>
    path = @props.url ? @_pathFor(@props.name) ? @_pathFor(@props.fallback) ? ''
    pathIsRetina = path.indexOf('@2x') > 0
    className = @props.className ? ''

    style = @props.style ? {}
    style.WebkitUserDrag = 'none'
    style.zoom ?= if pathIsRetina then 0.5 else 1
    style.width = style.width / style.zoom if style.width
    style.height = style.height / style.zoom if style.height

    if @props.mode is Mode.ContentIsMask
      style.WebkitMaskImage = "url('#{path}')"
      style.WebkitMaskRepeat = "no-repeat"
      style.objectPosition = "10000px"
      className += " content-mask"
    else if @props.mode is Mode.ContentDark
      className += " content-dark"
    else if @props.mode is Mode.ContentLight
      className += " content-light"

    for key, val of style
      val = "#{val}"
      if key in StylesImpactedByZoom and val.indexOf('%') is -1
        style[key] = val.replace('px','') / style.zoom

    otherProps = _.omit(@props, _.keys(@constructor.propTypes))
    <img className={className} src={path} style={style} {...otherProps} />

  _pathFor: (name) =>
    return null unless name and _.isString(name)

    [basename, ext] = name.split('.')
    if @props.active is true
      name = "#{basename}-active.#{ext}"
    if @props.selected is true
      name = "#{basename}-selected.#{ext}"
    resourcePath = @props.resourcePath ? DEFAULT_RESOURCE_PATH
    Utils.imageNamed(resourcePath, name)


module.exports = RetinaImg
