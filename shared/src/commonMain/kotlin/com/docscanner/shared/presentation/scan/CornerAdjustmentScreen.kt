package com.docscanner.shared.presentation.scan

import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.AutoFixHigh
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.docscanner.shared.domain.model.DocumentCorners
import com.docscanner.shared.domain.model.PointF
import com.docscanner.shared.presentation.common.collectAsStateCompat
import com.docscanner.shared.presentation.components.PlatformImage
import org.koin.compose.viewmodel.koinViewModel
import kotlin.math.sqrt

/**
 * THE signature screen: the captured image is shown with four draggable corner handles. A
 * translucent quadrilateral connects them, the region outside the quad is shaded, and while a
 * corner is being dragged a circular magnifier lens shows a zoomed inset of the area around
 * the active corner for pixel-precise placement.
 *
 * Corners are stored normalized (0..1). They are mapped onto the displayed image rectangle
 * (which may be letter-boxed inside the canvas because the image uses [ContentScale.Fit]).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CornerAdjustmentScreen(
    onConfirmed: () -> Unit,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: CornerAdjustmentViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()

    LaunchedEffect(state.confirmed) {
        if (state.confirmed) {
            viewModel.onConfirmConsumed()
            onConfirmed()
        }
    }

    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text("Adjust Corners") },
                navigationIcon = {
                    androidx.compose.material3.IconButton(onClick = onBack) {
                        Icon(Icons.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
        bottomBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surface)
                    .padding(12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedButton(
                    onClick = viewModel::autoDetect,
                    enabled = !state.isProcessing,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.AutoFixHigh, contentDescription = null)
                    Text("Auto", modifier = Modifier.padding(start = 4.dp))
                }
                OutlinedButton(
                    onClick = viewModel::reset,
                    enabled = !state.isProcessing,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.Refresh, contentDescription = null)
                    Text("Reset", modifier = Modifier.padding(start = 4.dp))
                }
                Button(
                    onClick = viewModel::confirm,
                    enabled = !state.isProcessing,
                    modifier = Modifier.weight(1f),
                ) {
                    Icon(Icons.Filled.Check, contentDescription = null)
                    Text("Confirm", modifier = Modifier.padding(start = 4.dp))
                }
            }
        },
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .background(Color.Black),
            contentAlignment = Alignment.Center,
        ) {
            val capture = state.capture
            if (capture == null) {
                Text("No image to adjust", color = Color.White)
            } else {
                CornerEditor(
                    imagePath = capture.imagePath,
                    corners = state.corners,
                    onMove = viewModel::moveCorner,
                )
            }

            if (state.isProcessing) {
                CircularProgressIndicator(color = Color.White)
            }
            state.errorMessage?.let {
                Text(
                    it,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.align(Alignment.BottomCenter).padding(16.dp),
                )
            }
        }
    }
}

/**
 * The interactive editor surface: image + overlay canvas + drag handling + magnifier.
 */
@Composable
private fun CornerEditor(
    imagePath: String,
    corners: DocumentCorners,
    onMove: (CornerHandle, Float, Float) -> Unit,
) {
    val density = LocalDensity.current
    // Touch radius for grabbing a handle, in px.
    val grabRadiusPx = with(density) { 28.dp.toPx() }
    val handleRadiusPx = with(density) { 10.dp.toPx() }
    val magnifierRadiusPx = with(density) { 56.dp.toPx() }
    val magnifierZoom = 2.2f

    var canvasSize by remember { mutableStateOf(Size.Zero) }
    var activeHandle by remember { mutableStateOf<CornerHandle?>(null) }
    var activePoint by remember { mutableStateOf(Offset.Zero) }
    // Always read the freshest corners inside the long-lived gesture detector.
    val currentCorners by rememberUpdatedState(corners)

    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        // The image is drawn with ContentScale.Fit; we mirror that letter-box math so handle
        // positions line up exactly with the visible pixels.
        Box(
            modifier = Modifier
                .fillMaxSize()
                .onGloballyPositioned { canvasSize = Size(it.size.width.toFloat(), it.size.height.toFloat()) },
        ) {
            PlatformImage(
                path = imagePath,
                contentDescription = "Captured page",
                modifier = Modifier.fillMaxSize(),
            )

            // Overlay: quad + shading + handles, plus drag handling.
            androidx.compose.foundation.Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .pointerInput(canvasSize) {
                        detectDragGestures(
                            onDragStart = { pos ->
                                activeHandle = nearestHandle(pos, currentCorners, canvasSize, grabRadiusPx)
                                activePoint = pos
                            },
                            onDragEnd = { activeHandle = null },
                            onDragCancel = { activeHandle = null },
                            onDrag = { change, _ ->
                                change.consume()
                                val handle = activeHandle
                                if (handle != null && canvasSize.width > 0f && canvasSize.height > 0f) {
                                    val pos = change.position
                                    activePoint = pos
                                    onMove(
                                        handle,
                                        pos.x / canvasSize.width,
                                        pos.y / canvasSize.height,
                                    )
                                }
                            },
                        )
                    },
            ) {
                val w = size.width
                val h = size.height
                fun toPx(p: PointF) = Offset(p.x * w, p.y * h)
                val tl = toPx(corners.topLeft)
                val tr = toPx(corners.topRight)
                val br = toPx(corners.bottomRight)
                val bl = toPx(corners.bottomLeft)

                // Shade everything outside the quad using even-odd fill (full rect minus quad).
                val shade = Path().apply {
                    fillType = PathFillType.EvenOdd
                    addRect(Rect(0f, 0f, w, h))
                    moveTo(tl.x, tl.y)
                    lineTo(tr.x, tr.y)
                    lineTo(br.x, br.y)
                    lineTo(bl.x, bl.y)
                    close()
                }
                drawPath(shade, color = Color.Black.copy(alpha = 0.5f))

                // Crop quadrilateral outline.
                val quad = Path().apply {
                    moveTo(tl.x, tl.y)
                    lineTo(tr.x, tr.y)
                    lineTo(br.x, br.y)
                    lineTo(bl.x, bl.y)
                    close()
                }
                drawPath(quad, color = Color(0xFF4DB6AC), style = Stroke(width = 3f))

                // Corner handles.
                listOf(tl, tr, br, bl).forEach { c ->
                    drawCircle(Color.White, radius = handleRadiusPx, center = c)
                    drawCircle(Color(0xFF3F51B5), radius = handleRadiusPx, center = c, style = Stroke(width = 3f))
                }
            }

            // Magnifier lens: shown only while dragging. It renders a second copy of the image
            // scaled up and offset so the active corner sits at the lens center, clipped to a
            // circle. Positioned in the opposite vertical half to avoid the finger.
            val handle = activeHandle
            if (handle != null && canvasSize != Size.Zero) {
                Magnifier(
                    imagePath = imagePath,
                    focus = activePoint,
                    canvasSize = canvasSize,
                    radiusPx = magnifierRadiusPx,
                    zoom = magnifierZoom,
                )
            }
        }
    }
}

/** Pick the corner whose handle is within [grabRadiusPx] of [pos], or null. */
private fun nearestHandle(
    pos: Offset,
    corners: DocumentCorners,
    size: Size,
    grabRadiusPx: Float,
): CornerHandle? {
    if (size.width <= 0f || size.height <= 0f) return null
    fun px(p: PointF) = Offset(p.x * size.width, p.y * size.height)
    val candidates = listOf(
        CornerHandle.TOP_LEFT to px(corners.topLeft),
        CornerHandle.TOP_RIGHT to px(corners.topRight),
        CornerHandle.BOTTOM_RIGHT to px(corners.bottomRight),
        CornerHandle.BOTTOM_LEFT to px(corners.bottomLeft),
    )
    var best: CornerHandle? = null
    var bestDist = grabRadiusPx
    candidates.forEach { (handle, c) ->
        val d = sqrt((c.x - pos.x) * (c.x - pos.x) + (c.y - pos.y) * (c.y - pos.y))
        if (d <= bestDist) {
            bestDist = d
            best = handle
        }
    }
    return best
}

/**
 * Circular magnifier inset. Renders a second copy of the image, scaled by [zoom] and
 * translated (via [graphicsLayer]) so [focus] maps to the lens center, clipped to a circle.
 * Placed in the top-left or top-right margin (whichever is farther from the finger).
 */
@Composable
private fun Magnifier(
    imagePath: String,
    focus: Offset,
    canvasSize: Size,
    radiusPx: Float,
    zoom: Float,
) {
    val density = LocalDensity.current
    val diameterDp = with(density) { (radiusPx * 2).toDp() }
    val marginPx = with(density) { 16.dp.toPx() }

    // Lens placed opposite to the finger horizontally, pinned to the top.
    val lensLeftPx = if (focus.x < canvasSize.width / 2f) {
        canvasSize.width - radiusPx * 2 - marginPx
    } else {
        marginPx
    }
    val lensTopPx = marginPx
    val lensLeftDp = with(density) { lensLeftPx.toDp() }
    val lensTopDp = with(density) { lensTopPx.toDp() }

    // Translation so the focus point lands at the lens center after scaling about the origin.
    val txPx = radiusPx - focus.x * zoom
    val tyPx = radiusPx - focus.y * zoom

    Box(
        modifier = Modifier
            .offset(x = lensLeftDp, y = lensTopDp)
            .size(diameterDp)
            .clip(CircleShape)
            .background(Color.Black),
    ) {
        // The image laid out at canvas size, then scaled/translated to magnify the focus area.
        PlatformImage(
            path = imagePath,
            contentDescription = null,
            modifier = Modifier
                .size(
                    width = with(density) { canvasSize.width.toDp() },
                    height = with(density) { canvasSize.height.toDp() },
                )
                .graphicsLayer {
                    transformOrigin = TransformOrigin(0f, 0f)
                    scaleX = zoom
                    scaleY = zoom
                    translationX = txPx
                    translationY = tyPx
                },
        )
        // Crosshair + ring on top of the lens.
        androidx.compose.foundation.Canvas(modifier = Modifier.fillMaxSize()) {
            val cx = size.width / 2f
            val cy = size.height / 2f
            drawLine(Color(0xFF4DB6AC), Offset(cx - 12f, cy), Offset(cx + 12f, cy), strokeWidth = 2f)
            drawLine(Color(0xFF4DB6AC), Offset(cx, cy - 12f), Offset(cx, cy + 12f), strokeWidth = 2f)
            drawCircle(Color.White, radius = size.minDimension / 2f - 2f, style = Stroke(width = 3f))
        }
    }
}
