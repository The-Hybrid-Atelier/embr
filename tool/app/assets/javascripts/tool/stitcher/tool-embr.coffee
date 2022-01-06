class window.EmbrTool extends paper.Tool
  name: "embrTool"
  cssClassName: "embr-only"
  ZOOM_FACTOR: 0.10
  constructor: (ops)->
    super(ops)
    return
  onLoad: ()->
    console.log "Loading ...", this.name
    $(".tw:not(."+this.cssClassName+")").hide()
    $(".tw."+this.cssClassName).show()
  isMultitouch: (event)->
    if event and event.event and event.event.touches
      return event.event.touches.length > 1
    else false
  isTrace: (p)->
    if p.name == 'trace' 
      return p
    if p.parent 
      return this.isTrace(p.parent)
    else
      return null
  isThread: (p)->
    # debugger;
    if p.name == 'thread' 
      return p
    else if p.thread
      return this.isThread(p.thread)
    else if p.parent
      return this.isThread(p.parent)
    else
      return null