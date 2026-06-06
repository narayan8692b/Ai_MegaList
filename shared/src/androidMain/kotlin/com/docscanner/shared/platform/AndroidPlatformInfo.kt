package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.PlatformInfo

/** Android [PlatformInfo] implementation. */
class AndroidPlatformInfo : PlatformInfo {
    override val name: String = "Android"
    override val isAndroid: Boolean = true
    override val isIos: Boolean = false
}
