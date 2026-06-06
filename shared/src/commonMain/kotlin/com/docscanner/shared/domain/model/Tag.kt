package com.docscanner.shared.domain.model

/** A free-form label that can be attached to a [Document]. */
data class Tag(
    val id: String,
    val name: String,
    val color: Long? = null,
)
