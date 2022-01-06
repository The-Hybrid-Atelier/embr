window.stitcher = {}
stitcher.ANIMATION_SPEED = 0.05 #
stitcher.THREAD_RESISTIVITY = 7.2/100 # Ω/mm

stitcher.getTrace = (id)->
  return paper.project.getItem
    id: id
window.zoom = (factor, viewPosition)->
  newZoom = paper.view.zoom * factor
  oldZoom = paper.view.zoom
  beta = oldZoom/newZoom    
  mpos = viewPosition
  ctr = paper.view.center
  pc = mpos.subtract(ctr)
  offset = mpos.subtract(pc.multiply(beta)).subtract(ctr)

  paper.view.zoom = newZoom
  paper.view.center = paper.view.center.add(offset)
  paper.view.draw()
  return beta

class stitcher.Collection
  constructor: (ops)->
    this.root = null
    this.tail = null
  remove_last: ()->
    this.remove(this.tail)
  last: ()->
    return this.tail
  is_root: (member)->
    return _.isNull member.prev
  is_tail: (member)->
    return _.isNull member.next
  is_connected: (member)->
    return _.isNull member.next and _.isNull member.prev
  add: (member)->
    member.collection = this
    # FIRST NODE
    if not this.root
      this.root = member
      member.prev = null
      member.next = null
      this.tail = member
    else
      member.prev = this.tail
      member.next = null
      this.tail.next = member
      this.tail = member

  remove: (member)->
    if this.is_root(member) and this.is_tail(member)
      this.root = null
      this.tail = null  
    if this.is_root(member) 
      this.root = member.next
      member.prev = null
    else if this.is_tail(member)
      this.tail = member.prev
      member.prev.next = null
    else
      member.prev.next = member.next
      member.next.prev = member.prev

    member.prev = null
    member.next = null
    member.clear()

  clear: ()->
    node = this.root
    while node
      node.remove()
      node = node.next
