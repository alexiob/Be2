from PyQt4 import QtCore, QtGui, Qt
from Be2Definitions import *
from CommonUtilities import *

class ScreenGraphicItem (QtGui.QGraphicsRectItem):
	kind = "Screen"
	
	def __init__ (self, config, editor):
		self.__initializing = True
		super (ScreenGraphicItem, self).__init__ ()
		self.setFlags (QtGui.QGraphicsItem.ItemIsSelectable | QtGui.QGraphicsItem.ItemIsMovable | QtGui.QGraphicsItem.ItemSendsGeometryChanges)
		self.setZValue (-100)
		
		self.config = config;
		self.editor = editor
		
		self.configUpdated ()
		self.__initializing = False

	def itemChange (self, change, variant):
		if not self.__initializing:
			if change == QtGui.QGraphicsItem.ItemSelectedChange:
				if variant.toBool ():
					self.setZValue (self.zValue () + 1)
				else:
					self.setZValue (self.zValue () - 1)
					
				self.editor.onScreenSelected (self, variant.toBool ())
			elif change == QtGui.QGraphicsItem.ItemPositionChange:
				p = variant.toPointF ()
				self.config['positionX'] = int (p.x ())
				self.config['positionY'] = int (p.y ())
				self.editor.onScreenUpdatePosition (self)
		
		return super (ScreenGraphicItem, self).itemChange (change, variant)
	
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
		
		self.setColor (self.config['colorColor1'])
		
	def setColor (self, s):
		self.setBrush (QtGui.QBrush (strToQColor (s)))
		
	def boundingRect (self):
		return self.rect ().adjusted (-self.config['borderSizeLeft']/2, -self.config['borderSizeTop']/2, self.config['borderSizeRight']/2, self.config['borderSizeBottom']/2)
	
	def borderColor (self, pen, state, border):
		if state & QtGui.QStyle.State_Selected:
			pen.setColor (QtCore.Qt.blue)
		else:
			color = self.config.get (border, "") 
			if color.strip ():
				pen.setColor (strToQColor (color))
			else:
				color = self.editor.project.get (border, "") 
				if color.strip ():
					pen.setColor (strToQColor (color))
		
	def paint (self, painter, option, widget):
		super (ScreenGraphicItem, self).paint (painter, option, widget)
		
		pen = QtGui.QPen (QtCore.Qt.SolidLine)
		# if option.state & QtGui.QStyle.State_Selected:
		# 	pen.setColor (QtCore.Qt.blue)
		# else:
		# 	pen.setColor (QtCore.Qt.white)
		
		r = self.rect ()
		# top
		if self.config['kScreenFlagTopSideClosed']:
			self.borderColor (pen, option.state, 'borderSideTopColor')
			pen.setWidth (self.config['borderSizeTop'])
			pen.setStyle (QtCore.Qt.SolidLine)
		else:
			pen.setWidth (1)
			pen.setStyle (QtCore.Qt.DotLine)
		painter.setPen (pen)
		painter.drawLine (r.topLeft (), r.topRight ())
		
		# bottom
		if self.config['kScreenFlagBottomSideClosed']:
			self.borderColor (pen, option.state, 'borderSideBottomColor')
			pen.setWidth (self.config['borderSizeBottom'])
			pen.setStyle (QtCore.Qt.SolidLine)
		else:
			pen.setWidth (1)
			pen.setStyle (QtCore.Qt.DotLine)
		painter.setPen (pen)
		# FIXME: inverted with top because the y coords are inverted
		painter.drawLine (r.bottomLeft (), r.bottomRight ())

		# left
		if self.config['kScreenFlagLeftSideClosed']:
			self.borderColor (pen, option.state, 'borderSideLeftColor')
			pen.setWidth (self.config['borderSizeLeft'])
			pen.setStyle (QtCore.Qt.SolidLine)
		else:
			pen.setWidth (1)
			pen.setStyle (QtCore.Qt.DotLine)
		painter.setPen (pen)
		painter.drawLine (r.topLeft (), r.bottomLeft ())

		# right
		if self.config['kScreenFlagRightSideClosed']:
			self.borderColor (pen, option.state, 'borderSideRightColor')
			pen.setWidth (self.config['borderSizeRight'])
			pen.setStyle (QtCore.Qt.SolidLine)
		else:
			pen.setWidth (1)
			pen.setStyle (QtCore.Qt.DotLine)
		painter.setPen (pen)
		painter.drawLine (r.topRight (), r.bottomRight ())

		s = self.config['title']
		if s:
			pen = QtGui.QPen (QtCore.Qt.SolidLine)
			pen.setColor (strToQColor (self.config['titleColor']))
			painter.setPen (pen)
			painter.setFont (QtGui.QFont (FONT_TO_TTF[DEFAULT_SCREEN_FONT], DEFAULT_SCREEN_TITLE_FONT_SIZE))
			o = painter.opacity ()
			painter.setOpacity (DEFAULT_SCREEN_TITLE_OPACITY/255.0)
			painter.drawText (
				self.rect ().adjusted (0, SCREEN_TITLE_START_Y, 0, 0),
				QtCore.Qt.AlignHCenter,
				s
			)
			painter.setOpacity (o)

		s = self.config['description']
		if s:
			pen = QtGui.QPen (QtCore.Qt.SolidLine)
			pen.setColor (strToQColor (self.config['descriptionColor']))
			painter.setPen (pen)
			painter.setFont (QtGui.QFont (FONT_TO_TTF[DEFAULT_SCREEN_FONT], DEFAULT_SCREEN_DESCRIPTION_FONT_SIZE))
			o = painter.opacity ()
			painter.setOpacity (DEFAULT_SCREEN_DESCRIPTION_OPACITY/255.0)
			painter.drawText (
				self.rect ().adjusted (0, SCREEN_DESCRIPTION_START_Y, 0, 0),
				QtCore.Qt.AlignHCenter,
				s
			)
			painter.setOpacity (o)
			
