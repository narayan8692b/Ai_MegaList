# ---------------------------------------------------------------------------
# DocScanner ProGuard / R8 rules
# ---------------------------------------------------------------------------

# Koin --------------------------------------------------------------------
-keep class org.koin.** { *; }
-keep class * extends org.koin.core.module.Module { *; }
-keepnames class * { @org.koin.core.annotation.* *; }
-dontwarn org.koin.**

# SQLDelight --------------------------------------------------------------
-keep class app.cash.sqldelight.** { *; }
-keep class com.docscanner.shared.database.** { *; }
-dontwarn app.cash.sqldelight.**

# Ktor + OkHttp -----------------------------------------------------------
-keep class io.ktor.** { *; }
-keepclassmembers class io.ktor.** { volatile <fields>; }
-dontwarn io.ktor.**
-dontwarn org.slf4j.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ML Kit text recognition -------------------------------------------------
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# kotlinx.serialization ---------------------------------------------------
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keep,includedescriptorclasses class com.docscanner.**$$serializer { *; }
-keepclassmembers class com.docscanner.** {
    *** Companion;
}
-keepclasseswithmembers class com.docscanner.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep class kotlinx.serialization.** { *; }
-dontwarn kotlinx.serialization.**

# Coroutines --------------------------------------------------------------
-dontwarn kotlinx.coroutines.**

# AndroidX security / biometric (reflection-based) ------------------------
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Keep platform model classes referenced reflectively ---------------------
-keep class com.docscanner.shared.domain.model.** { *; }
