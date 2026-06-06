package com.docscanner.shared.domain.model

/** A folder used to organize [Document]s. */
data class Folder(
    val id: String,
    val name: String,
    val parentId: String?,
    val color: Long?,
    val createdAt: Long,
    val documentCount: Int = 0,
)
