require "doger"

Doger.configure do |config|
  config.default_colors = [
    [221,0,204],   # magenta
    [255,50,50],   # red
    [255,160,0],   # orange
    [250,250,50],  # yellow
    [0,255,0],     # green
    [0,255,255],   # cyan
    [25,150,150],  # aqua
    [50,50,255],   # blue
    [125,0,255],   # purple
    [255,255,255]  # white
  ]
  default_pointsizes = (18..25)
  config.image_quality = 90
end
