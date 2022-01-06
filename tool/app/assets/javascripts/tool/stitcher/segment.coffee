
class stitcher.Segment
  @PULL_OFFSET: 6
  constructor: (members)->
    this.members = members
    this.name = "segment"
  id: ()->
    this.root().id
  root: ()->
    return this.members[0]
  tail: ()->
    return this.members[this.members.length-1]
  side: ()->
    return this.members[0].side
  getColor: ()->
    this.root().getColor()
  colorize: (color)->
    _.each this.members, (m)-> m.colorize(color)
  screenprint: ()->
    # console.log "adding guide to ", this.root().getWaypoint(0), this.tail().getWaypoint(-1)
    c = new paper.Path.Circle
      parent: stitch.canvas
      name: "guide"
      radius: Ruler.mm2pts(1)
      fillColor: "white"
      position: this.root().getWaypoint(0).point
      z_index: 0
    c = new paper.Path.Circle
      parent: stitch.canvas
      name: "guide"
      radius: Ruler.mm2pts(1)
      fillColor: "white"
      position: this.tail().getWaypoint(-1).point
      z_index: 0 
  clear: ()->
    _.each this.members, (m)->
      m.remove()
  fade: ()->
    _.each this.members, (m)->
      console.log "fading", m.id
      m.visible = false
      # m.opacity = 0.1
  length: ()->
    sum = 0
    _.each this.members, (m)->
      sum += m.length()
    return sum
  print: (prefix)->
    scope = this
    nodes = _.map this.members, (node, idx, arr)->
      connection = if node.side == "over" then "---" else '...'
      if _.isNull node.next
        connection = "x" 
      return node.id+"("+node.length()+") "+connection+" "
    console.log prefix, nodes.join('')

  resample: (ops)->
    ops = _.defaults ops, 
      step: 1
    pts = _.range(ops.from, ops.to+ops.step)
    return _.map pts, (offset)-> 
      if offset > ops.path.length
        offset = ops.path.length
      return ops.path.getPointAt(offset)

  update_view: ()->
    if this.side() == "under"
      stitch.canvas.set_view("bottom")
    else
      stitch.canvas.set_view("top")
  show: ()->
    $(document).trigger("select", this)
    this.update_view()
    paper.view.update()
    time = this.length() / stitcher.ANIMATION_SPEED - 100# pixels per millisecond
    # console.log "animate", this.id(), this.length().toFixed(0), time.toFixed(0)
    _.each this.members, (m)->
      # console.log "showing", m.id
      m.opacity = 1
      m.hide()

    time_allowance = _.map this.members, (m)-> m.length()
    sum = _.reduce time_allowance, ((memo, num)-> memo + num), 0
    time_allowance = _.map time_allowance, (t)-> time * (t/sum)

    t = 100
    _.each this.members, (m, idx)->
      m.animate(time_allowance[idx], t)
      t += time_allowance[idx]

  fullPath: (plot=false)->
    segments = _.map this.members, (m)->
      return m.threadPath.segments
    segments = _.flatten segments
    if plot
      f = new paper.Path
        name: "full_path"
        segments: segments
        strokeColor: "black"
        strokeCap: "round"
        strokeJoin: "round"
        strokeWidth: 1
        visible: true
      console.log f.length
    return segments

  plotObstacles: ()->
    scope = this
    obstacles = _.map this.members, (m)->
      return m.getObstacles()
    obstacles = _.flatten obstacles
    _.each obstacles, (hit)->
      o = new stitcher.Obstacle(hit.firstSegment.point.x, hit.firstSegment.point.y)
      o = new stitcher.Obstacle(hit.lastSegment.point.x, hit.lastSegment.point.y)
    return obstacles

  pull: (debug=false)->
    # PREPARE PULLING ENVIRONMENT
    stitcher.Obstacle.clearAll()
    obstacles = this.plotObstacles()

    # RESOLVED PATH
    t = new stitcher.Trace
      side: this.side()
      prev: this.members[0]
      next: null
    t.colorize("#00A8E1")
    t.replaceSegments(this.fullPath())
    t.pull()

    # CONVERT TO Z REPRESENTATIONS AND REPLACE IN THREAD OBJECT
    thread_replacement = this.convertToZThread(t, obstacles, debug)
    this.reconnect(thread_replacement)
    # CLEANUP
    this.clear()
    if not debug
      t.remove()
      stitcher.Obstacle.clearAll()
      thread_replacement.colorize("reset")

      

  reconnect:(thread_replacement)->
    first = this.members[0]
    last = this.members[this.members.length-1]

    a = thread_replacement.root.next
    b = thread_replacement.tail

    # Connect front
    first.prev.next = a
    a.prev = first.prev

    # Connect back
    if _.isNull(last.next)
      last.thread.tail = b
    else
      b.next = last.next
      last.next.prev = b

    node = a
    while node
      node.thread = first.thread
      node = node.next

  convertToZThread: (trace, obstacles, debug)->
    scope = this
    
    # FIND OUT WHERE TO SLICE
    last_offset = 0
    slices = []
    _.each obstacles, (obstacle)->
      ixts = trace.threadPath.getIntersections(obstacle)
      _.each ixts, (hit)->
        c = new paper.Path.Circle
          radius: 2
          strokeColor: 'yellow'
          strokeWidth: 1
          position: hit.point
        slices.push([last_offset, hit.offset-stitcher.Segment.PULL_OFFSET, null])
        slices.push([hit.offset-stitcher.Segment.PULL_OFFSET, hit.offset+stitcher.Segment.PULL_OFFSET, obstacle.parent])
        last_offset = hit.offset+stitcher.Segment.PULL_OFFSET
        if not debug
          c.remove()
    slices.push([last_offset, trace.threadPath.length, null])

    console.log "SLICES", slices

    # STITCH THREAD
    resolved_thread = new stitcher.Thread
      side: this.side()
    underneath = false
    new_traces = _.map slices, (slice, idx)->
      topStitch = slice[2]
      if topStitch
        t = resolved_thread.under(topStitch)
        underneath = true
      else if underneath
        t = resolved_thread.return()
        underneath = false      
      else
        t = resolved_thread.continue()
        
      # SAMPLE POINTS FROM TRACE
      pts = scope.resample
        path: trace.threadPath
        from: slice[0]
        to: slice[1]
        step: 1

      switch idx
        when 0
          color = "red"
        when 1
          color = "blue"
        when 2
          color = 'yellow'
        else
          color = "white"

      t.replaceSegments(pts)
      t.colorize(color)
      return t

    _.each new_traces, (t)->
      t.render()

    resolved_thread.print()

    # REPLACE MEMBERS
    return resolved_thread


  