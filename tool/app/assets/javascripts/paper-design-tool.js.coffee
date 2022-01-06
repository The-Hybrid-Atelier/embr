
class window.PaperDesignTool
  constructor: (ops)->
    # super ops
    console.log "✓ Paperjs Functionality"
    this.name = "embr_design"
    
    @setup(ops)

  setup: (ops)->
    canvas = ops.canvas[0]
    console.log $('#sandbox').height()
    $(canvas)
      .attr('width', $("#sandbox").width())
      .attr('height', $("#sandbox").height())
    window.paper = new paper.PaperScope
    loadCustomLibraries()
    paper.setup canvas
    paper.view.zoom = 2.5
    paper.tool = new paper.Tool
      name: "default_tool"
      
    $(canvas)
      .attr('width', $("#sandbox").width())
      .attr('height', $("#sandbox").height())
    @toolEvents()
  toolEvents: ()-> 
    return
  
  save_svg: ()->
    prev = paper.view.zoom;
    console.log("Exporting file as SVG");
    paper.view.zoom = 1;
    paper.view.update();
    bg = paper.project.getItems({"name": "BACKGROUND"})


    g = new paper.Group
      name: "temp"
      children: paper.project.getItems
        className: (x)-> _.includes(["Path", "CompoundPath"], x)
    
    g.pivot = g.bounds.topLeft
    prior = g.position
    g.position = new paper.Point(0, 0)

    if bg.length > 0
      exp = paper.project.exportSVG
        bounds: g.bounds
        asString: true,
        precision: 5
    else
      exp = paper.project.exportSVG
        asString: true,
        precision: 5

    g.position = prior
    g.ungroup()
    saveAs(new Blob([exp], {type:"application/svg+xml"}), @name + ".svg")
    paper.view.zoom = prev
  clear: ->
    paper.project.clear()

###
Direct Manipulation Interactions
###
window.dm = (p)->
  p.set
    onMouseDown: (e)->
      this.touched = true
      this.selected = not this.selected
      this.update_dimensions()
      
    update_dimensions: (e)->
      if dim
        if this.data and this.data.height
          z = this.data.height
        else
          z = 0
        dim.set(this.bounds.height, this.bounds.width, z)
      return
    onMouseDrag: (e)->
        this.position = this.position.add(e.delta)
    onMouseUp: (e)->
      return
    clone_wire: ()->
      x = dm(this.clone())
      x.name = this.name
      return x
  return p
