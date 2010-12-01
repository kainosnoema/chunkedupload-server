fs =      require 'fs'
path =    require 'path'
File =    require 'formidable/file'

class Chunk extends File
  file: null
  chunkSize: 5 * (1024 * 1024)
  chunkIndex: 0
  
  _fd: null
  
  open: () =>
    @length = 0
    @_fd ?= fs.openSync @path, 'a', 0666
  
  close: () =>
    try
      fs.close @_fd if @_fd
    catch e
      throw e unless e.errno is 9 # rethrow if not EBADF
    finally
      @_fd = null
    
  write: (buffer, cb) =>
    position = (@chunkSize * @chunkIndex) + @length
    @length += buffer.length # immediately increment to avoid race condition
    fs.write @_fd, buffer, 0, buffer.length, position, (err, written) =>
      #throw err if err
      @emit 'progress', @length
      cb()
  
  end: (cb) =>
    @close()
    @file.uploadedChunks.push @chunkIndex
    @emit 'end'
    cb()

class exports.ChunkedFile extends File
  constructor: (properties) ->
    super properties
    @uploadedChunks = []
  
  fileSize: 0
  totalChunks: 0
  uploadedChunks: []
  
  addChunk: (properties) =>
    properties.file = this
    new Chunk properties
  
  isComplete: () => @uploadedChunks.length >= @totalChunks
