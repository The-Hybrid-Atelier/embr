class stitcher.StitchTool extends EmbrTool
  name: "stitchTool"   
  cssClassName: "stitch-only"
  mouse_shift: false 
  hitOptions: 
    stroke: true
    tolerance: 3

  constructor: (ops)->
    super(ops)
  
  onLoad: ()->
    super()
    $(document).unbind "mouse_shift_start mouse_shift_drag mouse_shift_end"
    $(document).on "mouse_shift_start", (event)->
      thread = stitch.threadkeeper.current_thread
      last_trace = thread.tail
      thread.under(last_trace)
      stitch.canvas.renderZ()
    $(document).on "mouse_shift_end", (event)->
      thread = stitch.threadkeeper.current_thread
      last_trace = thread.tail
      thread.return()
      stitch.canvas.renderZ()

    $(document).on "mouse_shift_drag", (event)->
      # HIT DETECT FOR GOING UNDER
      trace = stitch.threadkeeper.current_thread.tail
      hits = trace.hits()
      # _.each(hits, (h)-> h.threadPath.strokeColor.lightness += 0.01)
      # console.log event.type, hits.length

      if hits.length > 0
        # zs = _.map(hits, (hit)-> Math.abs(hit.z_index))
        z_neighbor = _.min(hits, (hit)-> Math.abs(hit.z_index))
        z_under = Math.abs(z_neighbor.z_index)-0.1
        if trace.side == "over" 
          trace.z_index = z_under
          trace.insertBelow(z_neighbor)
        
        else
          z_under = z_under*-1
          trace.z_index = z_under
          trace.insertAbove(z_neighbor)
        # console.log 'NEW Z', z_neighbor.z_index, z_under
        
        stitch.canvas.renderZ()
  onMouseDown: (event)->
    # console.log "STITCH DOWN"
    if event.modifiers.command
      console.log "SELECT"
      hitResults = paper.project.hitTestAll event.point, this.hitOptions
      hitResults = _.filter hitResults, (result)->
        return result.item.parent.name == "trace"
      hitResults = _.map hitResults, (result)->
        return result.item.parent
      hitResults = _.unique hitResults, false, (trace)->
        return trace.id
      _.each hitResults, (result)->
        result.selected = true
      console.log hitResults, _.isEmpty(hitResults)

      if _.isEmpty(hitResults)
        paper.project.deselectAll()
      return


    thread = stitch.threadkeeper.current_thread      
    thread.stitch(event.point.x, event.point.y, true, false)

  onMouseDrag: (event)->
    if (event.modifiers.shift or stitch.shift) and not this.mouse_shift
      this.mouse_shift = true
      $(document).trigger "mouse_shift_start"

    thread = stitch.threadkeeper.current_thread
    thread.stitch(event.point.x, event.point.y, false, false)

    if event.modifiers.shift or stitch.shift
      $(document).trigger('mouse_shift_drag')

  onMouseUp: (event)->
    if event.modifiers.command
      return
    thread = stitch.threadkeeper.current_thread
    trace = stitch.threadkeeper.current_thread.tail

    if trace
      if event.delta.length < 5
        console.log "SAME SPOT"
        trace.removeSegment()
      thread.stitch(event.point.x, event.point.y, true, false)
      trace.simplify()
      thread.passThrough()

    # z_index = if this.trace.z_index == 0 then 1 else 0
    # this.trace = new stitcher.Trace
    #   z_index: z_index
    #   previousTrace: this.previousTrace
    # console.log "UP"

  onKeyUp: (event)->
    if not event.modifiers.shift or stitch.shift
      $(document).trigger "end_shift"
      
      if this.mouse_shift
        $(document).trigger "mouse_shift_end"
        this.mouse_shift = false
    $(document).trigger "paperkeyup", [event.key, event.modifiers, []]
        
  onKeyDown: (event) ->
    paths = paper.project.selectedItems
    
    if event.modifiers.shift or stitch.shift
      $(document).trigger "start_shift"
      
    $(document).trigger "paperkeydown", [event.key, event.modifiers, paths]
