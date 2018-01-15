local weblit = require('weblit')
local childprocess = require('childprocess')
local fs = require('fs')
local uv = require('uv')
local voice_list = require('voice_list')

fs.mkdirSync('./tmp/')

weblit.app
    .bind({
        host = '0.0.0.0',
        port = '3333'
    })

    .use(weblit.logger)
    .use(weblit.autoHeaders)
    .use(weblit.eTagCache)
    .use(function(_, res, go)
        if res.code == 404 then
            return go()
        end
    end)

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
        path = '/tts/:voiceName:'
    }, function(req, res, go)
        local text = req.body
        local voiceName = voice_list[req.params.voiceName] and req.params.voiceName or 'boris'
        if not text then
            res.code = 400
            res.body = 'fuck you'
            res.headers['Content-Type'] = 'text/plain'
            
            return go()
        end
        
        local id = uv.now()
        
        childprocess.exec(string.format(
            'espeak -v "%s" "%s" --stdout >> tmp/%s',
            voiceName,
            text:lower():gsub('_', ' '):gsub(';', '\\;'):gsub('"', '\\"'),
            id .. '.wav'
        ))
        os.execute('sleep 0.3') -- hey, dont judge
        local data = fs.readFileSync('./tmp/' .. id .. '.wav')
        fs.unlinkSync('./tmp/' .. id .. '.wav')
        
        res.code = 200
        res.body = data
        res.headers['Content-Type'] = 'audio/wav'

        return go()
    end)
.start()
