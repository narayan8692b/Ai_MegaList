package com.docscanner.shared.di

import org.koin.core.KoinApplication
import org.koin.core.context.startKoin
import org.koin.dsl.KoinAppDeclaration

/**
 * Initializes the Koin dependency graph. Called from the Android `Application` and from
 * the iOS app entry point. [appDeclaration] lets the Android side inject `androidContext`.
 */
fun initKoin(appDeclaration: KoinAppDeclaration = {}): KoinApplication =
    startKoin {
        appDeclaration()
        modules(
            platformModule(),
            dataModule,
            useCaseModule,
            viewModelModule,
        )
    }

/** Convenience entry point for iOS, which cannot pass a Koin declaration lambda easily. */
fun initKoinIos(): KoinApplication = initKoin()
