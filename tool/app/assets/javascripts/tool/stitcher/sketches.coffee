class stitcher.Sketch
  constructor: (name)->
    this.name = name
    console.log "\tImporting", this.name, "to canvas.."
    @procedure()
  clearCanvasAndBegin: ()->
    thread = stitch.threadkeeper.current_thread
    thread.remove()
    thread = stitch.threadkeeper.knotAndBegin()
  procedure: ()->       
    return trace




class stitcher.CrossStitchSketch extends stitcher.Sketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Cross Stitch"
    super ops
  up: (thread, amount=10, snap=true)->
    thread.stitch(0, -amount, snap, true) 
  down: (thread, amount=10, snap=true)->
    thread.stitch(0, amount, snap, true) 
  right: (thread, amount=10, snap=true)->
    thread.stitch(amount, 0, snap, true) 
  left: (thread, amount=10, snap=true)->
    thread.stitch(-amount, 0, snap, true) 
  fdd: (thread, amount_x=10, amount_y=10, snap=true)->
    thread.stitch(amount_x, amount_y, snap, true) 
  fdu: (thread, amount_x=10, amount_y=10, snap=true)->
    thread.stitch(amount_x, -amount_y, snap, true)
  bdd: (thread, amount_x=10, amount_y=10, snap=true)->
    thread.stitch(-amount_x, amount_y, snap, true) 
  bdu: (thread, amount_x=10, amount_y=10, snap=true)->
    thread.stitch(-amount_x, -amount_y, snap, true)
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
  
    thread.passThrough()
    thread.stitch(-80, 0, true, true)
    _.each _.range(0, 10), (i)->
      scope.fdd(thread)  
      thread.passThrough()
      scope.up(thread)  
      thread.passThrough()
    _.each _.range(0, 10), (i)->
      scope.bdd(thread)  
      thread.passThrough()
      scope.up(thread)  
      thread.passThrough()

class stitcher.SVGSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "SVGSketch"
    super ops
  lcd: (f)->
    boundary = f.getItem
      name: "boundary"
    stitch.canvas.generate_heat_grid(boundary.bounds.expand(25), 100)
  addSVG: (ops)->
    scope = this
    # POSITION HANDLING
    if not ops.position
      ops.position = paper.view.center
    ops.position = ops.position.clone()

    console.log "LOADING", ops.url
    paper.project.activeLayer.name = "EMBR"
    paper.project.importSVG ops.url, 
      expandShapes: true
      insert: true
      onError: (item, err)->
        alertify.error "Could not load: " + item
        console.error item, err
      onLoad: (item) ->  
        console.log (item)
        item.position = ops.position
        item.z_index = 0
        # Extract Path and Compound Path Elements
        paths = item.getItems
          className: (n)->
            _.includes ["Group", "Path", "CompoundPath"], n
        # Add Interactivity
        # console.log "paths", _.map paths, "name"
        _.each paths, (p)-> 
          if p.name
            name = _.filter p.name.split("_"), (x)-> isNaN(x)
            p.name = name.join('-')
            p.set
              strokeColor: "black"
              fillColor: null
              strokeWidth: 1
            p.name = p.name.replaceAll("-x5F-", "_")

            # p.name = p.name.split("_")[0]
        # console.log "paths2", _.map paths, "name"
        scope.design = item

        scope.onLoad()  
  onLoad: ()->
    return



class stitcher.SatinStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Satin Stitch"
    super ops
  stitch: (thread)->
    this.down(thread, 30, false)
    thread.passThrough()
    this.fdu(thread, thread.width*2, 30, false)
    thread.passThrough()
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    thread.stitch(-40, 0, true, true)
    _.each _.range(0, 20), (i)->
      scope.stitch(thread)

class stitcher.RunningStitch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Running Stitch"
    super ops
  stitch: (thread)->
    this.right(thread, 10, false)
    thread.passThrough()
    this.right(thread, 5, false)
    thread.passThrough()
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    thread.stitch(-80, 0, true, true)
    _.each _.range(0, 10), (i)->
      scope.stitch(thread)

class stitcher.FeatherStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Feather Stitch"
    super ops

  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    # thread.stitch(-40, -40, true, true)
    column_spacing = 20
    feather_height = 15
    feather_lock_height=10
    rows = 2

    thread.stitch(-column_spacing*1.5, -feather_height*rows*2, false, true)

    scope.fdd(thread, column_spacing, feather_height, false) #A
    scope.fdu(thread, column_spacing, feather_height, false) #B
    thread.passThrough()
    scope.bdd(thread, column_spacing, feather_lock_height, false) #C
    thread.passThrough()

    _.each _.range(0, rows), (i)->
      scope.fdd(thread, column_spacing, feather_height, false) #D
      scope.fdu(thread, column_spacing, feather_height, false) #D
      thread.passThrough()
      scope.bdd(thread, column_spacing, feather_lock_height, false) #E
      thread.passThrough()
      
      scope.bdd(thread, column_spacing, feather_height, false) #F
      scope.bdu(thread, column_spacing, feather_height, false) #F
      thread.passThrough()
      scope.fdd(thread, column_spacing, feather_lock_height, false)
      thread.passThrough()
      
      scope.fdd(thread, column_spacing, feather_height, false) #A
      scope.fdu(thread, column_spacing, feather_height, false) #B
      thread.passThrough()
      scope.bdd(thread, column_spacing, feather_lock_height, false) #F
      thread.passThrough()
  
      scope.bdd(thread, column_spacing, feather_height, false) #F
      scope.bdu(thread, column_spacing, feather_height, false) #F
      thread.passThrough()
      scope.fdd(thread, column_spacing, feather_lock_height, false) #A
      thread.passThrough()

    # LOCK THE LAST STITCH
    scope.down(thread, 10, false)

class stitcher.ChainStitch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Chain Stitch"
    super ops
  stitch: (thread)->
    this.down(thread, 30, false)
    thread.passThrough()
    this.fdu(thread, thread.width*2, 30, false)
    thread.passThrough()
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    stitches = 10
    thread.stitch(-80, 0, true, true)
    _.each _.range(0, stitches), (i)->
      scope.fdu(thread, 10, 8, false)
      scope.fdd(thread, 10, 8, false)
      scope.bdd(thread, 10, 8, false)
      scope.bdu(thread, 10, 8, false)
      thread.passThrough()
      scope.right(thread, 15, false)
      thread.passThrough()
    scope.right(thread, 15)

class stitcher.LongAndShortStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "LongAndShort Stitch"
    super ops
  stitch: (thread)->
    this.down(thread, 30, false)
    thread.passThrough()
    this.fdu(thread, thread.width*4, 30, false)
    thread.passThrough()
  
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    one_thread = thread.width*2
    two_thread = thread.width*4
    long_length = 30
    short_length = 15
    gap = 4
    rows=18
    # LONG PASS/ LONG ROW
    thread.passThrough()
    thread.stitch(-80, 0, true, true)
    _.each _.range(0, rows), (i)->
      scope.stitch(thread)

    scope.down(thread, long_length, false)
    thread.passThrough()
    scope.bdu(thread, one_thread, long_length, false)
    
    # SHORT PASS/ SHORT ROW
    _.each _.range(0, rows), (i, idx, arr)->
      thread.passThrough()
      scope.down(thread, short_length, false)
      thread.passThrough()
      if i != arr.length-1
        scope.bdu(thread, two_thread, short_length, false)

    scope.down(thread, long_length+gap, false)
    thread.passThrough()
    scope.up(thread, long_length, false)
    thread.passThrough()

    # LONG PASS/ SHORT ROW
    _.each _.range(0, rows-1), (i)->
      scope.fdd(thread, two_thread, long_length, false)
      thread.passThrough()
      scope.up(thread, long_length, false)
      thread.passThrough()


class stitcher.HerringboneStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Herringbone Stitch"
    super ops
  fill_rectangle: (r, thread, stitch_width, stitch_height)->
    scope = this
    pt = r.bounds.bottomLeft
    ptt = r.bounds.topLeft

    ptt = ptt.add(new paper.Point(stitch_width/2, 0))
    thread.stitch(ptt.x, ptt.y, false, false)
    thread.passThrough()

    while r.contains(pt) and r.contains(ptt)
      scope.left(thread, stitch_width/2, false)  
      thread.passThrough()
      pt = pt.add(new paper.Point(stitch_width, 0))
      if not r.contains(pt) then return
      thread.stitch(pt.x, pt.y, false, false)
      thread.passThrough()
      scope.left(thread, stitch_width/2, false)  
      thread.passThrough()
      ptt = ptt.add(new paper.Point(stitch_width, 0))
      if not r.contains(ptt) then return
      thread.stitch(ptt.x, ptt.y, false, false)
      thread.passThrough()


  stitch2: (thread, stitch_height=50, stitch_width=30)->
    scope = this
    stitch.canvas.grid_pts(false)
    c = new paper.Path.Circle
      parent: stitch.canvas
      name: "guide"
      radius: Ruler.in2pts(6)
      strokeWidth: Ruler.mm2pts(3)
      strokeColor: "white"
      position: stitch.canvas.center()
      z_index: 0
    c = new paper.Path.Circle
      parent: stitch.canvas
      name: "guide"
      radius: Ruler.in2pts(3)
      strokeWidth: Ruler.mm2pts(3)
      strokeColor: "white"
      position: stitch.canvas.center()
      z_index: 0
    rect = c.strokeBounds.clone()
    rs = _.range(0, (rect.height / stitch_height))
    console.log "N", rect.height / stitch_height
    rect.height = stitch_height
    rect_guides = new paper.Group
      name: "guide"
      parent: stitch.canvas



    parameters = [[0.5, 1, "blue"], [0.75, 1, "green"], [1, 1, "yellow"], [1, 0.75, "orange"], [1, 0.5, "red"]]
    row_padding = 5
    _.each rs.slice(0, parameters.length), (r, i)->
      rect = rect.clone()
      sh = parameters[i][1] * stitch_height
      sh = sh + (row_padding * 2)
      console.log "STITCH RECT", i, stitch_height, sh
      rect.height = sh 
      r = new paper.Path.Rectangle
        parent: rect_guides
        name: "guide"
        rectangle: rect
        strokeWidth: 1
        strokeColor: "red"
      rect.point = rect.point.add(new paper.Point(0, sh))
    
    rect_guides.fitBounds(c.strokeBounds)

    
    _.each rect_guides.children.slice(0, parameters.length), (r, i, arr)->
      thread.colorize(parameters[i][2])
      rp = new paper.Path.Rectangle
        rectangle: r.bounds.expand(-Ruler.mm2pts(row_padding))
      scope.fill_rectangle(rp, thread, stitch_width * parameters[i][0], stitch_height* parameters[i][1])
      if i != arr.length-1
        thread = stitch.threadkeeper.knotAndBegin()
        thread.passThrough()
    c.remove()
    l = new paper.Path.Line
      parent: stitch.canvas
      strokeWidth: Ruler.mm2pts(2)
      strokeColor: "white"
      from: rect_guides.bounds.topCenter
      to: rect_guides.bounds.bottomCenter
      z_index: -1

    offset = rect_guides.bounds.width/4
    l = new paper.Path.Line
      parent: stitch.canvas
      strokeWidth: Ruler.mm2pts(1)
      strokeColor: "white"
      from: rect_guides.bounds.topCenter.add(new paper.Point(offset, 0))
      to: rect_guides.bounds.bottomCenter.add(new paper.Point(offset, 0))
      z_index: -1
    l = new paper.Path.Line
      parent: stitch.canvas
      strokeWidth: Ruler.mm2pts(1)
      strokeColor: "white"
      from: rect_guides.bounds.topCenter.add(new paper.Point(-offset, 0))
      to: rect_guides.bounds.bottomCenter.add(new paper.Point(-offset, 0))
      z_index: -1
    l = new paper.Path.Line
      parent: stitch.canvas
      strokeWidth: Ruler.mm2pts(1)
      strokeColor: "white"
      from: rect_guides.bounds.topCenter.add(new paper.Point(2*offset, 0))
      to: rect_guides.bounds.bottomCenter.add(new paper.Point(2*offset, 0))
      z_index: -1
    l = new paper.Path.Line
      parent: stitch.canvas
      strokeWidth: Ruler.mm2pts(1)
      strokeColor: "white"
      from: rect_guides.bounds.topCenter.add(new paper.Point(-2*offset, 0))
      to: rect_guides.bounds.bottomCenter.add(new paper.Point(-2*offset, 0))
      z_index: -1
    stitch.canvas.renderZ()
  stitch: (thread)->
    this.fdu(thread)  
    this.fdu(thread)  
    thread.passThrough()
    this.left(thread)  
    thread.passThrough()
    this.fdd(thread)  
    this.fdd(thread)
    thread.passThrough() 
    this.left(thread)  
    thread.passThrough() 
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    this.stitch2(thread, Ruler.mm2pts(18), Ruler.mm2pts(10))
    # thread.stitch(-80, 20, true, true)
    # _.each _.range(0, 5), (i)->
    #   scope.stitch(thread)

class stitcher.SeedStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Seed Stitch"
    super ops    
  
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    # thread.passThrough()

    c = new paper.Path.Circle
      radius: Ruler.in2pts(5)
      position: stitch.canvas.center()
      strokeColor: "red"
      strokeWidth: 1

    thrown = []
    count = 0
    while thrown.length < 100 and count < 1000
      randomVector = new paper.Point(Math.random(), Math.random())
      hypotenuse = c.bounds.bottomRight.subtract(c.bounds.topLeft).length
      randomVector.length = Math.random() * hypotenuse
      pt = c.bounds.topLeft.add(randomVector)
      if c.contains(pt)
        seed = new paper.Path.Circle
          name: "seed"
          radius: 10
          position: pt
          fillColor: "red"
        seeds = paper.project.getItems
          name: "seed"
        seeds.push(c)
        collision = _.any seeds, (other_seed)->
          if seed.id == other_seed
            return false
          else
            seed.intersects(other_seed)
        if collision
          seed.remove()
        else
          thrown.push(pt)
        count+=1
    seeds = paper.project.getItems
      name: "seed"    
    _.each seeds, (seed)->
      seed.remove()


    # _.each thrown, (pt)->
    #   seed = new paper.Path.Circle
    #     name: "seed"
    #     radius: 1
    #     position: pt
    #     fillColor: "yellow"
    #     strokeColor: "blue"

    # GREEDY STITCH
    remove_from_candidates = (index)->
      candidate = thrown[index]
      thrown.splice(index, 1)
      return candidate

    greedy_candidate_selection = (last_pt)->
      min_dis = 100000000000
      min_idx = 0
      _.each thrown, (seed, idx)->
        distance = seed.getDistance(last_pt)
        if distance < min_dis
          min_dis = distance
          min_idx = idx

      return remove_from_candidates(min_idx)

    idx = 0
    count = 0
    while thrown.length > 0 and count < 1000
      seed_pt = greedy_candidate_selection(seed_pt)
      thread.passThrough()
      

      a = new paper.Point(10, 0)
      a = a.rotate(Math.random() * 180)

      b = a.clone().rotate(90)
      b.length = 3
      c = b.clone().rotate(90)
      c.length = 10
      recenter = a.clone().add(b.clone().multiply(0.5))
      recenter.length = -5

      seed_pt = seed_pt.add(recenter)
      thread.stitch(seed_pt.x, seed_pt.y, false, false)
      if count>0
        thread.passThrough()
      # thread.stitch(recenter.x,recenter.y, false, true)
      thread.stitch(a.x,a.y, false, true)
      thread.passThrough()
      thread.stitch(b.x, b.y, false, true)
      thread.passThrough()
      thread.stitch(c.x, c.y, false, true)
      
      
      count += 1

  
 
class stitcher.StemStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Stem Stitch"
    super ops    
    
  stitch2: (thread)->
    l = new paper.Path.Circle
      position: stitch.canvas.center()
      strokeColor: 'red'
      strokeWidth: 3
      radius: 100
      # from: paper.view.center.subtract(new paper.Point(50, 0))
      # to: paper.view.center.add(new paper.Point(50, 0))
    stitch_length = 15
    tilt=3
    half_stitch_length = stitch_length/2
    offsets = _.range(0, l.length+1, stitch_length)
    _.each offsets, (offset)->
      tangent = l.getTangentAt(offset)
      normal = l.getNormalAt(offset)
      pt = l.getPointAt(offset)
      below = tangent.multiply(stitch_length).add(normal.multiply(-tilt))
      
      a = pt.add(below)
      b = a.subtract(pt)
      b.length = b.length/2
      b = pt.add(b).add(normal.multiply(tilt))
      
      thread.stitch(a.x, a.y, false, false)
      thread.passThrough()
      thread.stitch(b.x, b.y, false, false)
      thread.passThrough()
    l.remove()
  procedure: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    scope.stitch2(thread)

class stitcher.StarStitchSketch extends stitcher.CrossStitchSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Star Stitch"
    super ops

  procedure: ()->
    scope = this
    stitch.canvas.grid_pts(false)
    # thread = this.clearCanvasAndBegin()
    thread = stitch.threadkeeper.knotAndBegin()
    

    pointify = (circle)->
      step = circle.length/8
      _.map _.range(0, circle.length, step), (x)->
        pt = circle.getPointAt(x)
        stitch.canvas.makeGridPoint(pt)
        pt
        
    c = new paper.Path.Circle
      name: "outer_boundary"
      parent: stitch.canvas
      radius: Ruler.mm2pts(30)
      strokeWidth: 5
      strokeColor: "white"
      position: stitch.canvas.center()
      z_index:0
    out_pts = pointify(c)
    c = new paper.Path.Circle
      name: "mid_boundary"
      parent: stitch.canvas
      radius: Ruler.mm2pts(15)
      strokeWidth: 5
      strokeColor: "white"
      position: stitch.canvas.center()
      z_index:0
    mid_pts = pointify(c)
    c = new paper.Path.Circle
      name: "inner_boundary"
      parent: stitch.canvas
      radius: Ruler.mm2pts(5)
      strokeWidth: 1
      strokeColor: "white"
      position: stitch.canvas.center()
      z_index:0
    in_pts = pointify(c)

    console.log out_pts, in_pts
   
    thread.stitch(in_pts[0].x, in_pts[0].y, false, false)
    thread.passThrough()


    i = 0
    _.each _.range(0, out_pts.length), (i)->
      if i == 0
        inner = in_pts[i]
        outer = out_pts[i]
        mid = mid_pts[i]

        thread.stitch(inner.x, inner.y, false, false)
        thread.stitch(outer.x, outer.y, false, false)
        thread.passThrough()
      else
        inner = in_pts[i]
        outer = out_pts[i]
        mid = mid_pts[i]
        if i%2==1
          pt = mid
        else
          pt = outer
        thread.stitch(inner.x, inner.y, false, false)
        thread.passThrough()
        thread.stitch(pt.x, pt.y, false, false)
        thread.passThrough()

  stitch: (thread, major=20, minor=10)->
    this.up(thread, major, false)  
    thread.passThrough()
    
    this.fdd(thread, minor, minor, false)
    thread.passThrough()
    this.bdu(thread, minor, minor, false)
    thread.passThrough()

    this.right(thread, major, false)
    thread.passThrough()
    this.left(thread, major, false)
    thread.passThrough()

    this.fdu(thread, minor, minor, false)
    thread.passThrough()
    this.bdd(thread, minor, minor, false)
    thread.passThrough()
    
    this.up(thread, major, false)
    thread.passThrough()
    this.down(thread, major, false)
    thread.passThrough()
    
    this.bdu(thread, minor, minor, false)
    thread.passThrough()
    this.fdd(thread, minor, minor, false)
    thread.passThrough()

    this.left(thread, major, false)
    thread.passThrough()
    this.right(thread, major, false)
    thread.passThrough()

    this.bdd(thread, minor, minor, false)
    thread.passThrough()
    this.fdu(thread, minor, minor, false)
    thread.passThrough()
  procedure2: ()->
    scope = this
    # thread = this.clearCanvasAndBegin()
    thread = stitch.threadkeeper.knotAndBegin()
    thread.passThrough()
    thread.stitch(0, 15, true, true)
  
    scope.stitch(thread, Ruler.mm2pts(30), Ruler.mm2pts(15))
    

    thread = stitch.threadkeeper.knotAndBegin()
    thread.passThrough()
    thread.stitch(200, 0, true, true)
    scope.stitch(thread, Ruler.mm2pts(20), Ruler.mm2pts(10))

    thread = stitch.threadkeeper.knotAndBegin()

    thread.passThrough()
    thread.stitch(100, 30, true, true)
    scope.stitch(thread, Ruler.mm2pts(15), Ruler.mm2pts(5))

   

class stitcher.SerpentineStitchSketch extends stitcher.Sketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Serpentine Stitch"
    super ops
  
  procedure: ()->
    thread = this.clearCanvasAndBegin()
    
    pts = this.plot_points
      radius: 50
      line_density: 32

    boundary = paper.project.getItem
      name: "boundary"
    axis = paper.project.getItem
      name: "axis"

    _.each pts, (pt, idx, arr)->
      if idx%2==0 
        pt = pt.reverse()

      thread.stitch(pt[0].x, pt[0].y, false, false) 
      thread.passThrough()
      
      _.each pt, (p)->
        thread.stitch(p.x, p.y, false, false) 

      thread.passThrough()

  plot_points: (ops)->
    # ADD NEW TRACE
    boundary = new paper.Path.Circle
      name: "boundary"
      radius: ops.radius
      position: paper.view.center
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: false

    boundary.sendToBack()
    boundary.rotate(90)
    # boundary.segments[0].clearHandles()

    axis = new paper.Path.Line
      name: "axis"
      from: boundary.bounds.topCenter
      to: boundary.bounds.bottomCenter
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: false
    axis.sendToBack()

    tangent = axis.getTangentAt(0)
    tangent.length = 50

    normalA = axis.getNormalAt(0)
    normalA.length = 1000
    normalB = axis.getNormalAt(0)
    normalB.length = -1000

    step = axis.length/ops.line_density
    offsets = _.range(step, axis.length, step)
    
    pts = _.map offsets, (offset, idx)->
      c = new paper.Path.Line
        name: "c"
        radius: 4
        from: axis.getPointAt(offset).add(normalA)
        to: axis.getPointAt(offset).add(normalB)
        strokeColor: "blue"
        strokeWidth: 1
        visible: false
      ixts = c.getIntersections(boundary)
      c.segments = _.map ixts, "point"
      pts = _.map c.segments, "point"
    
    return pts

class stitcher.FlyStitchSketch extends stitcher.Sketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Fly Stitch"
    super ops
  
  procedure: ()->
    thread = this.clearCanvasAndBegin()


    boundary = new paper.Path.Circle
      name: "boundary"
      radius: 100
      position: paper.view.center
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: false

    boundary.sendToBack()
    boundary.rotate(90)
    boundary.segments[0].clearHandles()

    axis = new paper.Path.Line
      name: "axis"
      from: boundary.bounds.topCenter
      to: boundary.bounds.bottomCenter
      strokeColor: "white"
      strokeWidth: 2
      z_index: 0
      visible: false
    axis.sendToBack()

    this.flystitch(paper.project, 0)

  flystitch: (f, idx)->
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    if idx == 2
      pts = this.plot_points
        stem_density: 14/3 # number of times stitch crosses stem
        lock_stitch_length: 2 # at least 4
        pull_distance: 3 # at least 10
        v_acuteness: 10  
        boundary: boundary
        axis: axis
    else
      pts = this.plot_points
        stem_density: 16/3 # number of times stitch crosses stem
        lock_stitch_length: 2 # at least 4
        pull_distance: 3 # at least 10
        v_acuteness: 10 
        boundary: boundary
        axis: axis

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
class stitcher.DaisyStitchSketch extends stitcher.Sketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Daisy Stitch"
    super ops
  plot_petals: (ops)->
    # ADD NEW TRACE
    c = new paper.Path.Circle
      name: "daisy_stitch_ref"
      radius: ops.radius
      position: paper.view.center
      strokeColor: "white"
      strokeWidth: 2
    c.sendToBack()
    c.rotate(90)
    petals = _.range(0, c.length, c.length/ops.petal_count)
    petals = petals.slice(0, 5)
    return petals

  procedure: ()->
    thread = this.clearCanvasAndBegin()

    petals = this.plot_petals
      radius: 50
      petal_count: 5
    c = paper.project.getItem
      name: "daisy_stitch_ref"

    # Wrap around point
    triangles =_.map petals, (p)->
      petal = new paper.Path.Circle
        radius: 5
        position: c.getPointAt(p).clone()
        fillColor: "white"
        strokeWidth: 2
      petal.sendToBack()
      out = c.getPointAt(p)
      n = c.getNormalAt(p)
      n.length = 5
      out = out.add(n)
      
      minus = p-15
      plus = p+15
      if plus > c.length
        plus = plus - c.length
      if minus < 0
        minus = c.length + minus

      return [c.bounds.center, c.getPointAt(minus), out.clone(), c.getPointAt(plus), c.bounds.center]

    # Lock the petal
    lock_stitch =_.map petals, (p)->
      out = c.getPointAt(p)
      n1 = c.getNormalAt(p)
      n2 = c.getNormalAt(p)
      n1.length = -10
      n2.length = 20
      a = out.add(n1)
      b = out.add(n2)
      return [a, b]


    # PETAL STITCH
    _.each triangles, (pts, idx, arr)->
      thread.passThrough()
      _.each pts, (pt)->
        thread.stitch(pt.x, pt.y, false, false)
      
      _.each lock_stitch[idx], (pt)->
        thread.passThrough()
        thread.stitch(pt.x, pt.y, false, false)
        
      thread.passThrough()

      pt = arr[idx][0]
      thread.stitch(pt.x, pt.y, false, false)

    



class stitcher.ObstacleResolutionDebuggingSketch extends stitcher.Sketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Obstacle resolution debugging sketch"
    super ops

  procedure: ()->
      # ADD NEW TRACE
      thread = this.clearCanvasAndBegin()

      topStitch = thread.passThrough()
      thread.stitch(0, 0, false)
      thread.stitch(0, 80, false)

      thread.passThrough()
      thread.stitch(40, -40, false)
      
      thread.passThrough()
      thread.stitch(-20, 0, false)
      
      thread.under(topStitch) # Under string
      thread.stitch(-40, 0, false) 
      
      thread.return()
      thread.stitch(-20, -60, false)
      thread.stitch(60, 0, false)
      
      thread.passThrough()
      thread.pull_last_segment()
      # thread.plot_last_segment()





      # Obstacles
      # o = new stitcher.Obstacle(0, 0)
      

class stitcher.SimulationDebuggingSketch extends stitcher.Sketch
  constructor: (ops)->
    super ops

  procedure: ()->
    thread = this.clearCanvasAndBegin()
    # ADD NEW TRACE
    @addTrace("over")
    
    # TRACE
    y_step = 20
    @addPointToTrace(0, 0, false)
    @addPointToTrace(-40, 0, false)
    @addPointToTrace(0, y_step, false)
    @addPointToTrace(80, 0, false)
    @addPointToTrace(0, y_step, false)
    @addPointToTrace(-80, 0, false)
    @addPointToTrace(0, y_step, false)
    @addPointToTrace(80, 0, false)

    # Obstacles
    o = new stitcher.Obstacle(0, 50, true)
    o = new stitcher.Obstacle(0, 30, true)
    o = new stitcher.Obstacle(0, 10, true)
   
