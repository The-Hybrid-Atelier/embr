
class stitcher.ThreadKeeper
  constructor: (ops)->
    this.name = "threadkeeper"
    this.current_thread = null
    this.threads = []
  knotAndBegin: ()->
    this.current_thread = new stitcher.Thread
      side: "under"
    this.threads.push(this.current_thread)
    return this.current_thread
  screen_guides: ()->
    _.each this.threads, (thread)->
      if thread.length() > 0
        thread.screen_guides()
    extra_elements = paper.project.getItems
      className: "Path"
      name: (name)-> 
        name != "guide"
    _.each extra_elements, (e)->
      e.remove()

    this.save_svg("embr-screenprint")

  save_svg: (name)->
    removeable = ["grid_point", "grid_line", "hoop", "fabric"]
    _.each removeable, (r)->
      rs = paper.project.getItems
        name: r
      _.each rs, (s)->
        s.remove()
    prev = paper.view.zoom;
    console.log("Exporting file as SVG");
    paper.view.zoom = 1;
    paper.view.update();
    exp = paper.project.exportSVG
      asString: true,
      precision: 5
    saveAs(new Blob([exp], {type:"application/svg+xml"}), name + ".svg")
    paper.view.zoom = prev


class stitcher.Knot extends paper.Path.Circle
  constructor: (ops)->
    ops.radius = 2
    ops.position = paper.view.center
    super ops
    this.visible = false
    this.id = 0
    this.name = "knot"
    this.prev = null
    this.next = null
    this.side = ops.side
  length: ()->
    return 0
  remove: ()->
    return
  screenprint: ()->
    return 


class stitcher.Thread
  @SELECTION_COLOR: "yellow"
  constructor: (ops)->
    this.root = new stitcher.Knot
      side: ops.side
    this.tail = this.root
    this.last_point = stitch.canvas.getNearestGridPoint(paper.view.center)
    this.name = "thread"
    this.width = stitcher.Trace.TRACE_PATH_DEFAULT_WIDTH
  passThrough: ()->
    side = if this.tail.side == "under" then "over" else "under"
    t = this.addTrace(side)
    return t
  getColor: ()->
    this.tail.getColor()
  continue: ()->
    side = this.tail.side
    t = this.addTrace(side)
    return t

  addTrace: (side)->
    t = new stitcher.Trace
      prev: this.tail
      side: side
      next: null
    t.thread = this
    this.tail.next = t
    this.tail = t
    return t

  stitch: (x, y, grid_correct=true, from_last=true)->
    if this.tail.name == "trace"
      pt = new paper.Point(x,y)
      if from_last
        pt = this.last_point.add(pt)
      if grid_correct
        pt = stitch.canvas.getNearestGridPoint(pt)
      this.last_point = pt
      
      this.tail.addPt(pt)
      this.tail.render()

  under: (topStitch)->
    t = this.continue()
    z_under = Math.abs(topStitch.z_index)-0.1
    if t.side == "over" 
      t.z_index = z_under
      t.insertBelow(topStitch)
    else
      z_under = z_under*-1
      t.z_index = z_under
      t.insertAbove(topStitch)

  return: ()->
    t = this.continue()
    t.recede("start")    
    t.prev.recede("end")
    t.prev.prev.recede("end")
    return t

  go_back: ()->
    this.select_position = this.tail
    segment = this.current()
    segment.clear()

    if segment.root()
      this.tail = segment.root().prev
      this.tail.next = null
      console.log "REMOVING", segment.id()
    else
      console.log "KNOT"


  last_segment: ()->
    return this.walk(this.tail, 0)

  colorize: (color)->
    node = this.tail
    while node and node.name != "knot"
      node.colorize(color)
      node = node.prev

  clear_selection: ()->
    this.colorize('reset')
  
  select: (segment, clear=true)->
    if clear
      this.clear_selection()
    segment.colorize(stitcher.Thread.SELECTION_COLOR)

  select_left: ()-> 
    segment = this.left()
    if segment
      this.select(segment)
      segment.update_view
  select_right: ()->  
    segment = this.right()
    if segment
      this.select(segment)
      segment.update_view
  
  fade_left: ()->
    segment = this.current()
    if segment
      segment.fade()
    segment = this.left()
    if segment
      segment.fade()
    return segment

  fade_right: ()->
    segment = this.current()
    if segment
      segment.show()
    segment = this.right()

  current: ()->
    if not this.select_position
      this.select_position = this.tail
    return new stitcher.Segment(this.walk(this.select_position, 0))
    
  left: ()->
    if not this.select_position
      this.select_position = this.tail

    segment = new stitcher.Segment(this.walk(this.select_position, -1))
        
    if _.isUndefined segment.root()
      return null

    this.select_position = segment.root()
    # console.log "SELECT", this.select_position.id, _.map segment.members, "id"
    
    return segment
    
  right: ()->
    if not this.select_position
      this.select_position = this.tail

    segment = new stitcher.Segment(this.walk(this.select_position, 1))
    
    

    if _.isUndefined segment.tail()
      return null
    else
      this.select_position = segment.tail()
      console.log "SELECT", this.select_position.id, _.map segment.members, "id"
      return segment

    
  walk: (node=null, direction=0)->
    step = if direction < 0 then 1 else -1
    step_lang = if direction < 0 then 'LEFT' else "RIGHT"
    same_side = node.side

    if node.name == "knot" and direction == 0
      return []

    if _.isNull node
      node = this.tail

    # Compute segment left and right
    segment = []
    next_node = node.next
    prev_node = node.prev
    segment.push(node)
    while next_node and next_node.side == same_side
      segment.push(next_node)
      next_node = next_node.next
    while prev_node and prev_node.side == same_side
      segment.unshift(prev_node)
      prev_node = prev_node.prev

    # look prev
    if direction == 0
      return segment
    else if direction < 0
      if segment[0].prev
        return this.walk(segment[0].prev, direction+step)
      else
        return []
    else# look next
      if segment[segment.length-1].next
        return this.walk(segment[segment.length-1].next, direction+step)
      else
        return []
  count: ()->
    this.select_position = this.tail
    s = this.current()
    sum = 0
    while s
      sum += 1
      s = this.left()
    return sum
  screen_guides: ()->
    this.select_position = this.tail
    s = this.current()
  
    while s
      if s.side() == "over"
        s.screenprint()
      s = this.left()

  length: ()->
    this.select_position = this.tail
    s = this.current()
    sum = 0
    while s
      sum += s.length()
      s = this.left()
    return sum

  fb_ratio: ()->
    this.select_position = this.tail
    s = this.current()
    sum = 0
    sum_front = 0
    sum_back = 0
    while s
      if s.side() == "over"
        sum_front+=s.length()
      else
        sum_back+=s.length()
      sum += s.length()
      s = this.left()
    return sum_front/sum_back


  remove: ()->
    node = this.tail
    while node
      node.remove()
      node = node.prev 



  print: (segment)->
    node = this.tail
    nodes = []
    while node
      connection = if node.side == "over" then "---" else '...' 
      if _.isNull node.next
        connection = "x" 

      nodes.push(node.id+"("+node.length().toFixed(0)+") "+connection+" ")
      node = node.prev
    console.log nodes.reverse().join('')

  pull_last_segment: ()->
    this.print()
    this.select_position = this.tail
    s = this.current()
    s.print("PULL")
    s.pull()
    this.print()

  pull_xth_segment: (idx)->
    this.print()
    this.select_position = this.tail
    s = this.walk(this.tail, idx*-1)
    x = new stitcher.Segment(s)
    x.print('before')
    x.pull()
    this.print()

  select_all: ()->
    this.select_position = this.tail
    s = this.current()
    while s
      this.select(s, false)
      s = this.left()
  pull_all_segments: ()->
    this.select_position = this.root
    s = this.right()

    while s
      s.pull()
      console.log "PULLING", s.id(), s.length()
      s.print('\t')
      paper.view.update()
      s = this.right()

    
  plot_last_segment: ()->
    this.go_back()
    this.print()
    this.select_position = this.tail
    s = new stitcher.Segment(this.left())
    # debugger;
    s.print("FullPATH")
    s.fullPath(true)
    


        
