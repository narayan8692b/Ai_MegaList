package com.docscanner.shared.platform

import com.docscanner.shared.domain.platform.SecureStorage
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.value
import platform.CoreFoundation.CFDictionaryCreate
import platform.CoreFoundation.CFDictionaryRef
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
import kotlinx.cinterop.CValuesRef
import kotlinx.cinterop.COpaquePointer
import kotlinx.cinterop.cValuesOf

/**
 * iOS [SecureStorage] backed by the Keychain (kSecClassGenericPassword items). Each entry is
 * stored under a fixed service identifier with the supplied key as the account; values are
 * UTF-8 encoded.
 *
 * Interop notes: Keychain queries are CFDictionaries. We build them with [CFDictionaryCreate]
 * passing the Security framework's CF string constants directly as keys (they are immortal CF
 * singletons we must NOT release) and CF-bridged values. Bridged values created via
 * [CFBridgingRetain] are released with [CFBridgingRelease] once the query is consumed.
 */
@OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)
class IosSecureStorage : SecureStorage {

    private val service = "com.docscanner.shared.securestorage"

    override fun putString(key: String, value: String) {
        // Upsert semantics: delete any existing item, then add the new one.
        remove(key)
        val data = CFBridgingRetain(value.toNSData())
        try {
            val query = buildQuery(
                keys = listOf(kSecClass, kSecAttrService, kSecAttrAccount, kSecValueData),
                values = listOf(
                    kSecClassGenericPassword,
                    CFBridgingRetain(service.toNSString()),
                    CFBridgingRetain(key.toNSString()),
                    data,
                ),
            )
            SecItemAdd(query, null)
            CFBridgingRelease(query as COpaquePointer?)
        } finally {
            CFBridgingRelease(data)
        }
    }

    override fun getString(key: String): String? = memScoped {
        val query = buildQuery(
            keys = listOf(kSecClass, kSecAttrService, kSecAttrAccount, kSecReturnData, kSecMatchLimit),
            values = listOf(
                kSecClassGenericPassword,
                CFBridgingRetain(service.toNSString()),
                CFBridgingRetain(key.toNSString()),
                kCFBooleanTrue,
                kSecMatchLimitOne,
            ),
        )
        val result = alloc<CFTypeRefVar>()
        val status = SecItemCopyMatching(query, result.ptr)
        CFBridgingRelease(query as COpaquePointer?)
        if (status != errSecSuccess) return@memScoped null
        // result holds a retained CFDataRef; CFBridgingRelease transfers it to NSData (ARC).
        val nsData = CFBridgingRelease(result.value) as? NSData ?: return@memScoped null
        nsData.toKString()
    }

    override fun remove(key: String) {
        val query = buildQuery(
            keys = listOf(kSecClass, kSecAttrService, kSecAttrAccount),
            values = listOf(
                kSecClassGenericPassword,
                CFBridgingRetain(service.toNSString()),
                CFBridgingRetain(key.toNSString()),
            ),
        )
        SecItemDelete(query)
        CFBridgingRelease(query as COpaquePointer?)
    }

    override fun clear() {
        val query = buildQuery(
            keys = listOf(kSecClass, kSecAttrService),
            values = listOf(kSecClassGenericPassword, CFBridgingRetain(service.toNSString())),
        )
        SecItemDelete(query)
        CFBridgingRelease(query as COpaquePointer?)
    }

    // --- interop helpers -------------------------------------------------

    /**
     * Build a CFDictionary from parallel [keys]/[values] lists of CF references. The returned
     * dictionary is +1 retained; callers release it with [CFBridgingRelease] after use.
     */
    private fun buildQuery(
        keys: List<COpaquePointer?>,
        values: List<COpaquePointer?>,
    ): CFDictionaryRef? = memScoped {
        require(keys.size == values.size)
        val keyArray = allocArrayOfPointers(keys)
        val valueArray = allocArrayOfPointers(values)
        CFDictionaryCreate(
            allocator = null,
            keys = keyArray,
            values = valueArray,
            numValues = keys.size.toLong(),
            keyCallBacks = kCFTypeDictionaryKeyCallBacks.ptr,
            valueCallBacks = kCFTypeDictionaryValueCallBacks.ptr,
        )
    }

    private fun kotlinx.cinterop.MemScope.allocArrayOfPointers(
        items: List<COpaquePointer?>,
    ): CValuesRef<COpaquePointerVar> {
        val array = allocArray<COpaquePointerVar>(items.size)
        items.forEachIndexed { index, ptr -> array[index] = ptr }
        return array
    }

    private fun String.toNSData(): NSData =
        (this as NSString).dataUsingEncoding(NSUTF8StringEncoding)!!

    private fun String.toNSString(): NSString = this as NSString

    private fun NSData.toKString(): String? =
        NSString.create(this, NSUTF8StringEncoding) as String?
}
