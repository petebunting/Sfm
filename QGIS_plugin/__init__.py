# -*- coding: utf-8 -*-
"""
/***************************************************************************
 MicMac_SFM
                                 A QGIS plugin
 This plugin facilitates use of the MicMac Structure from Motion Library
                             -------------------
        begin                : 2019-01-15
        copyright            : (C) 2019 by Ciaran Robb
        email                : ciaran.robb@gmail.com
        git sha              : $Format:%H$
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 This script initializes the plugin, making it known to QGIS.
"""


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    """Load MicMac_SFM class from file MicMac_SFM.

    :param iface: A QGIS interface instance.
    :type iface: QgisInterface
    """
    #
    from .micmac import MicMac_SFM
    return MicMac_SFM(iface)
