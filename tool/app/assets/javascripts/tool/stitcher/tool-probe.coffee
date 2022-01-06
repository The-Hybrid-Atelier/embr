class stitcher.ProbeTool extends EmbrTool
  name: "probeTool"
  cssClassName: "probe-only"
  hitOptions:
    stroke: true
    tolerance: 3
  panning: false   
  minDistance: 5
  constructor: (ops)->
    super(ops)
    scope = this
  onLoad: ()->
    super()
    $(document).unbind "panstart pandrag panend"
    $(document).on "panstart pandrag panend", (e, paperevent)->
      # console.log e.type, paperevent.delta
      switch e.type
        when "pandrag"
          pan_offset = paperevent.point.subtract(paperevent.downPoint);
          paper.view.center = paper.view.center.subtract(pan_offset);
  
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
    thread = stitch.threadkeeper.current_thread
    hitResults = paper.project.hitTestAll event.point, this.hitOptions
    
    if hitResults.length == 0
      $(document).trigger("panstart", event)
      this.panning = true

    hits = _.map hitResults, (hit)-> return scope.isTrace(hit.item)
    hits = _.compact hits
    hits = _.uniq hits, false, "id"

    if event.modifiers.shift or stitch.shift
      thread.select_all()
      $(document).trigger("select", thread)
    else
      if hits.length > 0
        s = new stitcher.Segment(thread.walk(hits[0], 0))
        thread.select(s)
        $(document).trigger("select", s)
  onMouseDrag: (event)->
    multitouch = this.isMultitouch(event)
    if this.panning and not multitouch
      $(document).trigger('pandrag', event)
    else if this.panning and multitouch
      this.panning = false
    
    if this.pinching and multitouch
      event.type = "pinchdrag"
      this.onPinchDrag(event, event.event.touches)
    else if not this.pinching and multitouch
      event.type = "pinchstart"
      this.onPinchStart(event, event.event.touches)
      this.pinching = true
  onMouseUp: (event)->
    if this.pinching 
      this.pinching = false
      event.type = "pinchend"
      this.onPinchEnd(event, event.event.touches)
    if this.panning
      $(document).trigger('panend', event)
      this.panning = false
    thread = stitch.threadkeeper.current_thread
    thread.clear_selection()
    paper.project.deselectAll()