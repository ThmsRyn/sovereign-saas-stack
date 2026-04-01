const http = require('http')
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200)
    res.end('ok')
    return
  }
  res.writeHead(200)
  res.end('sovereign-saas-stack demo app')
})
server.listen(3000, () => console.log('App running on port 3000'))
