import sys
import copy
import plistlib

def newMessagesArchive (text):
	d = {
	    'default': {
	        'messages': filter (None, map (lambda x: x.strip (), text.split ('\n'))),
	    }
	}
	
	return d

def main ():
	if len (sys.argv) != 3:
		print "Usage: %s messagesFileName messagesPListName" % sys.argv[0]
		return
	messagesFilename = sys.argv[1]
	plistFilename = sys.argv[2]
	text = open (messagesFilename).read ()
	plistlib.writePlist (newMessagesArchive (text), plistFilename)
	print 'Plist generated: ', plistFilename
	
if __name__ == '__main__':
	main ()