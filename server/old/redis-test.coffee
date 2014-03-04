redis = require 'redis'
client = redis.createClient()

client.on 'error', (err) ->
  console.log "Error! [#{err}]"

# Mess around on DB:9 instead of dirtying 0
client.select 9, () ->
  client.set 'key', 'value!', redis.print
  client.hset 'hash', 'one', 'value', redis.print
  client.hset 'hash', 'two', 'other', redis.print
  client.hkeys 'hash', (err, replies) ->
    console.log "#{replies.length} replies:"
    for reply, i in replies
      console.log "  #{i}: #{reply}"
    client.quit()
console.log 'test'