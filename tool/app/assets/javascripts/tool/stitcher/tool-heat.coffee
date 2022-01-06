class stitcher.HeatTool extends EmbrTool
  name: "heatTool"
  cssClassName: "heat-only"
  hitOptions:
    stroke: true
    tolerance: 3
  panning: false   
  minDistance: 5
  constructor: (ops)->
    super(ops)
    scope = this
  onLoad: ()->
    scope = this
    super()
    $(document).unbind "panstart pandrag panend"
    $(document).on "panstart pandrag panend", (e, paperevent)->
      # console.log e.type, paperevent.delta
      switch e.type
        when "pandrag"
          pan_offset = paperevent.point.subtract(paperevent.downPoint);
          paper.view.center = paper.view.center.subtract(pan_offset);
    scope.keybindings()
  keybindings: ()->
    scope = this
    # TOOL BINDINGS
    $(".actions .app.button[data-click]").unbind()
    $(".actions .app.button[data-click]").click (event)->
      action = $(this).data('click')
      $(document).trigger(action)
  touchCentroid: (touches)->
    pts = _.map touches, (touch)->
      touchPosition = new paper.Point(touch.clientX, touch.clientY)
      return paper.view.viewToProject(touchPosition);
    
    touchPath = new paper.Path
      strokeColor: "red"
      strokeWidth: 3
      segments: pts

    resp = 
      length: touchPath.length
      centroid: touchPath.bounds.center
    touchPath.remove()
    return resp
  
  onPinchStart: (event, touches)->
    resp = this.touchCentroid(touches)
    this.pinchstartlength = resp.length
    this.pinchlastlength = resp.length
  onPinchDrag: (event, touches)->
    resp = this.touchCentroid(touches)
    absDelta = resp.length - this.pinchstartlength
    currentDelta = resp.length - this.pinchlastlength
    console.log absDelta, currentDelta
    
    factor = if currentDelta > 0 then 1+this.ZOOM_FACTOR else 1-this.ZOOM_FACTOR
    beta = zoom(factor, resp.centroid)
    this.pinchlastlength = resp.length * beta
  
  onPinchEnd: (event, touches)->
    console.log event.type
  onMouseDown: (event)->
    scope = this

  onMouseDrag: (event)->
    if event.point.subtract(event.downPoint).length > 10
      if this.selection
        this.selection.remove()
      this.selection = new paper.Path.Rectangle
        fillColor: new paper.Color(0, 0, 1, 0.5)
        from: event.downPoint
        to: event.point

  onMouseUp: (event)->
    if this.selection
      stitch.canvas.generate_heat_grid(this.selection, this.selection.bounds, 3, 3)
      this.selection.remove()