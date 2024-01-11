local skynet = require 'skynet'

skynet.start(function()
    skynet.error('hello world')
    skynet.error(skynet.exit())
end)