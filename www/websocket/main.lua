local skynet = require 'skynet'
require "skynet.manager"
local console = require 'utils/console'

skynet.start(function()
    console.log('--------- skynet start ---------')

    local port = skynet.getenv('port')
    local serviceManager = skynet.newservice('service/manager/service_manager')
    skynet.name('.ServiceManager', serviceManager)
    skynet.call('.ServiceManager', 'lua', 'startGateway', port)
end)