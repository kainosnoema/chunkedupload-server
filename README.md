chunkedupload-server
=============

## DESCRIPTION

chunkedupload-server is an experimental node.js project demonstrating a
method to upload very large files by splitting them into small 1-5 MB chunks
and distributing them across multiple concurrent HTTP POST requests. Using
this method, pausing and resuming uploads should be quite simple and will be
implemented soon.

For the companion Objective-C client project, see [chunkedupload-client](http://github.com/kainosnoema/chunkedupload-client).

## Project Goals:

1. Upload very large files
1. Show real-time upload feedback
1. Pause and resume uploads
1. Use minimal memory footprint
