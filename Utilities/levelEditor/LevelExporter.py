
import sys
import copy
import plistlib
import subprocess

from PyQt4 import QtCore

from Be2Definitions import *
from ConfigUtilities import *

class LevelExporter (object):
	def __init__ (self, config):
		self.config = copy.deepcopy (config)
		
	def findMaxY (self):
		my = -sys.maxint
		
		for paddle in self.config['paddles']:
			ty = paddle['positionY'] + paddle['height']
			if ty > my:
				my = ty

		for screen in self.config['screens']:
			ty = screen['positionY'] + screen['height']
			if ty > my:
				my = ty
	
		return my
	
	def convert (self):
		self.convertLevelFlags ()
		
		self.config['borderSideTopColor'] = self.normalizeColor (self.config.get ('borderSideTopColor', ''))
		self.config['borderSideBottomColor'] = self.normalizeColor (self.config.get ('borderSideBottomColor', ''))
		self.config['borderSideLeftColor'] = self.normalizeColor (self.config.get ('borderSideLeftColor', ''))
		self.config['borderSideRightColor'] = self.normalizeColor (self.config.get ('borderSideRightColor', ''))
		
		my = self.findMaxY ()
		
		for paddle in self.config['paddles']:
			self.convertPaddleYCoords (paddle, my)
			self.convertColor (paddle)
			self.convertPaddleFlags (paddle)
			self.convertPaddleLabel (paddle)
			self.convertPaddleTopImage (paddle)
			self.convertPaddleProximity (paddle)
			self.convertPaddleAI (paddle)
			self.convertExtensions (paddle)
			
		for screen in self.config['screens']:
			screen['positionY'] = my - screen['positionY'] - screen['height']
			
			self.convertColor (screen)
			self.convertScreenFlags (screen)
			screen['titleColor'] = self.normalizeColor (screen['titleColor'])
			screen['descriptionColor'] = self.normalizeColor (screen['descriptionColor'])
			screen['borderSideTopColor'] = self.normalizeColor (screen.get ('borderSideTopColor', ''))
			screen['borderSideBottomColor'] = self.normalizeColor (screen.get ('borderSideBottomColor', ''))
			screen['borderSideLeftColor'] = self.normalizeColor (screen.get ('borderSideLeftColor', ''))
			screen['borderSideRightColor'] = self.normalizeColor (screen.get ('borderSideRightColor', ''))
			
			for i in range (MAX_BG_IMAGES):
				self.convertBGImage (i, screen)
				
			self.convertExtensions (screen)
			
		self.convertExtensions (self.config)
		self.fillScreens ()

	def convertPaddleYCoords (self, data, my):
		data['positionY'] = my - data['positionY'] - data['height']
		y = data['minY']
		if data['maxY']:
			data['minY'] = my - data['maxY'] - data['height']
		if y:
			data['maxY'] = my - y - data['height']
			
	def convertExtensions (self, data):
		if 'extensions' in data:
			e = eval ('{%s}' % data.pop ('extensions'))
			data.update (e)

	def isPaddleInsideScreen (self, paddle, screen):
		r1 = QtCore.QRectF (
		    paddle['positionX'], paddle['positionY'],
		    paddle['width'], paddle['height']
		)
		r2 = QtCore.QRectF (
		    screen['positionX'], screen['positionY'],
		    screen['width'], screen['height']
		)
		return r1.intersects (r2)
		
	def fillScreenPaddles (self, screen):
		for idx, paddle in enumerate (self.config['paddles']):
			if self.isPaddleInsideScreen (paddle, screen):
				screen['paddles'].append (idx)

	def fillScreens (self):
		for screen in self.config['screens']:
			self.fillScreenPaddles (screen)
		
	def normalizeColor (self, c):
		return ','.join (map (lambda x: x.strip (), c.strip ().split (',')))
	
	def convertBGImage (self, idx, data):
		pass
	
	def convertColor (self, data):
		color = {
		    'mode': data.pop ('colorMode', 0),
		    'opacity': data.pop ('colorOpacity', 255),
		    'color1': self.normalizeColor (data.pop ('colorColor1', '255,255,255')),
		    'color2': self.normalizeColor (data.pop ('colorColor2', '0,0,0')),
		    'tintToDuration': data.pop ('colorTintToDuration', 0),
		}
		data['color'] = color
		
	def convertPaddleProximity (self, data):
		proximity = {
		    'mode': data.pop ('proximityMode', 0),
		    'width': data.pop ('proximityWidth', 0),
		    'height': data.pop ('proximityHeight', 0),
		    'accelerationX': data.pop ('proximityAccelerationX', 0),
		    'accelerationY': data.pop ('proximityAccelerationY', 0),
		}
		data['proximity'] = proximity
		
	def convertPaddleAI (self, data):
		ai = {
		    'defensiveKind': data.pop ('aiDefensiveKind', ''),
		    'defensiveConfig': data.pop ('aiDefensiveConfig', ''),
		    'offensiveKind': data.pop ('aiOffensiveKind', ''),
		    'offensiveConfig': data.pop ('aiOffensiveConfig', ''),
		}
		data['ai'] = ai
		
	def convertPaddleLabel (self, data):
		label = {
		    'font': data.pop ('labelFont', DEFAULT_PADDLE_FONT),
		    'fontSize': data.pop ('labelFontSize', DEFAULT_PADDLE_FONT_SIZE),
		    'color': self.normalizeColor (data.pop ('labelColor', DEFAULT_PADDLE_FONT_COLOR)),
		    'opacity': data.pop ('labelOpacity', DEFAULT_PADDLE_FONT_OPACITY),
		    'text': data.pop ('labelText', ''),
		}
		data['label'] = label
		
	def convertPaddleTopImage (self, data):
		img = {
		    'textureName': data.pop ('topImageName', ""),
		    'opacity': data.pop ('topImageOpacity', 255),
		    'rotation': data.pop ('topImageRotation', 0),
		    'width': data.pop ('topImageWidth', 0),
		    'height': data.pop ('topImageHeight', 0),
		    'positionX': data.pop ('topImagePositionX', 0.5),
		    'positionY': data.pop ('topImagePositionY', 0.5),
		    'anchorX': data.pop ('topImageAnchorX', 0.5),
		    'anchorY': data.pop ('topImageAnchorY', 0.5),
		}
		data['topImage'] = img
		
	def convertLevelFlags (self):
		flags = 0
		flags |= self.config.pop ('kLevelFlagLevelUpdate', 0) and kLevelFlagLevelUpdate or 0
		flags |= self.config.pop ('kLevelFlagScriptUpdate', 0) and kLevelFlagScriptUpdate or 0
		flags |= self.config.pop ('kLevelFlagShowHUD', 0) and kLevelFlagShowHUD or 0
		flags |= self.config.pop ('kLevelFlagDoNotStartBackgroundMusic', 0) and kLevelFlagDoNotStartBackgroundMusic or 0
		
		self.config['flags'] = flags
		
	def convertPaddleFlags (self, data):
		flags = 0
		flags |= data.pop ('kPaddleFlagOffensiveSide', 0) and kPaddleFlagOffensiveSide or 0
		flags |= data.pop ('kPaddleFlagCollisionDisabled', 0) and kPaddleFlagCollisionDisabled or 0
		flags |= data.pop ('kPaddleFlagBlockTouches', 0) and kPaddleFlagBlockTouches or 0
		flags |= data.pop ('kPaddleFlagScriptHandleTouches', 0) and kPaddleFlagScriptHandleTouches or 0
		flags |= data.pop ('kPaddleFlagIsButton', 0) and kPaddleFlagIsButton or 0
		flags |= data.pop ('kPaddleFlagSelected', 0) and kPaddleFlagSelected or 0
		flags |= data.pop ('kPaddleFlagEnabled', 0) and kPaddleFlagEnabled or 0
		flags |= data.pop ('kPaddleFlagIsInvisible', 0) and kPaddleFlagIsInvisible or 0
		flags |= data.pop ('kPaddleFlagScriptOnEnter', 0) and kPaddleFlagScriptOnEnter or 0
		flags |= data.pop ('kPaddleFlagScriptOnExit', 0) and kPaddleFlagScriptOnExit or 0
		flags |= data.pop ('kPaddleFlagScriptApplyProximityInfluenceToHero', 0) and kPaddleFlagScriptApplyProximityInfluenceToHero or 0
		flags |= data.pop ('kPaddleFlagScriptOnSideToggled', 0) and kPaddleFlagScriptOnSideToggled or 0
		flags |= data.pop ('kPaddleFlagScriptUpdate', 0) and kPaddleFlagScriptUpdate or 0
		flags |= data.pop ('kPaddleFlagScriptOnHeroInProxymityArea', 0) and kPaddleFlagScriptOnHeroInProxymityArea or 0
		flags |= data.pop ('kPaddleFlagNoPositionLimit', 0) and kPaddleFlagNoPositionLimit or 0
		flags |= data.pop ('kPaddleFlagIsGlobal', 0) and kPaddleFlagIsGlobal or 0
		data['flags'] = flags
		
	def convertScreenFlags (self, data):
		flags = 0
		flags |= data.pop ('kScreenFlagLeftSideClosed', 0) and kScreenFlagLeftSideClosed or 0
		flags |= data.pop ('kScreenFlagRightSideClosed', 0) and kScreenFlagRightSideClosed or 0
		flags |= data.pop ('kScreenFlagTopSideClosed', 0) and kScreenFlagTopSideClosed or 0
		flags |= data.pop ('kScreenFlagBottomSideClosed', 0) and kScreenFlagBottomSideClosed or 0
		flags |= data.pop ('kScreenFlagScriptUpdate', 0) and kScreenFlagScriptUpdate or 0
		flags |= data.pop ('kScreenFlagScriptOnEnter', 0) and kScreenFlagScriptOnEnter or 0
		flags |= data.pop ('kScreenFlagScriptOnExit', 0) and kScreenFlagScriptOnExit or 0
		
		data['flags'] = flags
		
	def export (self, filename):
		self.convert ()
		
		plistlib.writePlist (self.config, filename)
		r = subprocess.Popen (['plutil', '-convert', 'binary1', filename])
		