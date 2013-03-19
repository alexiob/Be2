from PyQt4 import QtCore, QtGui, Qt

from Be2Definitions import *
from CommonUtilities import *

class ColorButton (QtGui.QPushButton):
	def __init__ (self, data, plist, row, column):
		super (ColorButton, self).__init__ (data, None)

		self.plist = plist
		self.row = row
		self.column = column

		self.connect (self, QtCore.SIGNAL ("clicked()"), self.onClick)

	def onClick (self):

		item = self.plist.item (self.row, self.column)
		color = strToQColor (item.text ())
		color = QtGui.QColorDialog.getColor (color, self);
		if color.isValid ():
			s = qColorToStr (color)
			item.setText (s)
			self.setText (s)

