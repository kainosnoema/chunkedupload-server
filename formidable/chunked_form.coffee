require 'underscore'
path =          require 'path'
StringDecoder = require('string_decoder').StringDecoder
IncomingForm =  require 'formidable'
ChunkedFile =   require('./chunked_file').ChunkedFile

IncomingForm.prototype.handleFieldPart = (part) ->
  value = ''
  decoder = new StringDecoder @encoding

  part.on 'data', (buffer) =>
    @_fieldsSize += buffer.length
    if @_fieldsSize > @maxFieldsSize
      @_error(new Error "maxFieldsSize exceeded, received #{@_fieldsSize} bytes of field data")
      return

    value += decoder.write buffer

  part.on 'end', () =>
    (@chunkData ?= {})[part.name] = value
    @emit 'field', part.name, value

IncomingForm.prototype.handleChunkPart = (part) ->
  @_flushing++
  
  fileSize = parseInt @chunkData['fileSize']
  chunkSize = parseInt @chunkData['chunkSize']
  chunkIndex = parseInt @chunkData['chunkIndex']
  totalChunks = Math.ceil(fileSize / chunkSize)

  chunkProps = {
    path: @_uploadPath(part.filename),
    filename: part.filename,
    mime: part.mime,
    fileSize: fileSize,
    chunkSize: chunkSize,
    totalChunks: totalChunks,
    chunkIndex: chunkIndex,
  }

  file = (@incompleteFiles ?= {})[part.filename] ?= new ChunkedFile chunkProps

  if _.include file.uploadedChunks, chunkProps.chunkIndex
    @emit 'existingChunk', part.name, chunk
    return
  
  chunk = file.addChunk chunkProps
  
  @emit 'fileBegin', part.name, file if file.uploadedChunks.length == 1
  @emit 'chunkBegin', part.name, chunk
  
  chunk.open()
  
  part.on 'data', (buffer) =>
    @pause()
    chunk.write buffer, () =>
      @resume()

  part.on 'end', () =>
    chunk.end () =>
      @_flushing--
      @emit 'chunk', part.name, file
      if file.isComplete()
        if @incompleteFiles
          delete @incompleteFiles[file.filename]
          @incompleteFiles = null
        @emit 'file', part.name, file
      
      @_maybeEnd()
  
IncomingForm.prototype.onPart = (part) ->
  if(!part.filename)
    @handleFieldPart(part)
  else
    @handleChunkPart(part)

IncomingForm.prototype._uploadPath = (filename) ->
  path.join __dirname, '../uploads', filename

exports.IncomingChunkedForm = IncomingForm
  

    