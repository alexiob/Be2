
import os
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

LEVELS_DIR = os.path.abspath (os.path.join (os.getcwd (), "../../ResourcesApp/data/levels/"))

class RequestHandler (BaseHTTPRequestHandler):
	def do_GET (self):
		path_entries = filter (None, self.path.split ('/'))
		if not path_entries or path_entries[0] != "levels":
			self.send_error (404,'Invalid URL: %s' % self.path)
		
		level_name = path_entries[1]
		
		if path_entries[2] == "index":
			self.send_response (200)
			self.send_header ('Content-type', 'text/plain')
			self.end_headers ()
			self.wfile.write (self.generateIndex (level_name))
			return
		else:
			try:
				f = open (os.path.join (LEVELS_DIR, *path_entries[1:]))
				self.send_response (200)
				self.send_header ('Content-type', 'text/plain')
				self.end_headers ()
				self.wfile.write (f.read ())
				f.close ()
				return
			except IOError:
				self.send_error (404,'File Not Found: %s' % self.path)

	def generateIndex (self, levelName):
		idx = []
		path = os.path.join (LEVELS_DIR, levelName)
		
		for dirname, dirnames, filenames in os.walk (path):
			skip = False
			for i in dirname.split ('/'):
				if i.startswith ('.'):
					skip = True
					break
			if skip:
				continue
				
			for filename in filenames:
				if filename.startswith ('.'): continue
				idx.append (os.path.join (dirname, filename)[len (path)+1:])
		return ','.join (idx)
		
def main ():
	try:
		server = HTTPServer (('', 4280), RequestHandler)
		print 'LevelServer started on port 4280...'
		server.serve_forever ()
	except KeyboardInterrupt:
		print '^C received, shutting down LevelServer'
		server.socket.close ()

if __name__ == '__main__':
	main ()

