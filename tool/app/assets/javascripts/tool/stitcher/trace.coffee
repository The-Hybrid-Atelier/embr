class stitcher.Trace extends paper.Group
  @STROKE_PATH_SCALE: 1.5 #x100%
  @TRACE_PATH_DEFAULT_WIDTH: Ruler.mm2pts(0.5) #px
  @SIMULATION_STOP_THRESHOLD: 0.05 #px
  @CULL_AFTER_X_ITERATIONS: 1
  @LAYER_COLORS:
    "under": "#79B3E1"
    "over": "#F2663A"
    "stroke": "#333333"
  getColor: ()->
    if this.color
      return this.color
    else
      return stitcher.Trace.LAYER_COLORS["over"]
  constructor: (ops)->
    super ops

    _.extend this, this.ops
    this.name = "trace"

    this.recede_start = false
    this.recede_end = false
    this.z_index = if this.side == "over" then stitch.canvas.getTopCount(1) else stitch.canvas.getBottomCount(1)

    # console.log "TRACE", ops.side, this.z_index
    this.strokePath = new paper.Path
      parent: this
      strokeWidth: stitcher.Trace.STROKE_PATH_SCALE * stitcher.Trace.TRACE_PATH_DEFAULT_WIDTH
      strokeColor: stitcher.Trace.LAYER_COLORS["stroke"]
      strokeCap: "round"
      strokeJoin: "round"
      miterLimit: 5
    
    this.threadPath = new paper.Path
      parent: this
      strokeWidth: stitcher.Trace.TRACE_PATH_DEFAULT_WIDTH
      strokeColor: stitcher.Trace.LAYER_COLORS[this.side]
      strokeCap: "round"
      strokeJoin: "round"
      miterLimit: 5

    this.sideColor = stitcher.Trace.LAYER_COLORS[this.side]
    # Add previous trace as startpoint

    if this.prev and this.prev.name == "trace"
      this.strokePath.addSegment(this.prev.getWaypoint(-1))
      this.threadPath.addSegment(this.prev.getWaypoint(-1))
      
  
    this.render()

  animate: (time_bandwidth, time_offset)->
    time_bandwidth -= 100
    scope = this
    frame_rate = 30
    frames = time_bandwidth/frame_rate
    trace = new Trace
      side: this.side
      z_index: this.z_index
      prev: null
      next: null
    trace.colorize("yellow")
    offsets = _.range 0, this.length(), this.length()/frames # linear sampling
    p = _.range 0, 1, 1/frames
    offsets = _.map p, (t)-> return (t * t * t) * scope.length() # ease in cubic
    offsets = _.map p, (t)-> return if t<0.5 then (4*t*t*t * scope.length()) else (((t-1)*(2*t-2)*(2*t-2)+1) * scope.length())  # ease in cubic



    _.each offsets, (offset, idx, arr)->
      routine = ()->
        trace.addPt(scope.strokePath.getPointAt(offset))
      # step = time_bandwidth/arr.length
      _.delay routine, (frame_rate * idx) + time_offset
    cleanup = ()->
      trace.remove()
      scope.show()
    _.delay cleanup, time_bandwidth + time_offset + 100


  show: ()->
    this.visible = true
  hide: ()->
    this.visible = false

  getSegments: (segments)->
    return this.strokePath.segments
  setColor: (color)->
    this.color = color
  colorize: (color)->
    if color == "reset"
      if this.color
        this.strokePath.strokeColor = this.color
      else
        this.strokePath.strokeColor = stitcher.Trace.LAYER_COLORS["stroke"]
      
      this.threadPath.strokeColor = this.sideColor
    else
      this.threadPath.set 
        strokeColor: color
      color = new paper.Color(color).clone()
      color.brightness -= 0.4
      this.strokePath.set 
        strokeColor: color
  
  getObstacles: ()->
    scope = this
    traces = paper.project.getItems
      name: "trace"
      side: this.side
      overlapping: this.bounds
      z_index: (z)-> z > scope.z_index


    traces = _.filter traces, (t)-> 
      if t.id == scope.id
        return false
      else
        ixts = t.threadPath.getCrossings(scope.threadPath)
        ixts = _.filter ixts, (ixt)->
          return ixt.offset < t.threadPath.length - 1
        # if ixts.length > 0
        #   _.each ixts, (ixt)->
        #     console.log "IXT", t.id, t.threadPath.length, ixt.offset
        return ixts.length > 0

    hits = _.map traces, (t)-> 
      return t.threadPath

    return hits

  hits: ()->
    scope = this

    traces = paper.project.getItems
      name: "trace"
      side: this.side
      overlapping: this.bounds

    traces = _.filter traces, (t)-> 
      if t.id == scope.id
        return false
      else
        ixts = t.threadPath.getCrossings(scope.threadPath)
        return ixts.length > 0
    
    # _.each traces, (t)-> t.selected = true
    return traces
  addPt: (pt)->
    this.addSegment(pt)
  remove: ()->
    this.strokePath.remove()
    this.threadPath.remove()
  addSegment:(pt)->
    this.strokePath.addSegment(pt)
    this.threadPath.addSegment(pt)
  removeSegment: ()->
    this.strokePath.segments.pop()
    this.threadPath.segments.pop()
  addSegmentFront: (pt)->
    this.strokePath.insert(0, pt)
    this.threadPath.insert(0, pt)
  replaceSegments: (segments)->
    this.strokePath.removeSegments()
    this.strokePath.addSegments(segments)
    this.threadPath.removeSegments()
    this.threadPath.addSegments(segments)
  recede: (orientation)->
    if orientation == "start"
      this.recede_start = true
    else
      this.recede_end = true
    this.render()

  getWaypoint: (idx)->
    if idx == -1
      return this.threadPath.lastSegment
    if idx == 0
      return this.threadPath.firstSegment
  
  resample: (step=5)->
    scope = this
    pts = _.map _.range(0, this.threadPath.length, step), (offset)->
      scope.threadPath.getPointAt(offset)
    pts.push(scope.threadPath.lastSegment)
    this.replaceSegments(pts)
    scope.strokePath.firstSegment.fixed = true
    scope.threadPath.firstSegment.fixed = true
    scope.strokePath.lastSegment.fixed = true
    scope.threadPath.lastSegment.fixed = true
    this.resampled = true

  # Removes segments that are too close to each other (threshold) or those that are
  # along the same line (prev -> curr -> next). Angle threshold should be <10º
  cull: (threshold=4, angle_threshold=10)->
    # console.log "Culling at", threshold, angle_threshold, "º"
    prev_idx = 0
    okay_segments = _.map this.strokePath.segments, (seg, idx, arr)->
      if seg.fixed
        prev_idx = idx
        return seg
      else
        next = arr[idx+1]
        prev = arr[prev_idx]
        vector_next = next.point.subtract(seg.point)
        vector_prev = seg.point.subtract(prev.point)
        distance = vector_prev.length
        angle_distance = Math.abs(vector_next.angle - vector_prev.angle)
        cull = distance < threshold and angle_distance < angle_threshold
        # console.log "A", prev_idx, idx, cull, distance.toFixed(0), angle_distance.toFixed(0)
        if cull 
          null 
        else 
          prev_idx = idx
          seg
    okay_segments = _.compact okay_segments
    this.replaceSegments(okay_segments)

  pull: ()->
    scope = this
    # this.selected = true
    this.strokePath.clearHandles()
    this.threadPath.clearHandles()

     # RESAMPLE
    if not this.resampled
      this.resample()

    start_length = this.threadPath.length
    end_length = start_length - 1
    iter = 0
    step_percent = 1.0
      

    while start_length - end_length > stitcher.Trace.SIMULATION_STOP_THRESHOLD
      start_length = this.threadPath.length

      # ADD CONTROL POINT WHEN COLLISION OCCURS 
      obstacles = paper.project.getItems
        name: "obstacle"
      _.each obstacles, (obstacle)->
        if scope.strokePath.intersects(obstacle)
          ixts = scope.strokePath.getIntersections(obstacle)
          if ixts.length > 0
            _.each ixts.slice(0, 1), (ixt, i, arr)->
              c = new paper.Path.Circle
                name: "hit"
                radius: 1
                position: ixt.segment.point
                fillColor: "yellow"
              c.remove()
              ixt.segment.fixed = true

      # COMPUTE FORCES; 0 ON FIXED NODES
      # console.log "FIXED", _.map this.strokePath.segments, "fixed"
      forces = _.map this.strokePath.segments, (mass, idx, arr)->
        if mass.fixed
          return new paper.Point(0, 0)   
        else
          prev = arr[idx-1].point
          next = arr[idx+1].point
          curr = mass.point
          
          # COMPUTE COMPONENT FORCES
          force = prev.subtract(curr)
          force.length = force.length * step_percent
          force2 = next.subtract(curr)
          force2.length = force2.length * step_percent

          # AVERAGE FORCES
          force = force.add(force2).divide(2)
          return force
        
      # APPLY FORCES
      # console.log "FORCE", forces
      _.each forces, (force, idx)->
        movement = new paper.Path.Line
            from: scope.strokePath.segments[idx].point
            to: scope.strokePath.segments[idx].point.add(force)
        _.each obstacles, (obstacle)->
          if obstacle.intersects(movement) or obstacle.contains(scope.strokePath.segments[idx].point)
            force = new paper.Point(0, 0)
        movement.remove()

        scope.strokePath.segments[idx].point = scope.strokePath.segments[idx].point.add(force)
        scope.threadPath.segments[idx].point = scope.threadPath.segments[idx].point.add(force)

      end_length = this.threadPath.length
      iter += 1
      diff = start_length - end_length
      # console.log iter, diff, start_length, "->", end_length, scope.threadPath.segments.length
      if iter%stitcher.Trace.CULL_AFTER_X_ITERATIONS==0
        if diff > 1
          # Remove points that are too close
          scope.cull(4, 5)
        if diff < 1
          # Remove points that do not contribute angular data
          scope.cull(100, 3)
      window.debug_thread = scope

  simplify: ()->
    this.threadPath.simplify()
    this.threadPath.firstSegment.clearHandles()
    this.threadPath.lastSegment.clearHandles()

    this.strokePath.simplify()
    this.strokePath.firstSegment.clearHandles()
    this.strokePath.lastSegment.clearHandles()
  length: ()-> this.strokePath.length
  render: (x)->
    scope = this
    # GRAB ALL ITEMS BELOW THIS
    direction = if scope.z_index > 0 then -1 else 1
    # direction = if stitch.canvas.view_mode == "top" then direction else -1*direction
    item = paper.project.getItem
      z_index: scope.z_index + direction
    if direction == -1
      this.insertAbove(item)
    else
      this.insertBelow(item)
    stitch.canvas.renderZ()
    go_back = (stitcher.Trace.STROKE_PATH_SCALE * stitcher.Trace.TRACE_PATH_DEFAULT_WIDTH)/2*0.7

    if this.strokePath.length > go_back
      if this.recede_start and not this.recede_start_rendered
        trim = this.strokePath.splitAt(go_back)
        this.strokePath.remove()
        this.strokePath = trim
        this.recede_start_rendered = true
        
    if this.strokePath.length > go_back
      if this.recede_end and not this.recede_end_rendered
        trim = this.strokePath.splitAt(this.strokePath.length - go_back)
        trim.remove()
        this.recede_end_rendered = true