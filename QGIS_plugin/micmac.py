# -*- coding: utf-8 -*-
"""
/***************************************************************************
 MicMac_SFM
                                 A QGIS plugin
 This plugin facilitates use of the MicMac Structure from Motion Library
                              -------------------
        begin                : 2019-01-15
        git sha              : $Format:%H$
        copyright            : (C) 2019 by Ciaran Robb
        email                : ciaran.robb@gmail.com
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""
from PyQt4.QtCore import QSettings, QTranslator, qVersion, QCoreApplication
from PyQt4.QtGui import QAction, QIcon, QPushButton
from subprocess import check_call
# Initialize Qt resources from file resources.py
import resources
# Import the code for the dialog
from micmac_dialog import MicMac_SFMDialog
import os.path

from qgis.core import QgsMessageLog

import platform

if platform.system() == 'WINDOWS':
    mm3d = 'mm3d.exe'
else:
    mm3d = "/home/ciaran/micmac/bin/mm3d"

def sExif(mm3d):

     cmd = [mm3d,'vSetExif']
     check_call(cmd)
                        
def gp2txt(mm3d):
    
    cmd = [mm3d, 'vXifGps2Txt']
    check_call(cmd)

def gp2xml(mm3d):
    
    cmd = [mm3d, 'vXifGps2Xml']
    check_call(cmd)

def oriconv(mm3d):
    
    cmd = [mm3d, 'vOriConvert']
    check_call(cmd)

# matching and orientation    
def tapi(mm3d):
    
    cmd = [mm3d, 'vTapioca']
    check_call(cmd)

def schnap(mm3d):
    cmd = [mm3d, 'vSchnaps']
    check_call(cmd)
    
def taps(mm3d):
    
    cmd = [mm3d, 'vTapas']
    check_call(cmd)
def campi(mm3d):
    
    cmd = [mm3d, 'vCampari']
    check_call(cmd)

def centBasc(mm3d):
    
    cmd = [mm3d, 'vCenterBascule']
    check_call(cmd)
    
def chSysCoord(mm3d):
    
    cmd = [mm3d, 'vChgSysCo']
    check_call(cmd)

# editing
def saisemask(mm3d):
    
    cmd = [mm3d, 'vSaisieMasqQT']
    check_call(cmd)

# dense cloud and DSM etc
def malT(mm3d):
    
    cmd = [mm3d, 'vMalt']
    check_call(cmd)

def pimS(mm3d):
    
    cmd = [mm3d, 'vPIMs']
    check_call(cmd)
    
def pm2mnt(mm3d):
    
    cmd = [mm3d, 'vPIMs2MNT']
    check_call(cmd)

def c3d(mm3d):
    
    cmd = [mm3d, 'vC3DC']
    check_call(cmd)

# point cloud and mesh generation

def aperiC(mm3d):
    
    cmd = [mm3d, 'vAperiCloud']
    check_call(cmd)

def nuageP(mm3d):
    
    cmd = [mm3d, 'vNuage2PLY']
    check_call(cmd)

def tpunch(mm3d):
    
    cmd = [mm3d, 'vTiPunch']
    check_call(cmd)

def tquila(mm3d):
    
    cmd = [mm3d, 'vTequila']
    check_call(cmd)


class MicMac_SFM:
    """QGIS Plugin Implementation."""

    def __init__(self, iface):
        """Constructor.

        :param iface: An interface instance that will be passed to this class
            which provides the hook by which you can manipulate the QGIS
            application at run time.
        :type iface: QgisInterface
        """
        # Save reference to the QGIS interface
        self.iface = iface
        # initialize plugin directory
        self.plugin_dir = os.path.dirname(__file__)
        # initialize locale
        locale = QSettings().value('locale/userLocale')[0:2]
        locale_path = os.path.join(
            self.plugin_dir,
            'i18n',
            'MicMac_SFM_{}.qm'.format(locale))

        if os.path.exists(locale_path):
            self.translator = QTranslator()
            self.translator.load(locale_path)

            if qVersion() > '4.3.3':
                QCoreApplication.installTranslator(self.translator)


        # Declare instance attributes
        self.actions = []
        self.menu = self.tr(u'&MicMac_SFM')
        # TODO: We are going to let the user set this up in a future iteration
        self.toolbar = self.iface.addToolBar(u'MicMac_SFM')
        self.toolbar.setObjectName(u'MicMac_SFM')

    # noinspection PyMethodMayBeStatic
    def tr(self, message):
        """Get the translation for a string using Qt translation API.

        We implement this ourselves since we do not inherit QObject.

        :param message: String for translation.
        :type message: str, QString

        :returns: Translated version of message.
        :rtype: QString
        """
        # noinspection PyTypeChecker,PyArgumentList,Pycheck_callByClass
        return QCoreApplication.translate('MicMac_SFM', message)


    def add_action(
        self,
        icon_path,
        text,
        check_callback,
        enabled_flag=True,
        add_to_menu=True,
        add_to_toolbar=True,
        status_tip=None,
        whats_this=None,
        parent=None):
        """Add a toolbar icon to the toolbar.

        :param icon_path: Path to the icon for this action. Can be a resource
            path (e.g. ':/plugins/foo/bar.png') or a normal file system path.
        :type icon_path: str

        :param text: Text that should be shown in menu items for this action.
        :type text: str

        :param check_callback: Function to be check_called when the action is triggered.
        :type check_callback: function

        :param enabled_flag: A flag indicating if the action should be enabled
            by default. Defaults to True.
        :type enabled_flag: bool

        :param add_to_menu: Flag indicating whether the action should also
            be added to the menu. Defaults to True.
        :type add_to_menu: bool

        :param add_to_toolbar: Flag indicating whether the action should also
            be added to the toolbar. Defaults to True.
        :type add_to_toolbar: bool

        :param status_tip: Optional text to show in a popup when mouse pointer
            hovers over the action.
        :type status_tip: str

        :param parent: Parent widget for the new action. Defaults None.
        :type parent: QWidget

        :param whats_this: Optional text to show in the status bar when the
            mouse pointer hovers over the action.

        :returns: The action that was created. Note that the action is also
            added to self.actions list.
        :rtype: QAction
        """

        # Create the dialog (after translation) and keep reference
        self.dlg = MicMac_SFMDialog()

        icon = QIcon(icon_path)
        action = QAction(icon, text, parent)
        action.triggered.connect(check_callback)
        action.setEnabled(enabled_flag)

        if status_tip is not None:
            action.setStatusTip(status_tip)

        if whats_this is not None:
            action.setWhatsThis(whats_this)

        if add_to_toolbar:
            self.toolbar.addAction(action)

        if add_to_menu:
            self.iface.addPluginToMenu(
                self.menu,
                action)

        self.actions.append(action)

        return action

    def initGui(self):
        """Create the menu entries and toolbar icons inside the QGIS GUI."""

        icon_path = ':/plugins/MicMac_SFM/icon.png'
        self.add_action(
            icon_path,
            text=self.tr(u'MicMac3D'),
            check_callback=self.run,
            parent=self.iface.mainWindow())
        
        self.dlg.setexif.clicked.connect(self.run)
        self.dlg.gps2txt.clicked.connect(self.run)


    def unload(self):
        """Removes the plugin menu item and icon from QGIS GUI."""
        for action in self.actions:
            self.iface.removePluginMenu(
                self.tr(u'&MicMac_SFM'),
                action)
            self.iface.removeToolBarIcon(action)
        # remove the toolbar
        del self.toolbar
    
    # Before we go any further, the OS must be identified
    # as silly people using windows need a different start to the command check_call
        
    # Here define all the subprocess check_calls to the micmac qt commands
    # I imagine there is a less ugly way so will change infuture
    
    # prelim
    
   

        
    def run(self):
        """Run method that performs all the real work"""
        # show the dialog
        self.dlg.show()
        # Run the dialog event loop
        
        
        
        result = self.dlg.exec_()
        # See if OK was pressed

        
        
        if result:
            sExif(mm3d)
            
            gp2txt(mm3d)
            
        else:

            pass
 
        