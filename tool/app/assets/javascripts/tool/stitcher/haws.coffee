class stitcher.Pedal
  # EVENT EMISSIONS
  # so
  name: "foot-pedal"
  constructor: ()->
    return
  event_binding: ()->
    $(document).on "socket-connected", (event, stream)->
      window.pedal.subscribe()
    $(document).on "pedal-state", (event, stream)->
      if stream.data == "pedal-up"
        $("#step-manager .next").click()
      else if stream.data == "pedal-down"
        $("#step-manager .previous").click()
  subscribe: ()->
    socket.subscribe(this.name, "pedal-state")
  on: ()-> window.socket.send_api("PEDAL_ON")
  off: ()-> window.socket.send_api("PEDAL_OFF")

class window.HAWS
  constructor: (host, port)->
    url = 'ws://'+ host+':' + port
    console.log "Connecting to", url
    $("#url").html(url)
    socket = new WebSocket(url)
      
    $(document).unload ()->
      socket.close()

    socket.onopen = (event)->
      $(document).trigger("socket-connected")
      message = 
          name: window.NAME
          version: window.VERSION
          event: "greeting"
      socket.send JSON.stringify(message)
      socket.send_api("PEDAL_OFF")
    
    socket.send_api = (command, params={})->
      message = 
        api:
          command: command
          params: params
      message = JSON.stringify(message)
      socket.send(message)
    socket.onclose = (event)->
      $(document).trigger("socket-disconnected")
      # ATTEMPT RECONNECTION EVERY 5000 ms
      # _.delay (()-> start_socket(host, port)), 5000

    socket.onmessage = (event)->
      console.log event
      stream = JSON.parse(event.data)
      if stream.event
        $(document).trigger(stream.event, stream)
      
    socket.onerror = (event)->
      console.log("Client << ", event)
      alertify.error("<b>Error</b><p>Could not contact socket server at "+url+"</p>")

    socket.subscribe = (sender, service)->
      socket.jsend
        subscribe: sender
        service: service
    
    socket.jsend = (message)->
      headers = 
        name: window.NAME
        version: window.VERSION
      message = _.extend headers, message
      if this.readyState == this.OPEN
        this.send JSON.stringify message
        console.log("Client >>", message)
      else
        alertify.error("Lost connection to server (State="+this.readyState+"). Refresh?")        
        
    return socket