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
        if res.code ~= 200 then
            res.body = res.code .. '. That\'s an error.'
            res.headers['Content-Type'] = 'text/plain'

            return go()
        end
    end)

    .route({
        path = '/'
    }, function(req, res, go)
        res.code = 403

        return go()
    end)

    .route({
        method = 'GET',
        path = '/tts/'
    }, function(req, res, go)
        local text = req.query and req.query.text
        local voiceName = req.query and voice_list[req.query.voiceName] and req.query.voiceName or 'boris'
        if not text then
            res.code = 400
            res.body = ''
            res.headers['Content-Type'] = 'audio/wav'
            
            return go()
        end
        
        local id = uv.now()
        
        childprocess.exec(string.format(
            'espeak -v "%s" "%s" --stdout >> tmp/%s',
            voiceName,
            text:lower():gsub('_', ' '):gsub(';', ''):gsub('"', ''),
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
