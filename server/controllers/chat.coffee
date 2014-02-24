{Controller} = require '../zmqcontroller'
{Message} = require '../message'
{Reply} = require '../middleware/reply'

###
  It would be nice to have middleware layers that controllers can use.
  The chat controller would use the 'auth' middleware, which would attach
  user information to the requests before they get handled.

  How it gets that information is a little difficult right now, possibly just
  grab it from redis, otherwise I might need to consider changing the SS zmq
  socket type from pubsub to req/reply
###

class ChatChannel
  constructor: ({@id, @name, @controller}) ->
    @clients = []
    @history = []

  send: (message) ->
    @history.push {message:message.data.text, channel:@id, sender:message.connectionid}
    @history = @history.slice -100 # Only store the last x messages in history
    for client in @clients
      console.log "Fan out to #{client.id}"#, message
      client.send 'chat', {command: 'message', id:undefined, data:{message:message.data.text, channel:@id, sender:message.connectionid}}
      #@controller.send 'chat', {command: 'message', id:undefined, connectionid:user, data:{message:message.data.text, channel:@id, sender:message.connectionid}}
      #controller.send new Message 'chat', {channel: @id, @name, text:msg}

  sendHistory: (client) ->
    client.send 'chat', {command: 'history', id:undefined, data:{messages:@history}}

  addClient: (client) ->
    @clients.push client

# Chat module
class ChatController extends Controller
  middleware: [Reply]
  constructor : ->
    super
    @on 'client', 'sharded', 'chat', 'subscribe', (message) ->
      console.log "#{message.connectionid} subscribed to #{message.data.channel}"
      #sender.send new Message 'echo', {data: data.data}
      @channels[message.data.channel] ?= new ChatChannel {id:message.data.channel, name:message.data.channel, controller:this}
      @channels[message.data.channel].addClient message.reply
      @channels[message.data.channel].sendHistory message.reply

    @on 'client', 'unsharded', 'chat', 'message', (message) ->
      console.log "#{message.connectionid} sent a message to #{message.data.channel}"
      console.log "Pants: #{message.pants}"
      @channels[message.data.channel]?.send message


  init: ->
    @channels = {}

exports.ChatController = ChatController
