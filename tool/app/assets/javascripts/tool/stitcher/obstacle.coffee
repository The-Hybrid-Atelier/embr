class stitcher.Obstacle
  constructor: (x, y, visual_size=3, virtual_size=7, from_center=false)->
    point = new paper.Point(x, y)
    if from_center
      point = paper.view.center.add(point)
    # console.log "OBSTACLE AT", point.x, point.y

    this.virtual = new paper.Path.Circle
        name: "obstacle"
        radius: virtual_size
        position: point
    this.visual = new paper.Path.Circle
      name: "obstacle_visual"
      radius: visual_size
      position: point
      fillColor: "red"
      strokeColor: "orange"
      strokeWidth: 1
    this.a = new paper.Path.Line
      name: "obstacle_visual"
      from: this.visual.bounds.expand(-1).bottomLeft
      to: this.visual.bounds.expand(-1).topRight
      strokeColor: "orange"
    this.b = new paper.Path.Line
      name: "obstacle_visual"
      from: this.visual.bounds.expand(-1).bottomRight
      to: this.visual.bounds.expand(-1).topLeft
      strokeColor: "orange"

  @clearAll: ()->
    obstacles = paper.project.getItems
      name: "obstacle"
    obstacles2 = paper.project.getItems
      name: "obstacle_visual"
    obstacles = _.union(obstacles, obstacles2)
    _.each obstacles, (o)-> o.remove()