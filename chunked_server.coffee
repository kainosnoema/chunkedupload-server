http =        require 'http' 
formidable =  require './formidable/chunked_form'

incompleteFiles = {}
server = http.createServer (req, res) ->
  try
    if req.url is '/upload' and req.method.toLowerCase() is 'post'
    
      form = new formidable.IncomingChunkedForm
      form.incompleteFiles = incompleteFiles
      
      form.on 'fileBegin', (name, file) ->
        console.log "uploading file: #{file.filename}"
        
      form.on 'file', (name, file) ->
        console.log "done"
      
      form.on 'existingChunk', () -> statusCode res, 202
      form.on 'error', (err) -> statusCode res, 500, err
      form.on 'end', () -> statusCode res, 200
      
      form.parse req
    
    else statusCode res, 404
  catch e
    statusCode res, 500, e

server.listen 8000

statusCode = (res, code, err) ->
  res.writeHead code, 'Content-Type': 'text/plain'
  res.end()
  console.log "\n=> #{err}" if err
