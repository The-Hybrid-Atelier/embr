class stitcher.RainbowFishSketch extends stitcher.SVGSketch
  constructor: (ops)->
    if not ops
      ops = 
        name: "RainbowFish"
    super ops
  procedure: ()->
    console.log "loading", "/designs/rainbow-fish.svg"
    @addSVG
      url: "/designs/rainbow-fish.svg"
      position: stitch.canvas.center()
    return
  onLoad: ()->
    stitch.canvas.grid_pts(false)
    scope = this
    thread = this.clearCanvasAndBegin()
    thread.passThrough()
    scope.design.scaling = new paper.Size(2, 2)
    scope.design.sendToBack()

    f = scope.design.getItem
      className: "Group"
      name: "flystitch"
    axes = f.getItems
      name: "axis"
    curves = f.getItems
      name: "boundary_curve"
    curves.reverse()
    console.log _.map f.children, "name"
    console.log axes, curves

    grid = new Array(curves.length)
    grid = _.map grid, (g)-> new Array(axes.length)

    
    grid = _.map grid, (g, i, arr)->
      curve = curves[i]
      ixts = _.map g, (x, j)-> 
        axis = axes[j]
        ixts = curve.getIntersections(axis)
        _.each ixts, (ixt)->
          stitch.canvas.makeGridPoint(ixt.point, true)
          
        return ixts[0]

      pts =_.map ixts, (ixt, i, arr)->
        if i < arr.length - 1
          pt = ixt.path.getPointAt((ixt.offset + arr[i+1].offset)/2)
          pt2 = ixt.path.getPointAt(ixt.offset+5)
          stitch.canvas.makeGridPoint(pt, false)
          stitch.canvas.makeGridPoint(pt2, false)
          ixt.point.tname = 'start'
          pt2.tname = 'jump'
          pt.tname = 'down'
          return [ixt.point, pt2, pt]
        if i == arr.length-1
          pt2 = ixt.path.getPointAt(ixt.offset+5)
          ixt.point.tname = 'start'
          pt2.tname = 'jump'
          return [ixt.point, pt2]
      pts = _.compact(_.flatten(pts))
      pts
    _.each curves, (c)-> c.visible = false
    _.each axes, (c)-> c.visible = false


    thread.stitch(grid[0][0].x, grid[0][0].y, false, false)
    thread.passThrough()
    grid = _.each grid, (g, i, arr)->
      if i < 6
        if i % 2 == 1
          grid[i+1].reverse()
          g.reverse()
          thread.passThrough()
        if i % 2 == 0 and i > 0
          g.reverse()
          thread.passThrough()
        _.each g, (pt, j)->
          if i%2==0
            console.log "HERE"
            switch j%3
              when 0
                thread.stitch(pt.x, pt.y, false, false)
                if j > 0
                  thread.passThrough()
                
                console.log pt.tname, j%4

              when 1
                thread.stitch(pt.x, pt.y, false, false)
                thread.passThrough()
                console.log pt.tname, j%4

              when 2
                pt2 = arr[i+1][j]
                thread.stitch(pt2.x, pt2.y, false, false)
                console.log pt.tname, j%4
          else
            j = j-1
            pt2 = arr[i+1][j+1]
           
            console.log "ODD"
            if j < 3
              switch j%3
                when 0
                  thread.stitch(pt.x, pt.y, false, false)
                when 1
                  thread.stitch(pt.x, pt.y, false, false)
                  thread.passThrough()
                when 2
                  thread.stitch(pt2.x, pt2.y, false, false)
            else
              switch j%3
                when 0
                  # thread.stitch(pt.x, pt.y, false, false)
                  # thread.passThrough()
                  console.log "SKIP"
                when 1
                  thread.stitch(pt.x, pt.y, false, false)
                  thread.passThrough()
                  thread.stitch(pt.x, pt.y, false, false)
                  thread.passThrough()
                when 2
                  pt = arr[i+1][j+2]
                  thread.stitch(pt.x, pt.y, false, false)
                  thread.passThrough()
                  thread.stitch(pt.x, pt.y, false, false)
                  thread.passThrough()
              
              
              
