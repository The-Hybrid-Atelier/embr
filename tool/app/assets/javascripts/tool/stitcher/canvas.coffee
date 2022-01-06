class stitcher.Canvas extends paper.Group
  @GRID_STEP: 15
  @HEAT_STEP: 15/2
  @LOOP_RADIUS: 6 #inches
  @FABRIC_FACTOR: 0.1 # the lower, the thicker the fabric
  constructor: (ops)->
    super ops
    this.render()
    this.name = "canvas"#'', ,
    this.liquid_crystal = chroma.scale(['#252122', '#732E2A', '#949553', '#949553','#3D9145', '#3D9145','#0079AD', '#0079AD', "#2D41AD"]).mode('lch').colors(200)

    paper.view.translate(new paper.Point(0, -10))
    paper.view.zoom = 1.5
    this.view_mode = "top"
    this.generator_cells = null
  grid_pts: (visible=true)->
    gps = paper.project.getItems
      name: "grid_point" 
    _.each gps, (gp)-> gp.visible = visible
  flip: ()->
    switch this.view_mode
      when "top"
        this.view_mode = "bottom"
      when "bottom"
        this.view_mode = "top"

    this.renderZ()
  set_view: (view)->
    this.view_mode = view
    this.renderZ()
  resolveErrors: ()->
    traces = paper.project.getItems
      name: "trace"
      z_index: (item)-> 
        not _.isUndefined(item)
    _.each traces, (t)->
      
      t.colorize("red")
  steps: 0
  
  renderZ: ()->
    traces = paper.project.getItems
      z_index: (item)-> 
        not _.isUndefined(item)
    sorted_traces = _.sortBy traces, "z_index"
    # console.log _.map sorted_traces, "z_index"

    switch this.view_mode
      when "top"
        _.each sorted_traces, (t)-> 
          # console.log t, t.z_index
          t.bringToFront()
      when "bottom"
        _.each sorted_traces, (t)-> t.sendToBack()


    return sorted_traces
  getNearestGridPoint: (pt)->
    npt = this.grid_line.getNearestPoint(pt)
    gpt = this.grid_line.getNearestLocation(npt).segment.point.clone() 
    return gpt
  
  getTopCount: (increment)-> 
    count = this.getCount (z)-> z > 0
    return count + increment

  getBottomCount: (increment)-> 
    count = this.getCount (z)-> z < 0
    return -1 * (count + increment)

  getCount: (criteria)->
    items = paper.project.getItems
      z_index: (z)-> 
        if not _.isUndefined(z)
          return criteria(z)
        else
          return false
    return items.length
  center: ()->
    stitch.canvas.children.fabric.bounds.center
  heat_sim: ()->
    scope = this
    _.each _.range(0, 2), (i)->
      scope.step()
  step: ()->
    scope = this
    heat_grid = paper.project.getItem
      name: "heat_grid"
    if not this.generator_cells
      console.log "RUNNING HEAT SIMULATION"
      traces = paper.project.getItems
        name: "trace"
        inside: heat_grid.bounds
      heat_cells = paper.project.getItems
        name: "heat_cell"
      generator_cells = _.filter heat_cells, (hc, idx)->
        # console.log "HC", idx
        return _.any traces, (t)-> t.threadPath.intersects(hc)
      _.each generator_cells, (gc, i)->
        console.log "COMPUTING HEAT MASS"
        gc.fillColor = "yellow"
        _.each traces, (t)->
          if t.threadPath.intersects(gc)
            fabric_factor = if this.side == "over" then 1 else stitcher.Canvas.FABRIC_FACTOR
            ixts = t.threadPath.getIntersections(gc)
            if ixts.length == 2
              gc.heatMass += fabric_factor * Math.abs(ixts[1].offset - ixts[0].offset) * t.threadPath.strokeWidth
            else
              gc.heatMass += fabric_factor * Math.min(Math.abs(ixts[0].path.length - ixts[0].offset), Math.abs(ixts[0].offset))  * t.threadPath.strokeWidth
                
      _.each generator_cells, (gc, i)->
        if gc.heatMass > 0
          gc.heatDensity = gc.heatMass/gc.area
      this.generator_cells = generator_cells

    console.log("------------------")
    this.steps++
    heated_cells = paper.project.getItems
      name: "heat_cell" 

    heat_gen = _.map this.generator_cells, (gc, i)-> gc.heat(gc.heatDensity)  
    _.each heated_cells, (hc)-> hc.cool()
    _.each heated_cells, (hc)-> hc.transfer()
    lcs = _.map heated_cells, (hc)-> hc.update()
    energy = _.map heated_cells, "temperature"
    average_temp = numeric.sum(energy)/energy.length
    generated_heat = numeric.sum(heat_gen)/heat_gen.length
    console.log "Step statistics", 
      "\n\t i", scope.steps,
      "\n\t generator_cells", this.generator_cells.length, 
      "\n\t heat_generated", generated_heat, 
      "\n\t total_energy", numeric.sum(energy).toFixed(1),
      "\n\t average_temperature", average_temp.toFixed(1),
      "\n\t diff min-max",  _.min(lcs).toFixed(1), _.max(lcs).toFixed(1),

  generate_heat_grid: (boundary, bounds, resolution_x=100, resolution_y=100)->
    canvas = this
    hg = paper.project.getItem
      name: "heat_grid"
    if hg
      hg.remove()
      this.generator_cells = null
    step_x = resolution_x
    step_y = resolution_y
    xx =_.range(0, bounds.width/step_x)
    yy = _.range(0, bounds.height/step_y)
    console.log(xx.length, " x ", yy.length, "--", bounds.width.toFixed(0), " x ", bounds.height.toFixed(0), step_x, step_y)

    grid = new Array(xx.length)
    grid = _.map grid, (row)->
      return new Array(yy.length)
    add_if_in_bounds = (hc, i, j)->
      if i >= 0 and i < xx.length and j >= 0 and j < yy.length
        if grid[i][j]
          hc.neighbors.push(grid[i][j])

    heat_grid = new paper.Group
      name: "heat_grid"
    _.each xx, (x, i)->
      _.each yy, (y, j)->
        
        pt = new paper.Point(x * step_x, y * step_y)
        pt = pt.add(bounds.topLeft)
        r = new paper.Path.Rectangle
          COOL_FACTOR: 0.0 # percent of heat to maintain from cooling
          FLUX_FACTOR: 200
          conductivity: 0.80
          TRANSFER_FACTOR: 0.5# percent of heat to carry over to other cells
          LC_FACTOR: 5
          parent: heat_grid
          name: 'heat_cell'
          size: new paper.Size(step_x*1.1, step_y*1.1)
          position: pt.clone()
          heatMass: 0
          heatDensity: 0
          neighbors: []
          fillColor: new paper.Color(0, 0, 1, 0)
          heat_diff: 0
          temperature: 72
          
          timestep: 1
          visible: boundary.contains(pt)
          # heat_lost_to_neighbors: 0
          # gained_from_neighbors: 0
          heat: (heat_flux)->
            this.heat_diff += heat_flux*this.FLUX_FACTOR
            return heat_flux*this.FLUX_FACTOR
          transfer: ()->
            scope = this
            # heat_transfer = loss/this.neighbors.length
            cooler_neighbors = _.filter(this.neighbors, (n)-> n.temperature < scope.temperature)
            avg_temp = numeric.sum(_.map cooler_neighbors, "temperature")/cooler_neighbors.length
            neigbor_loss = (scope.temperature - avg_temp)* this.conductivity/cooler_neighbors.length
            # neigbor_loss = (scope.temperature - 72) * this.conductivity /cooler_neighbors.length
            
            _.each cooler_neighbors, (n, i, arr)->
              loss = neigbor_loss
              n.heat_diff += loss
              scope.heat_diff -= loss


            # console.log loss, heat_transfer*this.neighbors.length
            return
          cool: ()->
            this.heat_diff -= (this.temperature - 72) * this.COOL_FACTOR
            return
          update: ()-> 
            diff = this.heat_diff * this.timestep
             # - this.heat_lost_to_neighbors + this.gained_from_neighbors  #* this.timestep   
            # console.log "T", diff, this.heat_diff, this.heat_lost_to_neighbors, this.gained_from_neighbors
            this.temperature += diff 
            if this.temperature < 72
              debugger;
            # console.log "T'", this.temperature, this.id 
            this.heat_diff = 0    
            # this.heat_lost_to_neighbors = 0    
            # this.gained_from_neighbors = 0    
            # this.selected = true    
            this.lc(this.temperature)
            return diff

          lc: (temperature)->
            max = 150
            if temperature > 150
              this.fillColor = canvas.liquid_crystal[canvas.liquid_crystal.length-1]
              return
            activation = temperature - 72
            n = canvas.liquid_crystal.length
            idx = activation / (max-72) * n
            idx = parseInt(idx)
            c = canvas.liquid_crystal[idx]   
            this.fillColor = c      

          onMouseDown: (event)->
            # _.each this.neighbors, (n)->
            #   n.fillColor = "yellow"
            # console.log "THERMAL", this.id, this.temperature
            return
          onMouseDrag: (event)->
            this.heat_diff+= 5
            this.update()
          onMouseUp: (event)->

            # _.each this.neighbors, (n)->
            #   n.fillColor = canvas.liquid_crystal[0]
            return
        r.update()
        # console.log i, j
        grid[i][j] = r
    # NEIGHBORS
    _.each xx, (x, i)->
      _.each yy, (y, j)->
        curr = grid[i][j]
        add_if_in_bounds(curr, i+1, j)
        add_if_in_bounds(curr, i-1, j)
        add_if_in_bounds(curr, i, j-1)
        add_if_in_bounds(curr, i+1, j-1)
        add_if_in_bounds(curr, i-1, j-1)
        add_if_in_bounds(curr, i+1, j+1)
        add_if_in_bounds(curr, i, j+1)
        add_if_in_bounds(curr, i-1, j+1)
  makeGridPoint: (pt, major=true)->
    if major
      c = new paper.Path.Circle
        name: "grid_point"
        radius: 0.5
        fillColor: "#666666"
        position: pt.clone()
    else
      c = new paper.Path.Circle
        name: "grid_point"
        radius: 0.5
        fillColor: "#999999"
        position: pt.clone()


  render: ()->
    scope = this
    # ASSUMING CIRCULAR HOOP
    fabric = new paper.Path.Circle
      parent: this
      name: "fabric"
      radius: Ruler.in2pts(stitcher.Canvas.LOOP_RADIUS)
      # fillColor: "#1E1915"
      fillColor: "#F4EEE1"
      # fillColor: "black"
      position: paper.view.center
      opacity: 0.5
      z_index: 0
    
    hoop_width = Ruler.mm2pts(8)
    hoop = new paper.Path.Circle
      parent: this
      name: "hoop"
      radius: Ruler.in2pts(stitcher.Canvas.LOOP_RADIUS)+(hoop_width/2)
      opacity: 1
      strokeWidth: hoop_width
      strokeColor: "#D4C9AC"
      position: paper.view.center
      shadowColor: new paper.Color(0.3)
      shadowBlur: 12
      shadowOffset: new paper.Point(5, 5)
      z_index: 0
      
    # THROW GRID PTS
    xx =_.range(0, fabric.bounds.width+stitcher.Canvas.GRID_STEP, stitcher.Canvas.GRID_STEP)
    yy = _.range(0, fabric.bounds.height+stitcher.Canvas.GRID_STEP, stitcher.Canvas.GRID_STEP)

    # ROW-ORDERED
    grid_pts = []
    _.each yy, (y, i)->
      # xx.reverse()
      _.each xx, (x, j)->
        pt = new paper.Point(x, y)
        grid_pts.push(pt.add(fabric.bounds.topLeft))

    
    
    grid_pts_c = _.map grid_pts, (pt)->
      scope.makeGridPoint(pt)
      
    # MASK GRID POINTS OFF HOOP
    grid_pts_c.unshift(fabric.clone())
    fabric_grid = new paper.Group
      name: "fabric_grid"
      children: grid_pts_c
      clipped: true
      
    # DATA STRUCTURE FOR FINDING CLOSEST GRIDPT
    this.grid_line = new paper.Path
      name: "grid_line"
      segments: grid_pts
      strokeWidth: 1
      strokeColor: "black"
      visible: false
    paper.view.translate(new paper.Point(0, 50))

    # scope.generate_heat_grid(fabric.bounds)