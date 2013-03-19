from PyQt4 import QtCore, QtGui, Qt
from Be2Definitions import *
from CommonUtilities import *

class PaddleGraphicItem (QtGui.QGraphicsRectItem):
	kind = "Paddle"
	
	def __init__ (self, config, editor):
		self.__initializing = True
		super (PaddleGraphicItem, self).__init__ (Qt.QRectF (0,0,0,0), None, None)
		self.setFlags (QtGui.QGraphicsItem.ItemIsSelectable | QtGui.QGraphicsItem.ItemIsMovable | QtGui.QGraphicsItem.ItemSendsGeometryChanges)
		self.setZValue (10)
		
		self.config = config
		self.editor = editor
		
		self.configUpdated ()
		self.__initializing = False
		
	def configUpdated (self):
		r = Qt.QRectF (
		    0,
		    0,
		    self.config['width'],
		    self.config['height']
		)
		self.setRect (r)
		
		p = QtCore.QPointF (
		    self.config['positionX'],
		    self.config['positionY']
		)
		self.setPos (p)
		
		self.setZValue (10 + self.config['z'])
		self.setColor (self.config['colorColor1'])
		
	def setColor (self, s):
		self.setBrush (QtGui.QBrush (strToQColor (s)))
		
	def itemChange (self, change, variant):
		if not self.__initializing:
			if change == QtGui.QGraphicsItem.ItemSelectedChange:
				if variant.toBool ():
					self.setZValue (self.zValue () + 1)
				else:
					self.setZValue (self.zValue () - 1)
				self.editor.onPaddleSelected (self, variant.toBool ())
			elif change == QtGui.QGraphicsItem.ItemPositionChange:
				p = variant.toPointF ()
				self.config['positionX'] = int (p.x ())
				self.config['positionY'] = int (p.y ())
				self.editor.onPaddleUpdatePosition (self)
		
		return super (PaddleGraphicItem, self).itemChange (change, variant)

	def paint (self, painter, option, widget):
		super (PaddleGraphicItem, self).paint (painter, option, widget)

		label = self.config['labelText']
		if not label:
			return
		
		pen = QtGui.QPen (QtCore.Qt.SolidLine)
		pen.setColor (strToQColor (self.config['labelColor']))
		painter.setPen (pen)
		painter.setFont (QtGui.QFont (FONT_TO_TTF[self.config['labelFont']], self.config['labelFontSize']))
		o = painter.opacity ()
		painter.setOpacity (self.config['labelOpacity']/255.0)
		painter.drawText (
		    self.rect (),
		    QtCore.Qt.AlignCenter | QtCore.Qt.AlignVCenter,
		    label
		)
		painter.setOpacity (o)
		
