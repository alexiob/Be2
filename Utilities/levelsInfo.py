import os
import cPickle
import plistlib
import subprocess

levelsPath = "../Docs/Levels"
levelsInfoPath = '../ResourcesApp/data/levels/levelsInfo.plist'

levelsInfo = {}

for i in os.listdir (levelsPath):
	if not i.endswith ('.b2p'): continue
	filename = os.path.join (levelsPath, i)
	f = open (filename, 'rb')
	data = cPickle.load (f)
	f.close ()
	
	levelsInfo[data['index']] = {
		'kind': data['kind'],
		'index': data['index'],
		'name': data['name'],
		'title': data['title'],
		'description': data['description'],
		'difficulty': data['difficulty'],
		'availableTime': data['availableTime'],
		'minimumScore': data['minimumScore'],
		'explorationPoints': data['explorationPoints'],
	}

plistlib.writePlist (levelsInfo, levelsInfoPath)
r = subprocess.Popen (['plutil', '-convert', 'binary1', levelsInfoPath])	
