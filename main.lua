local weblit = require('weblit')
local childprocess = require('childprocess')
local fs = require('fs')
local uv = require('uv')

weblit.app
    .bind({
        host = '0.0.0.0',
        port = '3333'
    })

    .use(weblit.logger)
    .use(weblit.autoHeaders)
    .use(weblit.eTagCache)

    .route({
        path = '/'
    }, function(req, res, go)
        res.code = 403
        res.body = 'fuck you'
        res.headers['Content-Type'] = 'text/plain'

        return go()
    end)

    .route({
        method = 'POST',
        path = '/tts/'
    }, function(req, res, go)
        local text = req.body
        if not text then
            res.code = 400
            res.body = 'fuck you'
            res.headers['Content-Type'] = 'text/plain'
            
            return go()
        end
        
        local id = uv.now()
        
        childprocess.exec(string.format(
            'espeak "%s" --stdout >> %s',
            text:gsub(';', '\\;'):gsub('"', '\\"'),
            id .. '.wav'
        ))
        os.execute('sleep 0.3') -- hey, dont judge
        local data = fs.readFileSync('./' .. id .. '.wav')

        res.code = 200
        res.body = data
        res.headers['Content-Type'] = 'audio/wav'

        return go()
    end)
.start()
