package com.docscanner.shared.presentation.security

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Backspace
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.docscanner.shared.presentation.common.collectAsStateCompat
import org.koin.compose.viewmodel.koinViewModel

/**
 * Startup lock gate. A numeric keypad verifies the PIN; an optional biometric button uses the
 * platform authenticator. On success [onUnlocked] is invoked so the host can show the app.
 */
@Composable
fun PinLockScreen(
    onUnlocked: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PinLockViewModel = koinViewModel(),
) {
    val state by viewModel.state.collectAsStateCompat()

    LaunchedEffect(state.unlocked) {
        if (state.unlocked) onUnlocked()
    }

    Surface(modifier = modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Icon(
                Icons.Filled.Lock,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
            Text(
                "Enter PIN",
                style = MaterialTheme.typography.headlineSmall,
                modifier = Modifier.padding(top = 16.dp),
            )

            // PIN dots
            Row(
                modifier = Modifier.padding(vertical = 24.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                for (i in 0 until 8) {
                    val filled = i < state.entered.length
                    Box(
                        modifier = Modifier
                            .size(14.dp)
                            .clip(CircleShape)
                            .then(
                                if (filled) {
                                    Modifier.background(MaterialTheme.colorScheme.primary)
                                } else {
                                    Modifier.background(MaterialTheme.colorScheme.surfaceVariant)
                                },
                            ),
                    )
                }
            }

            state.error?.let {
                Text(
                    it,
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(bottom = 8.dp),
                )
            }

            // Keypad
            val rows = listOf(
                listOf("1", "2", "3"),
                listOf("4", "5", "6"),
                listOf("7", "8", "9"),
            )
            rows.forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp), modifier = Modifier.padding(vertical = 6.dp)) {
                    row.forEach { digit ->
                        KeypadButton(label = digit, onClick = { viewModel.appendDigit(digit.first()) })
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp), modifier = Modifier.padding(vertical = 6.dp)) {
                if (state.biometricAvailable) {
                    KeypadIconButton(onClick = viewModel::authenticateBiometric) {
                        Icon(Icons.Filled.Fingerprint, contentDescription = "Biometric unlock")
                    }
                } else {
                    Spacer(modifier = Modifier.size(72.dp))
                }
                KeypadButton(label = "0", onClick = { viewModel.appendDigit('0') })
                KeypadIconButton(onClick = viewModel::deleteDigit) {
                    Icon(Icons.Filled.Backspace, contentDescription = "Delete")
                }
            }

            TextButton(onClick = viewModel::submit, modifier = Modifier.padding(top = 16.dp)) {
                Text("Unlock")
            }
        }
    }
}

@Composable
private fun KeypadButton(label: String, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        modifier = Modifier.size(72.dp),
        shape = CircleShape,
    ) {
        Text(label, style = MaterialTheme.typography.headlineSmall)
    }
}

@Composable
private fun KeypadIconButton(onClick: () -> Unit, content: @Composable () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        modifier = Modifier.size(72.dp),
        shape = CircleShape,
    ) {
        content()
    }
}
