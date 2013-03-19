from PyQt4 import QtCore, QtGui, Qt

from Be2Definitions import *
from CommonUtilities import *

class LevelView (QtGui.QGraphicsView):
	def __init__ (self, scene, editor):
		super (LevelView, self).__init__ (scene)
		
		self.editor = editor
		self.setRenderingSystem ()
		self.currentScale = 1
		
	def setRenderingSystem (self):
		from PyQt4 import QtOpenGL

		viewport = QtOpenGL.QGLWidget (QtOpenGL.QGLFormat (QtOpenGL.QGL.SampleBuffers))
		viewport.setAutoFillBackground (False)

		self.setViewport (viewport)
		self.setCacheMode (QtGui.QGraphicsView.CacheNone)
		self.setViewportUpdateMode (QtGui.QGraphicsView.FullViewportUpdate)
		self.setResizeAnchor (QtGui.QGraphicsView.AnchorUnderMouse)
		
	def viewportEvent (self, e):
		self.editor.onViewportEvent (e)
		return super (LevelView, self).viewportEvent (e)

	def keyPressEvent (self, e):
		k = e.key ()
		m = e.modifiers ()
		step = 1
		
		if self.editor.currentItem:
			if m & QtCore.Qt.ShiftModifier:
				step = 10
			elif m & QtCore.Qt.ControlModifier:
				step = -1 # snap to grid
				
			if k == QtCore.Qt.Key_Left:
				self.editor.moveCurrentItem (-1, 0, step)
			elif k == QtCore.Qt.Key_Right:
				self.editor.moveCurrentItem (1, 0, step)
			elif k == QtCore.Qt.Key_Up:
				self.editor.moveCurrentItem (0, -1, step)
			elif k == QtCore.Qt.Key_Down:
				self.editor.moveCurrentItem (0, 1, step)
			return
		
		super (LevelView, self).keyPressEvent (e)
			
	SCALE_STEP_IN = 0.9
	SCALE_STEP_OUT = 1.1
	
	def wheelEvent (self, e):
		e.accept ()
		i = e.delta () / (8.0 * 15.0) > 0 and 1or -1
		self.currentScale += i
		if self.currentScale == 0:
			self.currentScale += i

		s = i > 0 and self.SCALE_STEP_OUT or self.SCALE_STEP_IN
		self.editor.currentScale = self.currentScale * s
		self.editor.updateInfoLabel ()

		self.scale (s, s)
		