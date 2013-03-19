from PyQt4 import QtCore, QtGui, Qt

def strToQColor (s):
	s = str (s)
	if s:
		sa = map (lambda x: int (x.strip ()), s.strip ().split (','))
	else:
		sa = [255, 255, 255]
	return QtGui.QColor (sa[0], sa[1], sa[2])

def qColorToStr (c):
	return "%d,%d,%d" % (c.red (), c.green (), c.blue ())

def dict2lua (d):
	data = ''
	for k, v in d.iteritems ():
		if isinstance (v, basestring):
			data += '%s="%s";' % (k, v)
		else:
			data += '%s=%.1f;' % (k, v)
			
	data = '{%s}' % data
	return data
