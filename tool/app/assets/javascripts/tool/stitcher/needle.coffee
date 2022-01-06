class window.NeedleTool extends PaperDesignTool
  ### 
  To inherit parent class functionality, super ops must be the first line.
  This class hosts the logic for taking SVG Paths and interpreting them as wires.
  ###
  
  constructor: (ops)->
    super ops
    console.log "✓ Stitching Tool Functionality"
    # @test_addSVG()
    @keybindings()
    @actions()
    window.stitch = this
    this.canvas = new stitcher.Canvas()
    
    
    this.threadkeeper = new stitcher.ThreadKeeper()
    thread = stitch.threadkeeper.knotAndBegin()

    # thread.passThrough()

    # Load debugging sketches
    # sd = new stitcher.ObstacleResolutionDebuggingSketch()
    # sd = new stitcher.SerpentineStitchSketch()
    # sd = new stitcher.FlyStitchSketch()
    # sd = new stitcher.DaisyStitchSketch()
    # sd = new stitcher.FeatherStitchSketch()
    # sd = new stitcher.SimulationDebuggingSketch()
    # this.tool.activate()

  actions: ()->
    $(document).on "undo", {}, (event)->
      thread = stitch.threadkeeper.current_thread
      thread.go_back()
  keybindings: ()->
    scope = this
    # TOOL BINDINGS
    $(".actions .app.button[data-click]").click (event)->
      action = $(this).data('click')
      $(document).trigger(action)

    $(".actions .app.button[data-mousedown]").on "mousedown touchstart", (event)->
      action = $(this).data('mousedown')
      stitch.shift = true

    $(".actions .app.button[data-mouseup]").on "mouseup touchend", (event)->
      action = $(this).data('mouseup')
      stitch.shift = false

    $(".tools .app.button").click (event)->
      console.log $(this).data('tool')
      name = $(this).data('tool')
      tools = _.filter paper.tools, (tool)-> return tool.name == name
      if tools.length == 0
        console.error "TOOL NOT FOUND:", name
      else
        console.log "ACTIVATING", name
        tools[0].activate()
        tools[0].onLoad()
      $(this).addClass('active').siblings().removeClass('active')

    $(".tools .app.button.default").click()

    # STITCHER KEYBINDINGS


    $(document).on "paperkeydown", {}, (event, key, modifiers, paths)->
      # console.log(event, key, modifiers)

      thread = stitch.threadkeeper.current_thread

      # last_segment = stitch.threadkeeper.lastSegment()
      # last_trace = stitch.threadkeeper.lastTrace()
      selectedItems = paper.project.getSelectedItems()
      selectedTraces = _.filter selectedItems, (x)-> x.name == "trace"

      switch key
        when 'space'        
          if modifiers.shift or stitch.shift
            console.log "GLOBAL PULL"
            thread.pull_all_segments()
          else
            console.log "PULLING"
            segment = thread.current()
            segment.pull(true)
        when 'f'
          stitch.canvas.flip()
        when 'd'
          segment = new stitcher.Segment(thread.walk(thread.select_position, 0))
          segment.fade()
          segment.show()
        when 'backspace'
          $(document).trigger("undo")
          
        when 'r'
          thread.select_position = thread.tail
        when 'x'
          thread.plot_last_segment()
        when 'left'
          if modifiers.shift or stitch.shift
            thread.fade_left()
          else
            thread.select_left()
        when 'right'
          if modifiers.shift or stitch.shift
            thread.fade_right()
          else
            thread.select_right()

      return
  ###
  Binds hotkeys to wire operations. 
  Overrides default tool events from PaperDesignTool.
  ###
  toolEvents: ()->
    stitch = new stitcher.StitchTool()
    probe = new stitcher.ProbeTool()
    make = new stitcher.MakeTool()
    heat = new stitcher.HeatTool()
    
  
  
