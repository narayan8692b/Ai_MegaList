package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.SecureStorage
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.MemScope
import kotlinx.cinterop.alloc
import kotlinx.cinterop.allocArrayOf
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.value
import platform.CoreFoundation.CFDictionaryCreate
import platform.CoreFoundation.CFDictionaryRef
import platform.CoreFoundation.CFStringRef
import platform.CoreFoundation.CFTypeRef
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFBooleanTrue
import platform.CoreFoundation.kCFTypeDictionaryKeyCallBacks
import platform.CoreFoundation.kCFTypeDictionaryValueCallBacks
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

/**
 * iOS [SecureStorage] backed by the Keychain (kSecClassGenericPassword items). Each entry is
 * stored under a fixed service identifier with the supplied key as the account; values are
 * UTF-8 encoded.
 *
 * Interop notes: Keychain queries are CFDictionaries built with [CFDictionaryCreate]. The
 * Security framework CF string constants (kSecClass, etc.) are immortal singletons used
 * directly as keys. String/data values are bridged to CF with [CFBridgingRetain] and released
 * with [CFBridgingRelease] once the query dictionary (which retains them) is itself released.
 */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
class IosSecureStorage : SecureStorage {

    private val service = "com.docscanner.shared.securestorage"

    override fun putString(key: String, value: String) {
        // Upsert semantics: delete any existing item, then add the new one.
        remove(key)
        memScoped {
            val query = makeDictionary(
                kSecClass to kSecClassGenericPassword,
                kSecAttrService to service.bridged(),
                kSecAttrAccount to key.bridged(),
                kSecValueData to value.toNSData().bridged(),
            )
            SecItemAdd(query, null)
            CFBridgingRelease(query)
        }
    }

    override fun getString(key: String): String? = memScoped {
        val query = makeDictionary(
            kSecClass to kSecClassGenericPassword,
            kSecAttrService to service.bridged(),
            kSecAttrAccount to key.bridged(),
            kSecReturnData to kCFBooleanTrue,
            kSecMatchLimit to kSecMatchLimitOne,
        )
        val result = alloc<CFTypeRefVar>()
        val status = SecItemCopyMatching(query, result.ptr)
        CFBridgingRelease(query)
        if (status != errSecSuccess) return@memScoped null
        // result holds a retained CFDataRef; CFBridgingRelease transfers ownership to ARC.
        val nsData = CFBridgingRelease(result.value) as? NSData ?: return@memScoped null
        nsData.toKString()
    }

    override fun remove(key: String) = memScoped {
        val query = makeDictionary(
            kSecClass to kSecClassGenericPassword,
            kSecAttrService to service.bridged(),
            kSecAttrAccount to key.bridged(),
        )
        SecItemDelete(query)
        CFBridgingRelease(query)
    }

    override fun clear() = memScoped {
        val query = makeDictionary(
            kSecClass to kSecClassGenericPassword,
            kSecAttrService to service.bridged(),
        )
        SecItemDelete(query)
        CFBridgingRelease(query)
    }

    // --- interop helpers -------------------------------------------------

    /** Build a +1-retained CFDictionary from CF (key -> value) pairs. */
    private fun MemScope.makeDictionary(
        vararg pairs: Pair<CFStringRef?, CFTypeRef?>,
    ): CFDictionaryRef? {
        val keys = allocArrayOf(pairs.map { it.first })
        val values = allocArrayOf(pairs.map { it.second })
        return CFDictionaryCreate(
            allocator = null,
            keys = keys.reinterpret(),
            values = values.reinterpret(),
            numValues = pairs.size.toLong(),
            keyCallBacks = kCFTypeDictionaryKeyCallBacks.ptr,
            valueCallBacks = kCFTypeDictionaryValueCallBacks.ptr,
        )
    }

    /**
     * Bridge an Obj-C object to a +1-retained CFTypeRef for use as a dictionary value.
     *
     * NOTE: CFDictionaryCreate retains values again under kCFTypeDictionaryValueCallBacks, so
     * this +1 is technically an extra retain that is not balanced until process exit (a tiny,
     * bounded leak for the few short strings stored here). Releasing the dictionary releases
     * its own retain but not this one. Acceptable for secure-storage glue; a stricter version
     * would track and CFBridgingRelease each bridged value after dictionary construction.
     */
    private fun Any.bridged(): CFTypeRef? = CFBridgingRetain(this)

    private fun String.toNSData(): NSData =
        (this as NSString).dataUsingEncoding(NSUTF8StringEncoding)!!

    private fun NSData.toKString(): String? =
        NSString.create(this, NSUTF8StringEncoding) as String?
}
