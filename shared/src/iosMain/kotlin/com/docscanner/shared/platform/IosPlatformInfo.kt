package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.PlatformInfo
import platform.UIKit.UIDevice

/** iOS [PlatformInfo] implementation backed by [UIDevice]. */
class IosPlatformInfo : PlatformInfo {
    override val name: String =
        UIDevice.currentDevice.systemName + " " + UIDevice.currentDevice.systemVersion
    override val isAndroid: Boolean = false
    override val isIos: Boolean = true
}
