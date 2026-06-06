package com.docscanner.shared.di

import org.koin.core.module.Module

/**
 * Each platform supplies its concrete implementations (database driver, image processor,
 * OCR engine, PDF generator, camera, biometrics, secure storage, cloud client, etc.)
 * through this module.
 */
expect fun platformModule(): Module
