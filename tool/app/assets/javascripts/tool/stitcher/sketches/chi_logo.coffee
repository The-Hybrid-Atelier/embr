class stitcher.ChilogoSketch extends stitcher.SVGSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "CHILogo"
    super ops
  procedure: ()->
    url = "/designs/feather.svg"
    console.log "loading", url
    @addSVG
      url: url
      position: stitch.canvas.center()
    return
  onLoad: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    scope.design.scaling = new paper.Size(2, 2)
    groups = scope.design.getItems
      className: "Group"
      name: "flystitch"
    _.each groups, (f, i)-> 
      scope.flystitch(f, i)
      # scope.lcd(f)
    # groups = scope.design.getItems
    #   className: "Group"
    #   name: "serpentine"
    # _.each groups, (f, i)-> 
    #   scope.serpentine(f, i)
    #   scope.lcd(f)
  lcd: (f)->
    boundary = f.getItem
      name: "boundary"
    stitch.canvas.generate_heat_grid(boundary.bounds.expand(25), 100)
  serpentine: (f, idx)->
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    pts = this.plot_points_serpentine
      stem_density: 14 # number of times stitch crosses stem
      lock_stitch_length: 2 # at least 4
      pull_distance: 3 # at least 10
      v_acuteness: 10  
      boundary: boundary
      axis: axis
    thread = stitch.threadkeeper.knotAndBegin()
    # thread.passThrough()
    
    # this.up(thread, 100, false)
    # thread.passThrough()
    # console.log pts
    thread.passThrough()
    thread.stitch(pts[0][0].x, pts[0][0].y, false, false)
    thread.passThrough()
    _.each pts, (pt, idx)->
      if idx%2==0
        thread.stitch(pt[0].x, pt[0].y, false, false)
        thread.passThrough()
        thread.stitch(pt[1].x, pt[1].y, false, false)
        thread.passThrough()
      else
        thread.stitch(pt[1].x, pt[1].y, false, false)
        thread.passThrough()
        thread.stitch(pt[0].x, pt[0].y, false, false)
        thread.passThrough()
      
      # else
      #   thread.stitch(pt[1].x, pt[1].y, false, false)
      #   thread.stitch(pt[0].x, pt[0].y, false, false)
      
    #   thread.stitch(pt[2].x, pt[2].y, false, false)
    #   thread.stitch(pt[3].x, pt[3].y, false, false)
    #   thread.passThrough()
    #   thread.stitch(pt[4].x, pt[4].y, false, false)
    #   thread.passThrough()
    #   thread.stitch(pt[5].x, pt[5].y, false, false)
  prepare_guides: (ops)->
    boundary = ops.boundary
    boundary.set
      name: "boundary"
      strokeColor: "blue"
      strokeWidth: 1
      z_index: 0
      opacity: 0.5
      visible: ops.visible
    axis = ops.axis
    offsets = _.map axis.getIntersections(boundary), "offset"
    from = axis.getPointAt(_.min(offsets))
    to = axis.getPointAt(_.max(offsets))
    axis.remove()
    axis = new paper.Path.Line
      strokeColor: "yellow"
      strokeWidth: 1
      from: from
      to: to
      opacity: 0.5
      z_index: 0
      visible: ops.visible
    rtn = 
      axis: axis
      boundary: boundary
  flystitch: (f, idx)->
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = this.prepare_guides
      boundary: boundary
      axis: axis
      visible: true
    # if idx == 2
    pts = this.plot_points
      stem_density: 10 # number of times stitch crosses stem
      lock_stitch_length: 2 # at least 4
      pull_distance: 3 # at least 10
      v_acuteness: 40
      boundary: boundary
      axis: axis
    boundary.strokeColor = "blue"
    # else
    #   pts = this.plot_points
    #     stem_density: 16/3 # number of times stitch crosses stem
    #     lock_stitch_length: 2 # at least 4
    #     pull_distance: 3 # at least 10
    #     v_acuteness: 10 
    #     boundary: boundary
    #     axis: axis

    thread = stitch.threadkeeper.knotAndBegin()
    # thread.passThrough()
    pt = boundary.getPointAt(0)
    thread.stitch(pt.x, pt.y, false, false)
    # this.up(thread, 100, false)
    pt = axis.getPointAt(10)
    thread.passThrough()
    thread.stitch(pt.x, pt.y, false, false)
    # console.log pts
    _.each pts, (pt)->
      thread.passThrough()
      thread.stitch(pt[0].x, pt[0].y, false, false)
      thread.passThrough()
      thread.stitch(pt[0].x, pt[0].y, false, false)
      thread.stitch(pt[1].x, pt[1].y, false, false)
      thread.stitch(pt[2].x, pt[2].y, false, false)
      thread.stitch(pt[3].x, pt[3].y, false, false)
      thread.passThrough()
      thread.stitch(pt[4].x, pt[4].y, false, false)
      thread.passThrough()
      thread.stitch(pt[5].x, pt[5].y, false, false)
    # thread.pull_all_segments()
  plot_points_serpentine: (ops)->
    # ADD NEW TRACE
    boundary = ops.boundary
    boundary.set
      name: "boundary"
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: true
    axis = ops.axis
    axis.set
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: true

    
    step = axis.length/ops.stem_density
    offsets = _.range(step, axis.length, step)

    pts = _.map offsets, (offset, idx)->
      if offset+ops.v_acuteness+5 > axis.length
        return
      
      normalA = axis.getNormalAt(offset)
      normalA.length = 1000
      normalB = axis.getNormalAt(offset)
      normalB.length = -1000

      c = new paper.Path.Line
        name: "c"
        from: axis.getPointAt(offset).add(normalA)
        to: axis.getPointAt(offset).add(normalB)
        strokeColor: "blue"
        strokeWidth: 1
        visible: false
        z_index: 1
      ixts = c.getIntersections(boundary)
      c.segments = _.map ixts, "point"
      pts = _.map c.segments, "point"
        # pts.push(axis.getPointAt(offset+ops.v_acuteness - ops.lock_stitch_length))
        # pts.push(axis.getPointAt(offset+ops.v_acuteness + ops.lock_stitch_length))
        # c.add(axis.getPointAt(offset+ops.v_acuteness - ops.lock_stitch_length))
        # c.add(axis.getPointAt(offset+ops.v_acuteness + ops.lock_stitch_length))
      return pts
    pts = _.compact pts, pts
    
    return pts

  plot_points: (ops)->
    # ADD NEW TRACE
    boundary = ops.boundary
    boundary.set
      name: "boundary"
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: true
    axis = ops.axis
    axis.set
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: true

    
    step = axis.length/ops.stem_density
    offsets = _.range(step, axis.length, step)

    pts = _.map offsets, (offset, idx)->
      if offset+ops.v_acuteness+5 > axis.length
        return
      
      normalA = axis.getNormalAt(offset)
      normalA.length = 1000
      normalB = axis.getNormalAt(offset)
      normalB.length = -1000

      c = new paper.Path.Line
        name: "c"
        from: axis.getPointAt(offset).add(normalA)
        to: axis.getPointAt(offset).add(normalB)
        strokeColor: "blue"
        strokeWidth: 1
        visible: false
        z_index: 1
      ixts = c.getIntersections(boundary)
      c.segments = _.map ixts, "point"

      normalA = axis.getNormalAt(offset+ops.v_acuteness)
      normalB = axis.getNormalAt(offset+ops.v_acuteness)
      normalA.length = ops.pull_distance
      normalB.length = -ops.pull_distance
      midpoint = axis.getPointAt(offset+ops.v_acuteness)#.add(tangent)
      c.insert(1, midpoint.add(normalA))
      c.insert(2, midpoint.add(normalB))

      if not boundary.contains(midpoint)
        c.remove()
        return null
      else
        pts = _.map c.segments, "point"
        pts.push(axis.getPointAt(offset+ops.v_acuteness - ops.lock_stitch_length))
        pts.push(axis.getPointAt(offset+ops.v_acuteness + ops.lock_stitch_length))
        c.add(axis.getPointAt(offset+ops.v_acuteness - ops.lock_stitch_length))
        c.add(axis.getPointAt(offset+ops.v_acuteness + ops.lock_stitch_length))
        return pts
    pts = _.compact pts, pts
    
    return pts

    # console.log idx, axis, boundary