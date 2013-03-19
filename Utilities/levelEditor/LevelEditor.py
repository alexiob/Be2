#import sip
#sip.setapi ('QString', 2)

from PyQt4 import QtCore, QtGui, Qt

import random
import copy
import os
import cPickle
import telnetlib
import socket

from Be2Definitions import *
from CommonUtilities import *
from ConfigUtilities import *
from PaddleGraphicItem import PaddleGraphicItem
from ScreenGraphicItem import ScreenGraphicItem
from LevelView import LevelView
from ColorButton import ColorButton
from LevelExporter import LevelExporter
from FieldDialog import FieldDialog

PADDLE_HANDLER_ON_TRANSITION = """
function T:onEnter ()

end

function T:onExit ()

end

"""

PADDLE_HANDLER_ON_CLICK = """
function T:onClick ()

end
"""

PADDLE_HANDLER_ON_TOUCH = """
function T:onTouchBegan (x, y, count)

end

function T:onTouchMoved (x, y, count)

end

function T:onTouchEnded (x, y, count)

end
"""

PADDLE_HANDLER_ON_HIT = """
function T:onHit (heroIndex, side, x, y)

end
"""

EXT_LIGHTS_ARRAY = """
"lights": [

],
"""

EXT_PADDLE_LIGHT = """
{
    "lightID": -1,
    "kind": kLightKindRect,
    "enabled": True,
    "flags": 0,
    "width": 5,
    "height": 5,
    "opacity": 0,
    "color": "255,255,255",
    "power": 0.0,
},
"""

EXT_SCREEN_LIGHT = """
{
    "lightID": -1,
    "kind": kLightKindRect,
    "enabled": True,
    "flags": 0,
    "positionX": 0.5,
    "positionY": 0.5,
    "width": 5,
    "height": 5,
    "opacity": 0,
    "color": "255,255,255",
    "power": 0.0,
},
"""

kModeMove = 0
kModeResizeL = 1
kModeResizeR = 2
kModeResizeT = 3
kModeResizeB = 4
kModeResizeTL = 5
kModeResizeTR = 6
kModeResizeBL = 7
kModeResizeBR = 8

class MainWindow (QtGui.QMainWindow):
	def __init__ (self):
		super (MainWindow, self).__init__ ()

		self.project = None
		self.prevPoint = None
		self.pointOffset = 5
		self.levelPos = QtCore.QPoint (0, 0)
		self.currentItemIndex = -1
		self.currentItem = None
		self.infoLabel = None
		self.copiedItem = None
		self.copiedItemKind = None
		self.currentScale = 1
		self.projectModified = False
		self.projectFilename = ''
		self.projectOpenPath = ''
		self.projectSaveAsPath = ''
		self.projectExportPath = ''
		self.moveItemMode = kModeMove
		self.applyScreenPropertiesListState = False
		self.applyPaddlePropertiesListState = False
		self.deviceAddress = "localhost"
		
		self.__disable_item_update = 0

		self.createLevelView ()
		self.createActions ()
		self.createMenus ()
		self.createToolBars ()
		self.createStatusBar ()
		self.createDockWindows ()

		self.setWindowTitle ("Be2 Level Editor")

		#self.setUnifiedTitleAndToolBarOnMac (True)

		self.initProject (self.getEmptyProject (), loadSettings=True)

	def cleanup (self):
		self.levelPropertiesList.clear ()
		self.screenPropertiesList.clear ()
		self.paddlePropertiesList.clear ()
		self.levelPropertiesList = None
		self.screenPropertiesList = None
		self.paddlePropertiesList = None

		self.project = None
		self.prevPoint = None
		self.levelPos = None
		self.currentItem = None
		self.currentItemIndex = -1

		self.infoLabel = None

		self.cleanupMenus ()
		
	def closeEvent (self, event):
		if self.isOkToClose ():
			self.saveSettings ()
			self.cleanup ()
			super (MainWindow, self).closeEvent (event)
		else:
			event.ignore ()

	#--------------------------------------------------------------------------
	# settings

	def loadSettings (self, isLoad=False):
		settings = QtCore.QSettings ()
		
		if not isLoad:
			self.setGeometry (settings.value ("MainWindow/Geometry").toRect ())
			self.restoreState (settings.value ("MainWindow/State").toByteArray ())
			self.projectOpenPath = str (settings.value ("Project/OpenPath", "").toString ())
			self.projectSaveAsPath = str (settings.value ("Project/SaveAsPath", "").toString ())
			self.projectExportPath = str (settings.value ("Project/ExportPath", "").toString ())

		self.levelPropertiesList.horizontalHeader ().restoreState (settings.value ("PropertiesTabs/LevelPropertiesListState").toByteArray ())
		self.screenPropertiesList.horizontalHeader ().restoreState (settings.value ("PropertiesTabs/ScreenPropertiesListState").toByteArray ())
		self.paddlePropertiesList.horizontalHeader ().restoreState (settings.value ("PropertiesTabs/PaddlePropertiesListState").toByteArray ())

		self.applyScreenPropertiesListState = True
		self.applyPaddlePropertiesListState = True

	def saveSettings (self):
		settings = QtCore.QSettings ()
		settings.setValue ("MainWindow/State", QtCore.QVariant (self.saveState ()))
		settings.setValue ("MainWindow/Geometry", QtCore.QVariant (self.geometry ()))

		settings.setValue ("PropertiesTabs/LevelPropertiesListState", QtCore.QVariant (self.levelPropertiesList.horizontalHeader ().saveState ()))
		settings.setValue ("PropertiesTabs/ScreenPropertiesListState", QtCore.QVariant (self.screenPropertiesList.horizontalHeader ().saveState ()))
		settings.setValue ("PropertiesTabs/PaddlePropertiesListState", QtCore.QVariant (self.paddlePropertiesList.horizontalHeader ().saveState ()))

		settings.setValue ("Project/OpenPath", QtCore.QVariant (self.projectOpenPath))
		settings.setValue ("Project/SaveAsPath", QtCore.QVariant (self.projectSaveAsPath))
		settings.setValue ("Project/ExportPath", QtCore.QVariant (self.projectExportPath))

	#--------------------------------------------------------------------------
	# setup

	def createLevelView (self):
		self.levelViewScene = QtGui.QGraphicsScene ()
		self.levelViewScene.setBackgroundBrush (QtGui.QBrush (QtGui.QColor ('black')))
		l = self.levelViewScene.addLine (0, 10000, 0, -10000, QtGui.QPen (QtGui.QColor ('red')))
		l.setZValue (-10000)
		l.setOpacity (0.5)
		l = self.levelViewScene.addLine (-10000, 0, 10000, 0, QtGui.QPen (QtGui.QColor ('red')))
		l.setZValue (-10000)
		l.setOpacity (0.5)

		self.levelView = LevelView (self.levelViewScene, self)
		self.levelView.setDragMode (QtGui.QGraphicsView.ScrollHandDrag)

		self.setCentralWidget (self.levelView)

	def cleanupLevelView (self):
		for item in self.levelViewScene.items ():
			if isinstance (item, (PaddleGraphicItem, ScreenGraphicItem)):
				self.levelViewScene.removeItem (item)

	#--------------------------------------------------------------------------
	# events

	def onViewportEvent (self, e):
		self.updateInfoLabel ()

	#--------------------------------------------------------------------------
	# actions

	def createNewAction (self, text, slot=None, shortcut=None, icon=None, tip=None, checkable=False, signal="triggered()"):
		action = QtGui.QAction (text, self)
		if icon is not None:
			action.setIcon (QtGui.QIcon(icon))
		if shortcut is not None:
			action.setShortcut (shortcut)
		if tip is not None:
			action.setToolTip (tip)
			action.setStatusTip (tip)
		if slot is not None:
			self.connect (action, QtCore.SIGNAL (signal), slot)
		if checkable:
			action.setCheckable (True)
		return action

	def addActions (self, target, actions):
		for action in actions:
			if action is None:
				target.addSeparator ()
			else:
				target.addAction (action)

	def createActions (self):
		# project
		self.actionProjectNew = self.createNewAction (
			text = "&New", 
			slot = self.onProjectNew,
			shortcut = "Ctrl+N",
			icon = "resources/projectNew.png", 
			tip = "Create a new level project"
		)
		self.actionProjectOpen = self.createNewAction (
			text = "&Open", 
			slot = self.onProjectOpen, 
			shortcut = "Ctrl+O",
			icon = "resources/projectOpen.png", 
			tip = "Open a level project"
		)
		self.actionProjectSave = self.createNewAction (
			text = "&Save", 
			slot = self.onProjectSave, 
			shortcut = "Ctrl+S",
			icon = "resources/projectSave.png", 
			tip = "Save current level project"
		)
		self.actionProjectSaveAs = self.createNewAction (
			text = "Save &As...", 
			slot = self.onProjectSaveAs, 
			shortcut = "",
			icon = "resources/projectSaveAs.png", 
			tip = "Save current level project using different name"
		)
		self.actionProjectExport = self.createNewAction (
			text = "&Export", 
			slot = self.onProjectExport, 
			shortcut = "Ctrl+E",
			icon = "resources/projectExport.png", 
			tip = "Export current level project"
		)
		self.actionLevelUpload = self.createNewAction (
			text = "&Upload Level", 
			slot = self.onLevelUpload, 
			shortcut = "Ctrl+U",
			icon = "", 
			tip = "Upload level to device"
		)
		self.actionRemoveUploadedLevels = self.createNewAction (
			text = "&Remove Uploaded Levels", 
			slot = self.onRemoveUploadedLevels, 
			shortcut = "Ctrl+R",
			icon = "", 
			tip = "Remove uploaded levels from device"
		)

		# entities
		self.actionPaddleAdd = self.createNewAction (
			text = "Add &Screen", 
			slot = self.onAddScreen, 
			shortcut = "S",
			icon = "resources/screenAdd.png", 
			tip = "Add screen to level"
		)

		self.actionScreenAdd = self.createNewAction (
			text = "&Add Paddle", 
			slot = self.onAddPaddle, 
			shortcut = "A",
			icon = "resources/paddleAdd.png", 
			tip = "Add paddle to level"
		)

		# cut & paste
		self.actionCopy = self.createNewAction (
			text = "&Copy",
			slot = self.onCopy, 
			shortcut = "Ctrl+C",
			icon = "resources/copy.png", 
			tip = "Copy selected object"
		)
		self.actionCut = self.createNewAction (
			text = "Cu&t",
			slot = self.onCut, 
			shortcut = "Ctrl+X",
			icon = "resources/cut.png", 
			tip = "Cut selected object"
		)
		self.actionPaste = self.createNewAction (
			text = "&Paste", 
			slot = self.onPaste, 
			shortcut = "Ctrl+V",
			icon = "resources/paste.png", 
			tip = "Paste object into level"
		)

		# screen
		self.actionScreenFillField = self.createNewAction (
			text = "Fill &Field", 
			slot = self.onScreenFillField, 
			shortcut = "Ctrl+K",
			icon = "", 
			tip = "Fill a filed for all screens"
		)
		self.actionScreenSetFirst = self.createNewAction (
			text = "Set &First Screen", 
			slot = self.onScreenSetFirst, 
			shortcut = "",
			icon = "resources/screenSetFirst.png", 
			tip = "Set selected screen as level's first screen"
		)

		#paddles
		self.actionPaddleFillField = self.createNewAction (
			text = "Fill &Field", 
			slot = self.onPaddleFillField, 
			shortcut = "Ctrl+L",
			icon = "", 
			tip = "Fill a filed for all paddles"
		)

		self.actionPaddleFillDefensiveAIData = self.createNewAction (
			text = "Fill &Defensive AI Data", 
			slot = self.onPaddleFillDefensiveAIData, 
			shortcut = "Ctrl+D",
			icon = "", 
			tip = "Fill defensive AI data with default values"
		)
		self.actionPaddleAddHandlerOnTransition = self.createNewAction (
			text = "Add onTransition Handlers", 
			slot = self.onPaddleAddHandlerOnTransition, 
			shortcut = "",
			icon = "", 
			tip = ""
		)

		self.actionPaddleAddHandlerOnClick = self.createNewAction (
			text = "Add on&Click Handler", 
			slot = self.onPaddleAddHandlerOnClick, 
			shortcut = "",
			icon = "", 
			tip = ""
		)

		self.actionPaddleAddHandlerOnTouch = self.createNewAction (
			text = "Add on&Touch Handlers", 
			slot = self.onPaddleAddHandlerOnTouch, 
			shortcut = "",
			icon = "", 
			tip = ""
		)

		self.actionPaddleAddHandlerOnHit = self.createNewAction (
			text = "Add on&Hit Handler", 
			slot = self.onPaddleAddHandlerOnHit, 
			shortcut = "",
			icon = "", 
			tip = ""
		)

		#ext
		self.actionExtAddLightsArray = self.createNewAction (
			text = "Add Lights &Array", 
			slot = self.onExtAddLightsArray, 
			shortcut = "",
			icon = "", 
			tip = ""
		)
		self.actionExtAddLight = self.createNewAction (
			text = "Add &Light", 
			slot = self.onExtAddLight, 
			shortcut = "",
			icon = "", 
			tip = ""
		)

		# paddle resize modes
		self.actionPaddleResizeTL = self.createNewAction (
			text = "Resize TL", 
			slot = self.onPaddleResizeTL, 
			shortcut = "Meta+7",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeT = self.createNewAction (
			text = "Resize T", 
			slot = self.onPaddleResizeT, 
			shortcut = "Meta+8",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeL = self.createNewAction (
			text = "Resize L", 
			slot = self.onPaddleResizeL, 
			shortcut = "Meta+4",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeTR = self.createNewAction (
			text = "Resize TR", 
			slot = self.onPaddleResizeTR, 
			shortcut = "Meta+9",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeR = self.createNewAction (
			text = "Resize R", 
			slot = self.onPaddleResizeR, 
			shortcut = "Meta+6",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeBL = self.createNewAction (
			text = "Resize BL", 
			slot = self.onPaddleResizeBL, 
			shortcut = "Meta+1",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeBR = self.createNewAction (
			text = "Resize BR", 
			slot = self.onPaddleResizeBR, 
			shortcut = "Meta+3",
			icon = "", 
			tip = ""
		)
		self.actionPaddleResizeB = self.createNewAction (
			text = "Resize B", 
			slot = self.onPaddleResizeB, 
			shortcut = "Meta+2",
			icon = "", 
			tip = ""
		)
		self.actionPaddleMove = self.createNewAction (
			text = "Move", 
			slot = self.onPaddleMove, 
			shortcut = "Meta+5",
			icon = "", 
			tip = ""
		)

		self.actionPaddleSetMinX = self.createNewAction (
			text = "Set MinX", 
			slot = self.onPaddleSetMinX, 
			shortcut = "Ctrl+[",
			icon = "", 
			tip = ""
		)
		self.actionPaddleSetMaxX = self.createNewAction (
			text = "Set MaxX", 
			slot = self.onPaddleSetMaxX, 
			shortcut = "Ctrl+]",
			icon = "", 
			tip = ""
		)
		self.actionPaddleSetMinY = self.createNewAction (
			text = "Set MinY", 
			slot = self.onPaddleSetMinY, 
			shortcut = "Ctrl+;",
			icon = "", 
			tip = ""
		)
		self.actionPaddleSetMaxY = self.createNewAction (
			text = "Set MaxY", 
			slot = self.onPaddleSetMaxY, 
			shortcut = "Ctrl+'",
			icon = "", 
			tip = ""
		)

		self.enableActions ()

	def cleanupMenus (self):
		self.menuFile = None
		self.menuEdit = None
		self.menuScreen = None
		self.menuPaddle = None
		self.menuExt = None
		
		self.menubar = None
		
	def createMenus (self):
		self.menubar = QtGui.QMenuBar ()
		
		self.menuFile = self.menubar.addMenu ("&File")
		self.addActions (self.menuFile, 
			[
				self.actionProjectNew,
				self.actionProjectOpen,
				self.actionProjectSave,
				self.actionProjectSaveAs,
				None,
				self.actionProjectExport,
				None,
				self.actionLevelUpload,
				self.actionRemoveUploadedLevels,
			]
		)

		self.menuEdit = self.menubar.addMenu ("&Edit")
		self.addActions (self.menuEdit, 
				         [
				             self.actionPaddleAdd,
				             self.actionScreenAdd,
				             None,
				             self.actionCopy,
				             self.actionCut,
				             self.actionPaste,
				             None,
				             self.actionScreenSetFirst,
				         ]
				         )

		self.menuScreen = self.menubar.addMenu ("&Screen")
		self.addActions (self.menuScreen,
				         [
				             self.actionScreenFillField,
				             None,
				             self.actionScreenSetFirst,
				         ]
				         )

		self.menuPaddle = self.menubar.addMenu ("&Paddle")
		self.addActions (self.menuPaddle,
				         [
				             self.actionPaddleFillField,
				             None,
				             self.actionPaddleFillDefensiveAIData,
				             None,
				             self.actionPaddleAddHandlerOnTransition,
				             self.actionPaddleAddHandlerOnClick,
				             self.actionPaddleAddHandlerOnTouch,
				             self.actionPaddleAddHandlerOnHit,
				             None,
				             self.actionPaddleResizeTL,		                     
				             self.actionPaddleResizeTR,		                     
				             self.actionPaddleResizeBL,		                     
				             self.actionPaddleResizeBR,		                     
				             self.actionPaddleResizeT,		                     
				             self.actionPaddleResizeL,		                     
				             self.actionPaddleResizeB,		                     
				             self.actionPaddleResizeR,		                     
				             self.actionPaddleMove,	
				             None,
				             self.actionPaddleSetMinX,
				             self.actionPaddleSetMaxX,
				             self.actionPaddleSetMinY,
				             self.actionPaddleSetMaxY,
				         ]
				         )

		self.menuExt = self.menubar.addMenu ("&Extensions")
		self.addActions (self.menuExt,
				         [
				             self.actionExtAddLightsArray,
				             self.actionExtAddLight,
				         ]
				         )

	def createToolBars (self):
		self.toolbarFile = self.addToolBar ("File")
		self.toolbarFile.setObjectName ("toolbarFile")
		self.addActions (self.toolbarFile, 
				         [
				             self.actionProjectNew,
				             self.actionProjectOpen,
				             self.actionProjectSave,
				             self.actionProjectSaveAs,
				             self.actionProjectExport,
				         ]
				         )

		self.toolbarEdit = self.addToolBar ("Edit")
		self.toolbarEdit.setObjectName ("toolbarEdit")
		self.addActions (self.toolbarEdit, 
				         [
				             self.actionPaddleAdd,
				             self.actionScreenAdd,
				             None,
				             self.actionCopy,
				             self.actionCut,
				             self.actionPaste,
				             None,
				             self.actionScreenSetFirst
				         ]
				         )

	def createStatusBar (self):
		self.infoLabel = QtGui.QLabel ()
		self.infoLabel.setFrameStyle (QtGui.QFrame.StyledPanel | QtGui.QFrame.Sunken)
		status = self.statusBar ()
		status.addPermanentWidget (self.infoLabel)
		status.showMessage ("Ready", 5000)

		self.updateInfoLabel ()

	def createDockWindows (self):
		dock = QtGui.QDockWidget ("Properties", self)
		dock.setObjectName ('properties')
		dock.setAllowedAreas (QtCore.Qt.LeftDockWidgetArea | QtCore.Qt.RightDockWidgetArea)
		self.addDockWidget (QtCore.Qt.RightDockWidgetArea, dock)

		# level
		self.levelPropertiesList = QtGui.QTableWidget ()
		self.levelPropertiesList.verticalHeader ().hide ()
		self.levelPropertiesList.setAlternatingRowColors (True)
		self.connect (self.levelPropertiesList, QtCore.SIGNAL ('itemChanged(QTableWidgetItem*)'), self.levelPropertiesListItemChanged)
		self.connect (self.levelPropertiesList, QtCore.SIGNAL ('clicked(const QModelIndex &)'), self.levelPropertiesListSelectRow)

		# screen
		self.screenPropertiesList = QtGui.QTableWidget ()
		self.screenPropertiesList.verticalHeader ().hide ()
		self.screenPropertiesList.setAlternatingRowColors (True)
		self.connect (self.screenPropertiesList, QtCore.SIGNAL ('itemChanged(QTableWidgetItem*)'), self.screenPropertiesListItemChanged)
		self.connect (self.screenPropertiesList, QtCore.SIGNAL ('itemClicked(QTableWidgetItem*)'), self.screenPropertiesListSelectRow)

		# paddle
		self.paddlePropertiesList = QtGui.QTableWidget ()
		self.paddlePropertiesList.verticalHeader ().hide ()
		self.paddlePropertiesList.setAlternatingRowColors (True)
		self.connect (self.paddlePropertiesList, QtCore.SIGNAL ('itemChanged(QTableWidgetItem*)'), self.paddlePropertiesListItemChanged)
		self.connect (self.paddlePropertiesList, QtCore.SIGNAL ('clicked(const QModelIndex &)'), self.paddlePropertiesListSelectRow)

		# level/screens/paddle tab
		self.propertiesTabWidget = QtGui.QTabWidget ()
		self.propertiesTabWidget.addTab (self.levelPropertiesList, "&Level")
		self.propertiesTabWidget.addTab (self.screenPropertiesList, "&Screen")
		self.propertiesTabWidget.addTab (self.paddlePropertiesList, "&Paddle")
		dock.setWidget (self.propertiesTabWidget)

		# extras dock
		dock = QtGui.QDockWidget ("Extras", self)
		dock.setObjectName ('extras')
		dock.setAllowedAreas (QtCore.Qt.BottomDockWidgetArea)
		self.addDockWidget (QtCore.Qt.BottomDockWidgetArea, dock)
		self.extrasDock = dock

		font = QtGui.QFont ()
		font.setFamily( 'Courier')
		font.setFixedPitch (True)
		font.setPointSize (10)

		# scripts
		self.scriptsEditor = QtGui.QTextEdit ()
		self.scriptsEditor.setFont (font)
		self.scriptsEditor.setLineWrapMode (QtGui.QTextEdit.NoWrap)
		self.scriptsEditor.setTabChangesFocus (False)
		self.connect (self.scriptsEditor, QtCore.SIGNAL ('textChanged()'), self.onEditorChanged)

		# extensions
		self.extensionsEditor = QtGui.QTextEdit ()
		self.extensionsEditor.setFont (font)
		self.extensionsEditor.setLineWrapMode (QtGui.QTextEdit.NoWrap)
		self.extensionsEditor.setTabChangesFocus (False)
		self.connect (self.extensionsEditor, QtCore.SIGNAL ('textChanged()'), self.onEditorChanged)

		# extras tab 
		self.extrasTabWidget = QtGui.QTabWidget ()
		self.extrasTabWidget.addTab (self.scriptsEditor, "Scrip&ts")
		self.extrasTabWidget.addTab (self.extensionsEditor, "&Extensions")
		dock.setWidget (self.extrasTabWidget)

	#--------------------------------------------------------------------------
	# project

	def hasScriptCode (self, data):
		code = ''
		for i in data.split ('\n'):
			if i.strip (' \t').startswith ('--'):
				continue
			if not i.strip (' \t\n'):
				continue
			code += i + '\n'
		return bool (code)

	def getEmptyProject (self):
		project = newLevelConfig ()
		return project

	def createProjectItems (self):
		# screens
		for idx, screen in enumerate (self.project['screens']):
			self.addScreen (screen, idx=idx, select=False)

		# paddles
		for idx, paddle in enumerate (self.project['paddles']):
			self.addPaddle (paddle, idx=idx, select=False)

	def handleModifiedProject (self):
		r = True
		if self.projectModified:
			v = QtGui.QMessageBox.warning (self, "Be2 Warning", "Project is modified. Continue and discard all changes?", 
						                   QtGui.QMessageBox.Discard | QtGui.QMessageBox.Cancel, QtGui.QMessageBox.Cancel
						                   )
			if v == QtGui.QMessageBox.Cancel:
				r = False
		return r

	def setProjectModified (self, modified=True):
		self.projectModified = modified
		self.enableActions ()

	def initProject (self, data, loadSettings=False):
		self.cleanupLevelView ()
		self.scriptsEditor.clear ()
		self.extensionsEditor.clear ()
		
		self.project = data
		self.createProjectItems ()

		self.populateLevelPropertiesList ()
		self.populateScreenPropertiesList ()

		if loadSettings:
			self.loadSettings ()

		self.loadCurrentItem ()
		self.updateInfoLabel ()

		self.setProjectModified (False)

	def onProjectNew (self):
		if self.handleModifiedProject ():
			self.projectFilename = ""
			self.initProject (self.getEmptyProject ())

	def onProjectOpen (self):
		if self.handleModifiedProject ():
			filename = QtGui.QFileDialog.getOpenFileName (self, "Open Project", self.projectOpenPath, "Be2 Project (*.b2p)")
			if filename:
				filename = str (filename)
				self.projectOpenPath = os.path.dirname (filename)
				try:
					f = open (filename, 'rb')
					data = cPickle.load (f)
					f.close ()
					self.initProject (data)
					self.projectFilename = filename
				except:
					QtGui.QMessageBox.critical (self, "Be2 Error", "Error loading project file: %s" % filename)
					self.projectFilename = ''
					raise

	def onProjectSave (self):
		if self.projectModified:
			if not self.projectFilename:
				n = self.project['name']
				if not n:
					n = 'untitled'
				p = os.path.join (self.projectOpenPath, n + ".b2p")
				filename = str (QtGui.QFileDialog.getSaveFileName (self, "Save Project", p, "Be2 Project (*.b2p)"))
				if not filename:
					return
				self.projectFilename = str (filename)
				self.projectOpenPath = os.path.dirname (filename)

			self.saveCurrentItem ()

			try:
				f = open (self.projectFilename, 'wb')
				cPickle.dump (self.project, f)
				f.close ()
				self.setProjectModified (False)
			except:
				QtGui.QMessageBox.critical (self, "Be2 Error", "Error saving project file: %s" % self.projectFilename)
				raise

	def onProjectSaveAs (self):
		n = self.project['name']
		if not n:
			n = 'untitled'
		p = os.path.join (self.projectSaveAsPath, n + ".b2p")
		filename = str (QtGui.QFileDialog.getSaveFileName (self, "Save Project As", p, "Be2 Project (*.b2p)"))
		if not filename:
			return

		filename = str (filename)
		try:
			m = self.projectModified
			self.saveCurrentItem ()
			self.setProjectModified (m)

			f = open (filename, 'wb')
			cPickle.dump (self.project, f)
			f.close ()
		except:
			QtGui.QMessageBox.critical (self, "Be2 Error", "Error saving project file: %s" % filename)
			raise

	def onProjectExport (self):
		p = os.path.join (self.projectExportPath, "level.plist")
		filename = QtGui.QFileDialog.getSaveFileName (self, "Export Project As", p, "Be2 Level (*.plist)")
		if filename:
			m = self.projectModified
			self.saveCurrentItem ()
			self.setProjectModified (m)

			filename = str (filename)
			self.projectExportPath = os.path.dirname (filename)
			try:
				exporter = LevelExporter (self.project)
				exporter.export (filename)
			except:
				QtGui.QMessageBox.critical (self, "Be2 Error", "Error exporting project file: %s" % filename)
				raise

	def onLevelUpload (self):
		t, b = QtGui.QInputDialog.getText (self, "Device Address", "Device Address:", QtGui.QLineEdit.Normal, self.deviceAddress)
		if not b:
			return
		self.deviceAddress = str (t)
		server = "10.1.1.41"
		levelName = self.project['name']
		print "Upload Level %r to device %r" % (levelName, self.deviceAddress)
		c = telnetlib.Telnet (self.deviceAddress, 4242)
		c.write ('game.downloadLevel ("%s", "%s", 4280)' % (levelName, server))
		c.close ()
		
	def onRemoveUploadedLevels (self):
		t, b = QtGui.QInputDialog.getText (self, "Device Address", "Device Address:", QtGui.QLineEdit.Normal, self.deviceAddress)
		if not b:
			return
		self.deviceAddress = str (t)
		server = "10.1.1.41"
		levelName = self.project['name']
		print "Removed uploaded levels from device %r" % self.deviceAddress
		c = telnetlib.Telnet (self.deviceAddress, 4242)
		c.write ('game.removeDownloadedLevels ()')
		c.close ()

	# paddle

	def onPaddleFillField (self):
		field, data = self.fieldDialog (PADDLE_PROPERTIES_TYPES)
		if field:
			for i in self.project['paddles']:
				i[field] = data
			self.setProjectModified (True)
			if self.currentItem.kind == "Paddle":
				self.populatePaddlePropertiesList ()

	def onPaddleFillDefensiveAIData (self):
		d = {
			'flags': 0,
			'validSides': kSideLeft|kSideRight,
			'aiLevel': 2.0,
			'maxSpeedX': -1,
			'maxSpeedY': -1,
			'maxSpeedBL': 0,
			'maxSpeedTR': 0,
			'sensorRangeWidth': 0,
			'sensorRangeHeight': 0,

			'speedFactor': 1.0,
			'speedFactorMult': 1.5,
			'speedFactorMin': 7.5,
		}
		self.currentItem.config['aiDefensiveData'] = dict2lua (d)
		self.populatePaddlePropertiesList ()
		self.setProjectModified ()

	def onPaddleAddHandlerOnTransition (self):
		self.scriptsEditor.insertPlainText (PADDLE_HANDLER_ON_TRANSITION)
		self.saveCurrentItem ()

	def onPaddleAddHandlerOnClick (self):
		self.scriptsEditor.insertPlainText (PADDLE_HANDLER_ON_CLICK)
		self.saveCurrentItem ()

	def onPaddleAddHandlerOnTouch (self):
		self.scriptsEditor.insertPlainText (PADDLE_HANDLER_ON_TOUCH)
		self.saveCurrentItem ()

	def onPaddleAddHandlerOnHit (self):
		self.scriptsEditor.insertPlainText (PADDLE_HANDLER_ON_HIT)
		self.saveCurrentItem ()

	def onPaddleResizeTL (self):
		self.moveItemMode = kModeResizeTL

	def onPaddleResizeTR (self):
		self.moveItemMode = kModeResizeTR

	def onPaddleResizeBL (self):
		self.moveItemMode = kModeResizeBL

	def onPaddleResizeBR (self):
		self.moveItemMode = kModeResizeBR

	def onPaddleResizeT (self):
		self.moveItemMode = kModeResizeT

	def onPaddleResizeL (self):
		self.moveItemMode = kModeResizeL

	def onPaddleResizeB (self):
		self.moveItemMode = kModeResizeB

	def onPaddleResizeR (self):
		self.moveItemMode = kModeResizeR

	def onPaddleMove (self):
		self.moveItemMode = kModeMove

	def setPaddleField (self, name, value):
		self.currentItem.config[name] = value
		self.populatePaddlePropertiesList ()
		self.setProjectModified ()

	def onPaddleSetMinX (self):
		self.setPaddleField ('minX', self.currentItem.config['positionX'])

	def onPaddleSetMaxX (self):
		self.setPaddleField ('maxX', self.currentItem.config['positionX'])

	def onPaddleSetMinY (self):
		self.setPaddleField ('minY', self.currentItem.config['positionY'])

	def onPaddleSetMaxY (self):
		self.setPaddleField ('maxY', self.currentItem.config['positionY'])

	def newPaddlePosition (self):
		point = self.levelView.mapFromGlobal (QtGui.QCursor.pos ())
		g = self.levelView.geometry ()
		if not g.contains (point):
			point = g.center ()
		if point == self.prevPoint:
			point += QtCore.QPoint (self.pointOffset, self.pointOffset)
			self.pointOffset += 10
		else:
			self.pointOffset = 10
			self.prevPoint = point
		point = self.levelView.mapToScene (point)
		return int (point.x ()), int (point.y ())

	def onAddPaddle (self):
		x, y = self.newPaddlePosition ()
		paddle = newPaddleConfig (x, y, DEFAULT_PADDLE_WIDTH, DEFAULT_PADDLE_HEIGHT)
		self.project['paddles'].append (paddle)
		self.addPaddle (paddle, idx = len (self.project['paddles']) - 1)

	def onPaddleUpdatePosition (self, item):
		for i in range (self.paddlePropertiesList.rowCount ()):
			li = self.paddlePropertiesList.item (i, 0)
			if li is None: continue

			self.__disable_item_update += 1
			if (str (li.text ()) == 'positionX'):
				self.paddlePropertiesList.item (i, 1).setText (str(item.config['positionX']))
			if (str (li.text ()) == 'positionY'):
				self.paddlePropertiesList.item (i, 1).setText (str(item.config['positionY']))
			self.__disable_item_update -= 1
			self.setProjectModified ()

	def onPaddleUpdateSize (self, item):
		for i in range (self.paddlePropertiesList.rowCount ()):
			li = self.paddlePropertiesList.item (i, 0)
			if li is None: continue

			self.__disable_item_update += 1
			if (str (li.text ()) == 'width'):
				self.paddlePropertiesList.item (i, 1).setText (str(item.config['width']))
			if (str (li.text ()) == 'height'):
				self.paddlePropertiesList.item (i, 1).setText (str(item.config['height']))
			self.__disable_item_update -= 1
			self.setProjectModified ()

	def onPaddleSelected (self, item, b):
		m = self.projectModified
		self.saveCurrentItem ()

		if b:
			self.currentItem = item
			self.currentItemIndex = self.project['paddles'].index (item.config)
			self.propertiesTabWidget.setCurrentIndex (2)
		else:
			self.currentItem = None
			self.currentItemIndex = -1
			self.propertiesTabWidget.setCurrentIndex (0)

		self.populatePaddlePropertiesList ()

		self.loadCurrentItem ()
		self.projectModified = m
		self.enableActions ()

	def addPaddle (self, paddle, idx=-1, select=True):
		item = PaddleGraphicItem (paddle, self)

		self.levelViewScene.addItem (item)
		if select:
			self.projectModified = True
			self.saveCurrentItem ()

			self.levelViewScene.clearSelection ()
			item.setSelected (True)
			self.currentItem = item
			if idx == -1:
				idx = self.project['paddles'].index (item.config)
			self.currentItemIndex = idx
			self.populatePaddlePropertiesList ()

			self.loadCurrentItem ()
		self.setProjectModified ()

	def removePaddle (self, item):
		self.project['paddles'].remove (item.config)
		self.levelViewScene.removeItem (item)
		if self.currentItem is item:
			self.currentItem = None
			self.currentItemIndex = -1
			self.populatePaddlePropertiesList ()

			self.loadCurrentItem ()
		self.setProjectModified ()
		del item

	def findPaddleItemWithConfig (self, config):
		item = None
		for i in self.levelViewScene.items ():
			if isinstance (i, PaddleGraphicItem) and i.config is config:
				item = i
				break
		return item

	# screen

	def onScreenFillField (self):
		field, data = self.fieldDialog (SCREEN_PROPERTIES_TYPES)
		if field:
			for i in self.project['screens']:
				i[field] = data
			self.setProjectModified (True)
			if self.currentItem.kind == "Screen":
				self.populateScreenPropertiesList ()

	def onScreenSetFirst (self):
		if self.currentItem and self.currentItem.kind == 'Screen':
			self.project['firstScreen'] = self.currentItem.config['name']
			self.populateLevelPropertiesList ()

	def onAddScreen (self):
		x, y = self.newScreenPosition ()
		screen = newScreenConfig (x, y, DEFAULT_SCREEN_WIDTH, DEFAULT_SCREEN_HEIGHT)
		self.project['screens'].append (screen)
		self.addScreen (screen, idx = len (self.project['screens']) - 1)

	def newScreenPosition (self):
		return self.newPaddlePosition ()

	def onScreenUpdatePosition (self, item):
		for i in range (self.screenPropertiesList.rowCount ()):
			li = self.screenPropertiesList.item (i, 0)
			if li is None: continue

			self.__disable_item_update += 1
			if (str (li.text ()) == 'positionX'):
				self.screenPropertiesList.item (i, 1).setText (str(item.config['positionX']))
			if (str (li.text ()) == 'positionY'):
				self.screenPropertiesList.item (i, 1).setText (str(item.config['positionY']))
			self.__disable_item_update -= 1

		self.setProjectModified ()

	def onScreenSelected (self, item, b):
		m = self.projectModified
		
		self.saveCurrentItem ()
		if b:
			self.currentItem = item
			self.currentItemIndex = self.project['screens'].index (item.config)
			self.propertiesTabWidget.setCurrentIndex (1)
		else:
			self.currentItem = None
			self.currentItemIndex = -1
			self.propertiesTabWidget.setCurrentIndex (0)

		self.populateScreenPropertiesList ()

		self.loadCurrentItem ()
		self.projectModified = m
		self.enableActions ()

	def getScreenWithNameIndex (self, name):
		idx = -1
		for i, s in enumerate (self.project['screens']):
			if s['name'] == name:
				idx = i
				break
		return idx

	def showCurrentScreen (self):
		if self.currentItem == None or self.currentItem.kind == "Screen": 
			return
		self.levelView.centerOn (self.currentItem)

	def addScreen (self, screen, idx=-1, select=True):
		item = ScreenGraphicItem (screen, self)
		self.levelViewScene.addItem (item)

		if select:
			self.projectModified = True
			self.saveCurrentItem ()

			self.levelViewScene.clearSelection ()
			item.setSelected (True)
			self.currentItem = item
			if idx == -1:
				idx = self.project['screens'].index (item.config)
			self.currentItemIndex = idx
			self.populateScreenPropertiesList ()

			self.loadCurrentItem ()

		self.setProjectModified ()	

	def removeScreen (self, item):
		self.project['screens'].remove (item.config)
		self.levelViewScene.removeItem (item)
		if self.currentItem is item:
			self.currentItem = None
			self.currentItemIndex = -1
			self.screenPropertiesList.clear ()

			self.loadCurrentItem ()

		self.setProjectModified ()
		del item

	def findScreenItemWithConfig (self, config):
		item = None
		for i in self.levelViewScene.items ():
			if isinstance (i, ScreenGraphicItem) and i.config is config:
				item = i
				break
		return item

	#--------------------------------------------------------------------------
	# level

	def populateLevelPropertiesList (self):
		self.populatePropertiesList (self.levelPropertiesList, self.project, LEVEL_PROPERTIES_TYPES)

	def levelPropertiesListItemChanged (self, item):
		self.propertiesListItemChanged (self.levelPropertiesList, self.project, LEVEL_PROPERTIES_TYPES, item)

		if item.column () != 1: return

		name = str (self.levelPropertiesList.item (item.row (), 0).text ())
		if name == 'name':
			sitem = self.levelPropertiesList.item (item.row (), 1)
			sitem.setText (item.text ())
			self.updateInfoLabel ()

		if name in ('borderSideTopColor', 'borderSideBottomColor', 'borderSideLeftColor', 'borderSideRightColor'):
			for i in self.levelViewScene.items ():
				if isinstance (i, ScreenGraphicItem):
					i.update (i.boundingRect ())
					
	def levelPropertiesListSelectRow (self, modelIndex):
		pass

	#--------------------------------------------------------------------------
	# screens

	def currentScreenConfig (self):
		if self.currentItem and self.currentItem.kind == "Screen":
			config = self.currentItem.config
		else:
			config = None
		return config

	def screensListItemChanged (self, item):
		pass

	def screensListSelectRow (self, item, full=True):
		self.__disable_item_update += 1

		self.saveCurrentItem ()

		oi = self.currentItem

		self.currentItemIndex = item.row ()
		self.currentItem = self.findScreenItemWithConfig (self.project['screens'][self.currentItemIndex])
		if oi is self.currentItem:
			self.__disable_item_update -= 1
			return

		if full:
			if oi:
				oi.setSelected (False)
			if self.currentItem:
				self.currentItem.setSelected (True)

		self.propertiesTabWidget.setCurrentIndex (1)
		self.populateScreenPropertiesList ()
		self.updateInfoLabel ()
		self.showCurrentScreen ()

		self.loadCurrentItem ()
		self.enableActions ()

		self.__disable_item_update -= 1

	def populatePaddlePropertiesList (self):
		paddle = self.currentPaddleConfig ()
		self.populatePropertiesList (self.paddlePropertiesList, paddle, PADDLE_PROPERTIES_TYPES)

		if self.applyPaddlePropertiesListState:
			settings = QtCore.QSettings ()
			self.paddlePropertiesList.horizontalHeader ().restoreState (settings.value ("PropertiesTabs/PaddlePropertiesListState").toByteArray ())
			self.applyPaddlePropertiesListState = False

	def populateScreenPropertiesList (self):
		#self.__disable_item_update += 1
		screen = self.currentScreenConfig ()
		self.populatePropertiesList (self.screenPropertiesList, screen, SCREEN_PROPERTIES_TYPES)
		#self.__disable_item_update -= 1

		if self.applyScreenPropertiesListState:
			settings = QtCore.QSettings ()
			self.screenPropertiesList.horizontalHeader ().restoreState (settings.value ("PropertiesTabs/ScreenPropertiesListState").toByteArray ())
			self.applyScreenPropertiesListState = False

	def screenPropertiesListItemChanged (self, item):
		if self.__disable_item_update:
			return
		screen = self.currentScreenConfig ()
		self.propertiesListItemChanged (self.screenPropertiesList, screen, SCREEN_PROPERTIES_TYPES, item)

		if item.column () != 1: return

		name = str (self.screenPropertiesList.item (item.row (), 0).text ())

		if self.currentItem and name in SCREEN_UPDATE_FIELDS:
			self.currentItem.configUpdated ()
			
	def screenPropertiesListSelectRow (self, item):
		pass

	#--------------------------------------------------------------------------
	# paddle

	def currentPaddleConfig (self):
		if self.currentItem and self.currentItem.kind == "Paddle":
			config = self.currentItem.config
		else:
			config = None
		return config

	def populatePaddlePropertiesList (self):
		paddle = self.currentPaddleConfig ()
		self.populatePropertiesList (self.paddlePropertiesList, paddle, PADDLE_PROPERTIES_TYPES)

		if self.applyPaddlePropertiesListState:
			settings = QtCore.QSettings ()
			self.paddlePropertiesList.horizontalHeader ().restoreState (settings.value ("PropertiesTabs/PaddlePropertiesListState").toByteArray ())
			self.applyPaddlePropertiesListState = False

	def paddlePropertiesListItemChanged (self, item):
		paddle = self.currentPaddleConfig ()
		self.propertiesListItemChanged (self.paddlePropertiesList, paddle, PADDLE_PROPERTIES_TYPES, item)

		if item.column () != 1: return

		self.currentItem.configUpdated ()

	def paddlePropertiesListSelectRow (self, modelIndex):
		pass

	#--------------------------------------------------------------------------
	# extensions

	def onExtAddLightsArray (self):
		self.extensionsEditor.insertPlainText (EXT_LIGHTS_ARRAY)
		self.setProjectModified ()

	def onExtAddLight (self):
		if self.currentItem.kind == "Screen":
			d = EXT_SCREEN_LIGHT
		else:
			d = EXT_PADDLE_LIGHT

		self.extensionsEditor.insertPlainText (d)
		self.setProjectModified ()

	#--------------------------------------------------------------------------
	# event handlers

	def enableActions (self):
		if self.currentItem:
			cc = True
		else:
			cc = False

		if self.copiedItem:
			p = True
		else:
			p = False

		self.actionCopy.setEnabled (cc)
		self.actionCut.setEnabled (cc)
		self.actionPaste.setEnabled (p)

		self.actionExtAddLightsArray.setEnabled (cc)
		self.actionExtAddLight.setEnabled (cc)

		fs = False
		pa = False
		if cc:
			if self.currentItem.kind == 'Screen':
				fs = True
			else:
				pa = True
		self.actionScreenFillField.setEnabled (True)
		self.actionScreenSetFirst.setEnabled (fs)

		self.actionPaddleFillField.setEnabled (True)
		self.actionPaddleFillDefensiveAIData.setEnabled (pa)
		self.actionPaddleAddHandlerOnTransition.setEnabled (pa)
		self.actionPaddleAddHandlerOnClick.setEnabled (pa)
		self.actionPaddleAddHandlerOnTouch.setEnabled (pa)
		self.actionPaddleAddHandlerOnHit.setEnabled (pa)

		self.actionPaddleResizeTL.setEnabled (pa)
		self.actionPaddleResizeTR.setEnabled (pa)
		self.actionPaddleResizeBL.setEnabled (pa)
		self.actionPaddleResizeBR.setEnabled (pa)
		self.actionPaddleResizeT.setEnabled (pa)
		self.actionPaddleResizeL.setEnabled (pa)
		self.actionPaddleResizeB.setEnabled (pa)
		self.actionPaddleResizeR.setEnabled (pa)
		self.actionPaddleMove.setEnabled (pa)

		self.actionPaddleSetMinX.setEnabled (pa)
		self.actionPaddleSetMaxX.setEnabled (pa)
		self.actionPaddleSetMinY.setEnabled (pa)
		self.actionPaddleSetMaxY.setEnabled (pa)

		self.actionProjectSave.setEnabled (self.projectModified)

	def onCopy (self):
		if self.currentItem:
			self.copiedItemKind = self.currentItem.kind
			self.copiedItem = copy.deepcopy (self.currentItem.config)
			self.enableActions ()

	def onCut (self):
		self.onCopy ()
		if self.currentItem:
			if self.currentItem.kind == 'Screen':
				self.removeScreen (self.currentItem)
			elif self.currentItem.kind == 'Paddle':
				self.removePaddle (self.currentItem)

	def onPaste (self):
		if self.copiedItem:
			if self.copiedItemKind == 'Screen':
				x, y = self.newScreenPosition ()
				i = copy.deepcopy (self.copiedItem)
				i['positionX'] = x
				i['positionY'] = y
				self.project['screens'].append (i)
				self.addScreen (i, idx = len (self.project['screens']) - 1)
			elif self.copiedItemKind == 'Paddle':
				x, y = self.newPaddlePosition ()
				i = copy.deepcopy (self.copiedItem)
				i['positionX'] = x
				i['positionY'] = y
				self.project['paddles'].append (i)
				self.addPaddle (i, idx = len (self.project['paddles']) - 1)


	#--------------------------------------------------------------------------
	# utilities

	def saveCurrentItem (self):
		if self.currentItem == None:
			self.project['scripts'] = str (self.scriptsEditor.toPlainText ())
			self.project['extensions'] = str (self.extensionsEditor.toPlainText ())
		else:
			self.currentItem.config['scripts'] = str (self.scriptsEditor.toPlainText ())
			self.currentItem.config['extensions'] = str (self.extensionsEditor.toPlainText ())
		self.setProjectModified ()

	def loadCurrentItem (self):
		self.__disable_item_update += 1
		if self.currentItem == None:
			self.scriptsEditor.setPlainText (self.project['scripts'])
			self.extensionsEditor.setPlainText (self.project['extensions'])
			self.extrasDock.setWindowTitle ("Level Extras")
		else:
			self.scriptsEditor.setPlainText (self.currentItem.config['scripts'])
			self.extensionsEditor.setPlainText (self.currentItem.config['extensions'])

			self.extrasDock.setWindowTitle ("%s[%s] Extras" % (self.currentItem.kind, self.currentItemIndex))
		self.__disable_item_update -= 1

	def onEditorChanged (self):
		if self.__disable_item_update:
			return
		self.setProjectModified ()

	GRID_X = 10
	GRID_Y = 10

	def moveCurrentItem (self, x, y, step=1):
		if self.currentItem:
			px = self.currentItem.pos ().x () 
			py = self.currentItem.pos ().y () 

			if self.moveItemMode != kModeMove and self.currentItem.kind == "Paddle":
				dx = x * step
				dy = y * step

				if self.moveItemMode == kModeResizeTL:
					self.currentItem.config['positionX'] += dx
					self.currentItem.config['positionY'] += dy
					self.currentItem.config['width'] += -dx
					self.currentItem.config['height'] += -dy
				elif self.moveItemMode == kModeResizeBL:
					self.currentItem.config['positionX'] += dx
					self.currentItem.config['width'] += -dx
					self.currentItem.config['height'] += dy
				elif self.moveItemMode == kModeResizeTR:
					self.currentItem.config['positionY'] += dy
					self.currentItem.config['width'] += dx
					self.currentItem.config['height'] += -dy
				elif self.moveItemMode == kModeResizeBR:
					self.currentItem.config['width'] += dx
					self.currentItem.config['height'] += dy
				elif self.moveItemMode == kModeResizeT:
					self.currentItem.config['positionY'] += dy
					self.currentItem.config['height'] += -dy
				elif self.moveItemMode == kModeResizeB:
					self.currentItem.config['height'] += dy
				elif self.moveItemMode == kModeResizeL:
					self.currentItem.config['positionX'] += dx
					self.currentItem.config['width'] += -dx
				elif self.moveItemMode == kModeResizeR:
					self.currentItem.config['width'] += dx

				self.currentItem.configUpdated ()
				self.onPaddleUpdateSize (self.currentItem)
			else:
				if step == -1:
					# snap to grid
					if (px % self.GRID_X and x == -1):
						px = px - (px % self.GRID_X)
					else:
						px = (px - (px % self.GRID_X)) + (self.GRID_X * x)
					if (py % self.GRID_Y and y == -1):
						py = py - (py % self.GRID_Y)
					else:
						py = (py - (py % self.GRID_Y)) + (self.GRID_Y * y)
				else:
					px = px + (x * step)
					py = py + (y * step)

				self.currentItem.setPos (QtCore.QPointF (px, py))

	def populatePropertiesList (self, plist, sourceData, types):
		plist.clear ()
		plist.setSortingEnabled (False)
		plist.setColumnCount (2)
		plist.setHorizontalHeaderLabels (['Name', 'Value'])

		if sourceData is None: return

		properties = filter (lambda x: not x.startswith ('__') and types[x] is not None, types.keys ())
		properties.sort (key=lambda x: types[x][1])

		plist.setRowCount (len (properties))
		plist.horizontalHeader ().setStretchLastSection (True)

		for row, name in enumerate (properties):
			# left column
			item = QtGui.QTableWidgetItem (name)
			flags = QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled
			item.setFlags (flags)
			plist.setItem (row, 0, item)

			# right column
			flags = QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled | QtCore.Qt.ItemIsEditable
			kind = types[name][0]
			data = sourceData.get (name, None)
			item = None

			if kind == tColor:
				if data is None: data = "255,255,255"
				widget = ColorButton (data, plist, row, 1)
				plist.setCellWidget (row, 1, widget)
				item = QtGui.QTableWidgetItem (str (data))
			elif kind is bool:
				if data is None: data = False
				item = QtGui.QTableWidgetItem ('')
				if data:
					item.setCheckState (QtCore.Qt.Checked)
				else:
					item.setCheckState (QtCore.Qt.Unchecked)

				flags = QtCore.Qt.ItemIsUserCheckable | QtCore.Qt.ItemIsSelectable | QtCore.Qt.ItemIsEnabled
			elif kind is basestring or kind is str or kind is unicode:
				if data is None: data = ""
				item = QtGui.QTableWidgetItem (str (data))
			elif kind is int:
				if data is None: data = 0
				item = QtGui.QTableWidgetItem (str (data))
			elif kind is float:
				if data is None: data = 0
				item = QtGui.QTableWidgetItem (str (data))

			if item:
				item.setFlags (flags)
				plist.setItem (row, 1, item)

	def propertiesListItemChanged (self, plist, sourceData, types, item):
		if item.column () != 1: return

		name = str (plist.item (item.row (), 0).text ())
		kind = types[name][0]
		data = None

		if kind == tColor:
			data = str (item.text ())
			color = strToQColor (data)
			item.setBackground (QtGui.QBrush (color))
		elif kind is bool:
			data = item.checkState () == QtCore.Qt.Checked
		elif kind is basestring or kind is str or kind is unicode:
			data = str (item.text ())
		elif kind is int:
			data = int (item.text ())
		elif kind is float:
			data = float (item.text ())

		sourceData[name] = data
		self.setProjectModified ()

	def isOkToClose (self):
		return self.handleModifiedProject ()

	def updateInfoLabel (self):
		if self.infoLabel is None: return

		if self.currentItem:
			x = self.currentItem.pos ().x ()
			y = self.currentItem.pos ().y ()
		else:
			x = 0
			y = 0

		projectName = self.project and self.project['name'] or 'UNKNOWN'
		if self.currentItem == None:
			item = 'Level'
		else:
			if self.currentItem.kind == 'Screen':
				item = 'Screen [%d/%d]' % (self.currentItemIndex, len (self.project['screens']))
			else:
				item = 'Paddle [%d/%d]' % (self.currentItemIndex, len (self.project['paddles']))
		s = "Zoom:%(zoom).2f Pos:[%(x)d, %(y)d] Level:%(levelName)s Item:%(item)s" % {
			'levelName': projectName,
			'item': item,
			'x': x,
			'y': y,
			'zoom': self.currentScale,
		}
		self.infoLabel.setText (s)


	def fieldDialog (self, fields):
		field = None
		data = None

		dlg = FieldDialog (self, fields)
		dlg.exec_ ()
		if dlg.result () == QtGui.QDialog.Accepted:
			field, data = dlg.getFieldData ()
		dlg.close ()

		return field, data

if __name__ == '__main__':

	import sys

	app = QtGui.QApplication (sys.argv)
	app.setOrganizationName ('Kismik')
	app.setOrganizationDomain ('kismik.com')
	app.setApplicationName ('Be2 Level Editor')
	app.setWindowIcon (QtGui.QIcon ('resources/icon.png'))

	mainWin = MainWindow ()
	mainWin.setFocus ()
	mainWin.show ()
	mainWin.raise_ ()
	sys.exit (app.exec_ ())

