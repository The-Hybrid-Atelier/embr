class stitcher.CharacterizationSketch extends stitcher.SVGSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "Characterization"
    super ops
  procedure: ()->
    url = "/designs/characterization.svg"
    console.log "loading", url
    @addSVG
      url: url
      position: stitch.canvas.center()
    return
  lcd: (f)->
    boundary = f.getItem
      name: "boundary"
    boundary = boundary.expand
      strokeOffset: 5
      joinType: "round"
      strokeAlignment: "exterior"
      z_index: 0
      visible: false
    stitch.canvas.generate_heat_grid(boundary, boundary.bounds.expand(25), 1, 1)
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
  cullLine: (line, boundary)->
    offsets = _.map line.getIntersections(boundary), "offset"
    line.segments = [line.getPointAt(_.min(offsets)), line.getPointAt(_.max(offsets))]
    return line
  onLoad: ()->
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    # scope.design.scaling = new paper.Size(2, 2)
    if true
      fill_stitches = scope.design.getItems
        className: "Group"
        # name: (x)-> _.contains ["seed", fly", "star", "cross", "satin", "daisy", "serpentine", "herringbone"], x
        name: (x)-> _.contains ["satin", "seed", "cross", "star", "fly"], x
        # name: (x)-> _.contains ["herringbone"], x
      _.each fill_stitches, (f, i)-> 
        stitch = f.name
        
        if scope[f.name]
          console.log "HERE", f
          paper.view.center = f.bounds.center
          paper.view.zoom = paper.project.view.bounds.height/f.bounds.height*0.8
          # console.log "Rendering", f.name.toUpperCase()
          console.log "HERE2", f
          vcc = 5
          thread = scope[f.name](f, i)
          console.log "HERE3", thread
          length = thread.length()

          resistance = length*stitcher.THREAD_RESISTIVITY
          current = vcc / resistance
          power = vcc * current
          # area = f.bounds.area
          area = 900
          thread_consumption = resistance/area
          heat_potential = (power/area)*1000

          console.log f.name.toUpperCase(), 
            # "\n\tarea:", Ruler.pts2mm(Ruler.pts2mm(area)).toFixed(1), "mm"
            "\nphysical"
            "\n\tlength:", Ruler.pts2mm(length).toFixed(1), "mm"
            "\n\tfront-back ratio:", new Decimal(thread.fb_ratio()).toFraction(5).toString()
            "\nelectrical"
            "\n\tresistance:", resistance.toFixed(1), "Ω"
            "\n\tcurrent:", (current*1000).toFixed(1), "mA"
            "\n\tthread_consumption:", thread_consumption.toFixed(2), "Ω/mm^2"
            "\nthermal"
            "\n\tpower:", power.toFixed(1), "W"
            "\n\tsurface_power_density:", heat_potential.toFixed(2), "mW/mm^2"
        # scope.lcd(f)
    if true
      border_stitches = scope.design.getItems
        className: "Group"
        # name: (x)-> _.contains ["stem", "running", "chain"], x
        name: (x)-> _.contains ["running"], x
      _.each border_stitches, (f, i)-> 
        # scope.lcd(f)
        stitch = f.name
        if scope[f.name]
          if i == 0
            paper.view.center = f.bounds.center
            paper.view.zoom = (paper.project.view.bounds.height/f.bounds.height) * 0.8
          # console.log "Rendering", f.name.toUpperCase()
          vcc = 5
          thread = scope[f.name](f, i)
          length = thread.length()
          resistance = length*stitcher.THREAD_RESISTIVITY
          current = vcc / resistance
          power = vcc * current
          # area = f.bounds.area
          area = f.getItem({name: "boundary"}).length
          thread_consumption = resistance/area
          heat_potential = (power/area)*1000
          # paper.view.center = f.bounds.center
          # paper.view.zoom = paper.project.view.bounds.height/f.bounds.height
          console.log f.name.toUpperCase(), 
            "\nphysical"
            "\n\tlength:", Ruler.pts2mm(length).toFixed(1), "mm"
            "\n\tfront-back ratio:", new Decimal(thread.fb_ratio()).toFraction(5).toString()
            "\nelectrical"
            "\n\tresistance:", resistance.toFixed(1), "Ω"
            "\n\tcurrent:", (current*1000).toFixed(1), "mA"
            "\n\tthread_consumption:", thread_consumption.toFixed(2), "Ω/mm^2"
            "\nthermal"
            "\n\tpower:", power.toFixed(1), "W"
            "\n\tsurface_power_density:", heat_potential.toFixed(2), "mW/mm"
  throw_points: (seed_count, seed_radius, c)->
    count = 0
    thrown = []

    while thrown.length <= seed_count and count < seed_count*10

      randomVector = new paper.Point(Math.random(), Math.random())
      hypotenuse = c.bounds.bottomRight.subtract(c.bounds.topLeft).length
      randomVector.length = Math.random() * hypotenuse
      pt = c.bounds.topLeft.add(randomVector)
      seed = new paper.Path.Circle
          name: "seedling"
          radius: seed_radius
          position: pt
          strokeColor: "red"
          strokeWidth: 1
      if c.contains(pt) and seed.getIntersections(c).length == 0
        
        seeds = paper.project.getItems
          name: "seedling"
        seeds.push(seed)
        collision = _.any seeds, (other_seed)->
          if seed.id == other_seed
            return false
          else
            seed.intersects(other_seed)
        if collision
          seed.remove()
        else
          thrown.push(seed) 
        count+=1
      else
        seed.remove()
        count+=1
    return thrown
  seed: (f, idx)->
    this._seed(f, idx, this.seedling)
  
  frenchknotseed: (f, idx)->
    this._seed(f, idx, this.frenchknotseedling)

  _seed: (f, idx, seedling)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary
    
    seed_count = 10
    seed_radius = 6
    c = guides.boundary.expand
      joinType: "round"
      strokeAlignment: "exterior"
      strokeWidth: 1
      strokeColor: "yellow"
      strokeOffset: -3
      exterior: 1
      z_index: 0
      visible: false
    
    thrown = this.throw_points seed_count, seed_radius, c
    seeds = paper.project.getItems
      name: "seedling"
    # GREEDY STITCH
    remove_from_candidates = (index)->
      candidate = thrown[index]
      thrown.splice(index, 1)
      return candidate

    greedy_candidate_selection = (last_pt)->
      min_dis = 100000000000
      min_idx = 0
      _.each thrown, (seed, idx)->
        distance = seed.bounds.center.getDistance(last_pt)
        if distance < min_dis
          min_dis = distance
          min_idx = idx

      return remove_from_candidates(min_idx)

    idx = 0
    count = 0
    seed = thrown[0]
    while thrown.length > 0 and count < 100
      seed = greedy_candidate_selection(seed.bounds.center)
      seedling.call(this, thread, seed)
      count += 1
    return thread


  frenchknotseedling: (thread, seed)->
    scope = this
    random_axis = Math.random() * seed.length
    axis = new paper.Path.Line
      from: seed.getPointAt(random_axis)
      to: seed.getPointAt((random_axis+(seed.length/2))%seed.length)
      strokeColor: "red"
      strokeWidth: 1
      visible: false
      

      pt = seed.bounds.center  
      thread.stitch(pt.x, pt.y, false, false)

      topStitch = thread.passThrough()
      pt = seed.bounds.center  
      thread.stitch(pt.x, pt.y, false, false)

      c = seed.expand
        joinType: "round"
        strokeAlignment: "exterior"
        strokeWidth: 1
        strokeColor: "yellow"
        strokeOffset: -2
        exterior: 1
        z_index: 0
        visible: false
      c2 = seed.expand
        joinType: "round"
        strokeAlignment: "exterior"
        strokeWidth: 1
        strokeColor: "yellow"
        strokeOffset: -5
        exterior: 1
        z_index: 0
        visible: false


      _.each _.range(0, c2.length*0.9), (offset)->
        pt = c2.getPointAt(offset)
        thread.stitch(pt.x, pt.y, false, false)

      thread.under(topStitch)
      scope.fdd(thread, 2, 1,  false)
      thread.return()
      scope.right(thread, 3,  false)

      thread.under(topStitch)
      pt = seed.bounds.center  
      thread.stitch(pt.x, pt.y, false, false)
      thread.passThrough()

    seed.remove()
  seedling: (thread, seed)->
    random_axis = Math.random() * seed.length
    axis = new paper.Path.Line
      from: seed.getPointAt(random_axis)
      to: seed.getPointAt((random_axis+(seed.length/2))%seed.length)
      strokeColor: "red"
      strokeWidth: 1
      visible: false

    lines = this.plot_lines
      axis: axis
      boundary: seed
      crossings: 3
      color: "red"
      visible: false

    pts = _.map lines, (l)-> [l.getPointAt(0), l.getPointAt(l.length)]
    pts = _.flatten(pts)
  
    axis.remove()
    _.each lines, (l)-> l.remove()
    _.each pts, (pt)->        
      thread.stitch(pt.x, pt.y, false, false)
      thread.passThrough()

    seed.remove()

  star: (f, idx)->

    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    # thread.passThrough()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary
    star_radius = boundary.bounds.width/2
    inner_length = 5
    circuit_gap_length = 5

    pointify = (circle)->
      step = circle.length/8
      _.map _.range(0, circle.length, step), (x)->
        pt = circle.getPointAt(x)
        stitch.canvas.makeGridPoint(pt)
        pt
    
    c = boundary.expand
      joinType: "round"
      strokeAlignment: "exterior"
      strokeWidth: 1
      strokeColor: "yellow"
      strokeOffset: 0
      exterior: 1
      z_index: 0
      visible: false
    out_pts = pointify(c)

    
    c = c.expand
      joinType: "round"
      strokeAlignment: "exterior"
      strokeWidth: 1
      strokeColor: "yellow"
      strokeOffset: -(star_radius - inner_length)
      exterior: 1
      z_index: 0
      visible: false
    c.rotate(45*5)
    mid_pts = pointify(c)
    c = c.expand
      joinType: "round"
      strokeAlignment: "exterior"
      strokeWidth: 1
      strokeColor: "orange"
      strokeOffset: -(star_radius - inner_length - circuit_gap_length)
      exterior: 1
      z_index: 0
      visible: false
    c.rotate(45*4)
    in_pts = pointify(c)

    # console.log out_pts, in_pts
   
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


    return thread

  herringbone: (f, idx)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    thread.passThrough()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary

    lines = scope.plot_lines
      axis: guides.axis
      boundary: guides.boundary
      crossings: 4
      # color: 'green'
      # visible: false
    cross_width = 10


    step_up_and_down = (pt, step)->
      loc = boundary.getNearestLocation(pt)
      step_plus = loc.offset + (step/2)
      step_minus = loc.offset - (step/2)
      if step_plus > boundary.length
        step_plus = step_plus - boundary.length
      if step_minus < 0
        step_minus = boundary.length + step_minus
      pt_a = boundary.getPointAt(step_plus)
      pt_b = boundary.getPointAt(step_minus)
      return [pt_a, pt_b]

    rows = _.map lines, (l, i)->
      a = step_up_and_down(l.firstSegment.point, step=cross_width)
      b = step_up_and_down(l.lastSegment.point, step=cross_width).reverse()
      return _.flatten([a, b])

    _.each rows, (row, i)->
      _.each row, (pt)->
        console.log pt
        thread.stitch(pt.x, pt.y, false, false)
        thread.passThrough()
    return thread


  daisy: (f, idx)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    
    
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary

    petal_count = 6
    lock_stitch_length = 10
    petal_width = 15
    petals = _.range(0, boundary.length, boundary.length/petal_count)
    # petals = petals.slice(0, 5)

    
    # Wrap around point
    triangles =_.map petals, (p)->
      petal = new paper.Path.Circle
        radius: 5
        position: boundary.getPointAt(p).clone()
        # fillColor: "white"
        strokeWidth: 2
      petal.sendToBack()
      out = boundary.getPointAt(p)
      n = boundary.getNormalAt(p)
      n.length = 5
      out = out.add(n)
      
      minus = p-petal_width
      plus = p+petal_width
      if plus > boundary.length
        plus = plus - boundary.length
      if minus < 0
        minus = boundary.length + minus

      return [boundary.bounds.center, boundary.getPointAt(minus), out.clone(), boundary.getPointAt(plus), boundary.bounds.center.clone()]

    # Lock the petal
    lock_stitch =_.map petals, (p)->
      out = boundary.getPointAt(p)
      n1 = boundary.getNormalAt(p)
      n2 = boundary.getNormalAt(p)
      n1.length = -lock_stitch_length/3
      n2.length = lock_stitch_length/3*2
      a = out.add(n1)
      b = out.add(n2)
      return [a, b]
    thread.passThrough()
    pt = boundary.bounds.center.clone()
    thread.stitch(pt.x, pt.y, false, false)
    thread.passThrough()

    # pt = boundary.bounds.center.clone()
    # thread.stitch(pt.x, pt.y, false, false)
    # thread.passThrough()
    # pt = boundary.bounds.topRight.clone()
    # thread.stitch(pt.x, pt.y, false, false)
    # thread.passThrough()
    # pt = boundary.bounds.bottomRight.clone()
    # thread.stitch(pt.x, pt.y, false, false)
    # thread.passThrough()
    # thread.selected = true

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
    thread.pull_all_segments()

    return thread

  chain: (f, idx)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    thread.passThrough()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary

    stitch_length = 8
    chain_length = 12
    chain_width = 3
    offsets = _.range(0, boundary.length, stitch_length)
    _.each offsets, (offset, i, arr)->

      midpoint = offset+(chain_length/3*2)
      end = offset+chain_length
      next = offset+stitch_length
      if next > boundary.length
        return
      if end >= boundary.length 
        end = boundary.length
      start = boundary.getPointAt(offset)
      normal = boundary.getNormalAt(midpoint)
      normal.length = chain_width
      left = boundary.getPointAt(midpoint).add(normal)
      right = boundary.getPointAt(midpoint).add(normal.multiply(-1))
      end = boundary.getPointAt(end)
      next = boundary.getPointAt(next)

      thread.stitch(start.x, start.y, false, false)
      thread.stitch(left.x, left.y, false, false)
      thread.stitch(end.x, end.y, false, false)
      thread.stitch(right.x, right.y, false, false)
      thread.stitch(start.x, start.y, false, false)
      thread.passThrough()
      thread.stitch(next.x, next.y, false, false)
      thread.passThrough()

    return thread


  running: (f, idx)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    thread.passThrough()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary

    l = boundary
    stitch_length = 5
    
    offsets = _.range(0, l.length+1, stitch_length)
    _.each offsets, (offset, i)->
      pt = l.getPointAt(offset)
      thread.stitch(pt.x, pt.y, false, false)
      thread.passThrough()
    # l.remove()
    return thread
  stem: (f, idx)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    thread.passThrough()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary

    l = boundary
    stitch_length = 12
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
    # l.remove()
    return thread
  cross: (f, idx)->
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    pts = this.plot_points_cross
      axis: axis
      boundary: boundary
      row_height: Ruler.mm2pts(4.9)
      column_width: Ruler.mm2pts(4.9)
  
    thread = stitch.threadkeeper.knotAndBegin()
    
    thread.passThrough()
      
    _.each pts, (row, j)->
      if j%2 == 0
        row.reverse()
        pt = row[0]

        thread.stitch(pt[0].x, pt[0].y, false, false)  
        if j > 0   
          thread.passThrough()

        _.each row, (pt, i, arr)->
          if i < arr.length - 1
            pt2 = arr[i+1]
            thread.stitch(pt2[1].x, pt[1].y, false, false)
            thread.passThrough()
            thread.stitch(pt2[0].x, pt[0].y, false, false)
            thread.passThrough()
        _.each row.reverse(), (pt, i, arr)->
          if i < arr.length - 1
            pt2 = arr[i+1]
            thread.stitch(pt[0].x, pt[0].y, false, false)
            thread.stitch(pt2[1].x, pt[1].y, false, false)
            thread.passThrough()
            if i != arr.length - 2
              thread.stitch(pt2[0].x, pt[0].y, false, false)
              thread.passThrough()
      else
        # thread.passThrough()
        row.reverse()
        pt = row[0]
        thread.stitch(pt[1].x, pt[1].y, false, false)
        thread.passThrough()

        _.each row, (pt, i, arr)->
          if i < arr.length - 1
            pt2 = arr[i+1]
            thread.stitch(pt2[0].x, pt[0].y, false, false)
            thread.passThrough()
            thread.stitch(pt2[1].x, pt[1].y, false, false)
            thread.passThrough()
        _.each row.reverse(), (pt, i, arr)->
          if i < arr.length - 1
            pt2 = arr[i+1]
            thread.stitch(pt[1].x, pt[1].y, false, false)
            thread.stitch(pt2[0].x, pt[0].y, false, false)
            thread.passThrough()
            if i != arr.length - 2
              thread.stitch(pt2[1].x, pt[1].y, false, false)
              thread.passThrough()

    return thread

  
  plot_points_cross: (ops)->
    # ADD NEW TRACE
    scope = this
    boundary =  new paper.Path.Rectangle
      rectangle: ops.boundary.bounds
      name: "boundary"
      strokeColor: "blue"
      strokeWidth: 2
      z_index: 0
    ops.boundary.remove()
    ops.boundary = boundary
    guides = scope.prepare_guides(ops)
    axis = guides.axis
    pts = _.map _.range(0, axis.length-ops.row_height, ops.row_height), (offset)->
      normalA = axis.getNormalAt(offset)
      normalA.length = 1000
      normalB = axis.getNormalAt(offset)
      normalB.length = -1000
      c = new paper.Path.Line
        name: "c"
        from: axis.getPointAt(offset).add(normalA)
        to: axis.getPointAt(offset).add(normalB)
        strokeColor: "green"
        strokeWidth: 1
        visible: false
        z_index: 1
      c2 = new paper.Path.Line
        name: "c"
        from: axis.getPointAt(offset+ops.row_height).add(normalA)
        to: axis.getPointAt(offset+ops.row_height).add(normalB)
        strokeColor: "blue"
        strokeWidth: 1
        visible: false
        z_index: 1
      c = scope.cullLine(c, boundary)
      c2 = scope.cullLine(c2, boundary)
      y_range = _.range(0, c.length, ops.column_width)
      pts = _.map y_range, (x)-> [c.getPointAt(x), c2.getPointAt(x)]
      return pts
      

  satin: (f, idx)->
    scope = this
    thread = stitch.threadkeeper.knotAndBegin()
    # thread.passThrough()
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    guides = scope.prepare_guides
      axis: axis
      boundary: boundary
    
    lines = scope.plot_lines
      boundary: guides.boundary
      axis: guides.axis
      crossings: 30
    pts = _.map lines, (l)-> [l.firstSegment.point, l.lastSegment.point]
    pts = _.flatten pts
    pts.unshift(pts[1])
    _.each pts, (pt)->
      thread.stitch(pt.x, pt.y, false, false)
      thread.passThrough()
    return thread

  plot_points_satin: (ops)->
    scope = this
    guides = scope.prepare_guides(ops)
    axis = guides.axis
    boundary = guides.boundary
    
    step = axis.length/ops.stem_density
    offsets = _.range(step, axis.length+step, step)

    pts = _.map offsets, (offset, idx)->
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
      pts = _.map ixts, "point"
      c.remove()
      return pts
    return _.compact _.flatten(pts), pts
      
   

  serpentine: (f, idx)->
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"
    pts = this.plot_points_serpentine
      stem_density: 14 # number of times stitch crosses stem
      boundary: boundary
      axis: axis
    thread = stitch.threadkeeper.knotAndBegin()
   
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
    return thread

  fly: (f, idx)->
    axis = f.getItem
      name: "axis"
    boundary = f.getItem
      name: "boundary"

    pts = this.plot_points
      stem_density: 12 # number of times stitch crosses stem
      lock_stitch_length: 2 # at least 4
      pull_distance: 3 # at least 10
      v_acuteness: 20
      boundary: boundary
      axis: axis
    thread = stitch.threadkeeper.knotAndBegin()
    pt = boundary.getPointAt(0)
    thread.stitch(pt.x, pt.y, false, false)
    pt = axis.getPointAt(10)
    thread.passThrough()
    thread.stitch(pt.x, pt.y, false, false)

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
    return thread

  plot_lines: (ops)->
    scope = this
    defaults = 
      visible: true
      color: "blue"
    ops = _.extend defaults, ops
    guides = scope.prepare_guides(ops)
    axis = guides.axis
    boundary = guides.boundary

    step = (axis.length)/(ops.crossings+1)
    offsets = _.range(step, axis.length, step)

    lines = _.map offsets, (offset, idx)->
      if ops.v_acuteness
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
        strokeColor: ops.color
        strokeWidth: 1
        visible: false #ops.visible
        z_index: 1
      ixts = c.getIntersections(boundary)
      c.segments = _.map ixts, "point"
      return c
   
    return lines
  plot_points_serpentine: (ops)->
    scope = this
    guides = scope.prepare_guides(ops)
    axis = guides.axis
    boundary = guides.boundary

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
      c.remove()
      return pts
    pts = _.compact pts, pts
    return pts

  plot_points: (ops)->
    scope = this
    guides = scope.prepare_guides(ops)
    axis = guides.axis
    boundary = guides.boundary

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
