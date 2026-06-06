package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.SecureStorage
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.CValuesRef
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.value
import platform.CoreFoundation.CFDictionaryRef
import platform.CoreFoundation.CFStringRef
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFBooleanTrue
import platform.Foundation.CFBridgingRelease
import platform.Foundation.CFBridgingRetain
import platform.Foundation.NSData
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.create
import platform.Foundation.dataUsingEncoding
import platform.Security.SecItemAdd
import platform.Security.SecItemCopyMatching
import platform.Security.SecItemDelete
import platform.Security.errSecSuccess
import platform.Security.kSecAttrAccount
import platform.Security.kSecAttrService
import platform.Security.kSecClass
import platform.Security.kSecClassGenericPassword
import platform.Security.kSecMatchLimit
import platform.Security.kSecMatchLimitOne
import platform.Security.kSecReturnData
import platform.Security.kSecValueData
import platform.darwin.OSStatus

/**
 * iOS [SecureStorage] backed by the Keychain (kSecClassGenericPassword items). Each key is
 * stored as a generic-password item with a fixed service identifier and the key as the
 * account. Values are UTF-8 encoded.
 *
 * Interop notes: Keychain APIs take `CFDictionaryRef`. We build the query as an NSDictionary
 * and bridge it to CoreFoundation with [CFBridgingRetain] / release the result with
 * [CFBridgingRelease]. All CF/Security calls are wrapped in @OptIn(ExperimentalForeignApi).
 */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
class IosSecureStorage : SecureStorage {

    private val service = "com.docscanner.shared.securestorage"

    override fun putString(key: String, value: String) {
        // Upsert semantics: delete any existing item, then add the new one.
        remove(key)
        val data = value.toNSData()
        val query = mapOf<Any?, Any?>(
            bridge(kSecClass) to bridge(kSecClassGenericPassword),
            bridge(kSecAttrService) to service,
            bridge(kSecAttrAccount) to key,
            bridge(kSecValueData) to data,
        )
        SecItemAdd(query.toCFDictionary(), null)
    }

    override fun getString(key: String): String? = memScoped {
        val query = mapOf<Any?, Any?>(
            bridge(kSecClass) to bridge(kSecClassGenericPassword),
            bridge(kSecAttrService) to service,
            bridge(kSecAttrAccount) to key,
            bridge(kSecReturnData) to kCFBooleanTrue,
            bridge(kSecMatchLimit) to bridge(kSecMatchLimitOne),
        )
        val result = alloc<CFTypeRefVar>()
        val status: OSStatus = SecItemCopyMatching(query.toCFDictionary(), result.ptr)
        if (status != errSecSuccess) return@memScoped null
        // result now holds a retained CFDataRef bridged to NSData.
        val nsData = CFBridgingRelease(result.value) as? NSData ?: return@memScoped null
        nsData.toKString()
    }

    override fun remove(key: String) {
        val query = mapOf<Any?, Any?>(
            bridge(kSecClass) to bridge(kSecClassGenericPassword),
            bridge(kSecAttrService) to service,
            bridge(kSecAttrAccount) to key,
        )
        SecItemDelete(query.toCFDictionary())
    }

    override fun clear() {
        // Delete all generic-password items for this service.
        val query = mapOf<Any?, Any?>(
            bridge(kSecClass) to bridge(kSecClassGenericPassword),
            bridge(kSecAttrService) to service,
        )
        SecItemDelete(query.toCFDictionary())
    }

    // --- interop helpers -------------------------------------------------

    /** Bridge a CoreFoundation constant (CFStringRef) to an Objective-C object for the dict. */
    private fun bridge(ref: CFStringRef?): Any? = CFBridgingRelease(ref?.let { CFBridgingRetainNoOp(it) })

    /**
     * The Security framework constants are already +1 retained CF singletons; we must NOT
     * release them. We simply reinterpret them as Objective-C ids for the NSDictionary keys
     * by bridging without transferring ownership.
     */
    @Suppress("UNCHECKED_CAST")
    private fun CFBridgingRetainNoOp(ref: CFStringRef): CFStringRef = ref

    private fun String.toNSData(): NSData =
        (this as NSString).dataUsingEncoding(NSUTF8StringEncoding)!!

    private fun NSData.toKString(): String? =
        NSString.create(this, NSUTF8StringEncoding) as String?

    @Suppress("UNCHECKED_CAST")
    private fun Map<Any?, Any?>.toCFDictionary(): CValuesRef<CFDictionaryRef>? {
        // Build an NSDictionary then bridge to CFDictionaryRef. NSDictionary <-> CFDictionary
        // are toll-free bridged, so the cast is valid.
        val nsDict = platform.Foundation.NSMutableDictionary()
        for ((k, v) in this) {
            if (k != null && v != null) nsDict.setObject(v, forKey = k as platform.darwin.NSObjectProtocol)
        }
        return CFBridgingRetain(nsDict) as CValuesRef<CFDictionaryRef>?
    }
}
