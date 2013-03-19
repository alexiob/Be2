
from PyQt4 import QtCore, QtGui, Qt

from ConfigUtilities import tColor

class FieldDialog (QtGui.QDialog):
	def __init__ (self, parent, fields):
		super (FieldDialog, self).__init__ (parent)
		
		self.fields = fields
		self.field = None
		self.data = None
		
		okButton = QtGui.QPushButton ("OK", self)
		self.connect (okButton, QtCore.SIGNAL ('clicked()'), self.accept)
		cancelButton = QtGui.QPushButton ("Cancel", self)
		self.connect (cancelButton, QtCore.SIGNAL ('clicked()'), self.reject)
		
		buttonsLayout = QtGui.QHBoxLayout ()
		buttonsLayout.addStretch ()
		buttonsLayout.addWidget (okButton)
		buttonsLayout.addWidget (cancelButton)
		
		fieldLabel = QtGui.QLabel ("Field:")
		self.fieldsCombobox = QtGui.QComboBox (self)
		self.fieldsCombobox.setEditable (False)
		self.fieldsCombobox.setSizePolicy (QtGui.QSizePolicy.Expanding, QtGui.QSizePolicy.Preferred)
		properties = filter (lambda x: not x.startswith ('__') and fields[x] is not None, fields.keys ())
		properties.sort (key=lambda x: fields[x][1])
		for i in properties:
			self.fieldsCombobox.addItem (i)

		dataLabel = QtGui.QLabel ("Data:")
		self.dataEdit = QtGui.QLineEdit (self)
		
		mainLayout = QtGui.QGridLayout (self)
		mainLayout.addWidget (fieldLabel, 0, 0)
		mainLayout.addWidget (self.fieldsCombobox, 0, 1, 1, 2)
		mainLayout.addWidget (dataLabel, 1, 0)
		mainLayout.addWidget (self.dataEdit, 1, 1, 1, 2)
		mainLayout.addLayout (buttonsLayout, 2, 0, 1,2)
		
		self.setWindowTitle ("Fill Field")
		
		self.connect (self, QtCore.SIGNAL ('accepted()'), self.accepted)
		
	def accepted (self):
		self.field = str (self.fieldsCombobox.currentText ())
		kind = self.fields[self.field][0]
		if kind == tColor:
			kind = str
		self.data = kind (str (self.dataEdit.text ()))
		
	def getFieldData (self):
		return self.field, self.data
	