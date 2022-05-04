# WEB UTILITIES
//= require underscore
//= require canvas-toBlob
//= require dat.gui.min
//= require paper-core
//= require clipper
//= require decimal
//= require chroma.min
//= require paper2
//= require numeric.min
//= require semantic-ui
//= require semantic-ui/video
//= require utilities/ruler
//= require utilities/file_saver.min
//= require utilities/webcache
//= require jquery.mobile-events.min
//= require hammer
//= require hammer.min
//= require jquery.hammer
//= require hammer-time
//= require hammer-time.min

//= require touch-emulator
//= require tablesort

# DESIGN TOOL
//= require paper-design-tool
//= require ntc
//= require tool/collection
//= require tool/stitcher
//= require tool/stitcher/haws
//= require tool/stitcher/obstacle
//= require tool/stitcher/trace
//= require tool/stitcher/segment
//= require tool/stitcher/sketches
//= require tool/stitcher/canvas
//= require tool/stitcher/thread
//= require tool/stitcher/needle
//= require tool/stitcher/tool-embr
//= require tool/stitcher/tool-stitch
//= require tool/stitcher/tool-probe
//= require tool/stitcher/tool-make
//= require tool/stitcher/tool-heat
//= require tool/stitcher/sketches/chi_logo
//= require tool/stitcher/sketches/rainbow-fish
//= require tool/stitcher/sketches/characterization

//= require tool/material
//= require tool/hotkey-legend

@clone_vec_array = (arr) ->
  clone = []
  for i of arr
  	clone.push arr[i].clone()
  clone

@calcBilinearInterpolant = (x1, x, x2, y1, y, y2, Q11, Q21, Q12, Q22) ->

  ###*
  # (x1, y1) - coordinates of corner 1 - [Q11]
  # (x2, y1) - coordinates of corner 2 - [Q21]
  # (x1, y2) - coordinates of corner 3 - [Q12]
  # (x2, y2) - coordinates of corner 4 - [Q22]
  # 
  # (x, y)   - coordinates of interpolation
  # 
  # Q11      - corner 1
  # Q21      - corner 2
  # Q12      - corner 3
  # Q22      - corner 4
  ###
  ans1 = (x2 - x) * (y2 - y) / (x2 - x1) * (y2 - y1) * Q11
  ans2 = (x - x1) * (y2 - y) / (x2 - x1) * (y2 - y1) * Q21
  ans3 = (x2 - x) * (y - y1) / (x2 - x1) * (y2 - y1) * Q12
  ans4 = (x - x1) * (y - y1) / (x2 - x1) * (y2 - y1) * Q22
  ans1 + ans2 + ans3 + ans4