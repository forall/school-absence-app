
package com.example.absencereport

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    AbsenceReportScreen()
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AbsenceReportScreen() {
    val context = LocalContext.current
    val scrollState = rememberScrollState()

    var email by remember { mutableStateOf("") }
    var selectedPerson by remember { mutableStateOf("Dziecko 1") }
    var isTodayOnly by remember { mutableStateOf(true) }
    var dateFrom by remember { mutableStateOf(getTodayDate()) }
    var dateTo by remember { mutableStateOf(getTodayDate()) }
    var showDateFromPicker by remember { mutableStateOf(false) }
    var showDateToPicker by remember { mutableStateOf(false) }

    val personOptions = listOf("Dziecko 1", "Dziecko 2", "Oboje")

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(scrollState)
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        Text(
            text = "Zgłoszenie nieobecności na obiad",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        OutlinedTextField(
            value = email,
            onValueChange = { email = it },
            label = { Text("Adres e-mail") },
            placeholder = { Text("przyklad@email.com") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true
        )

        Text(
            text = "Kto nieobecny:",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            personOptions.forEach { person ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = selectedPerson == person,
                        onClick = { selectedPerson = person }
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(text = person)
                }
            }
        }

        Divider(modifier = Modifier.padding(vertical = 8.dp))

        Text(
            text = "Wybór daty:",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            RadioButton(
                selected = isTodayOnly,
                onClick = { isTodayOnly = true }
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(text = "Tylko dziś")
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            RadioButton(
                selected = !isTodayOnly,
                onClick = { isTodayOnly = false }
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(text = "Zakres dat (od–do)")
        }

        if (!isTodayOnly) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = { showDateFromPicker = true },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Od: ${formatDate(dateFrom)}")
                    }
                    OutlinedButton(
                        onClick = { showDateToPicker = true },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Do: ${formatDate(dateTo)}")
                    }
                }
            }
        } else {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Text(
                    text = "Data: ${formatDate(getTodayDate())}",
                    modifier = Modifier.padding(16.dp),
                    style = MaterialTheme.typography.bodyLarge
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        Button(
            onClick = {
                val validationError = validateInput(email, isTodayOnly, dateFrom, dateTo)
                if (validationError != null) {
                    Toast.makeText(context, validationError, Toast.LENGTH_LONG).show()
                } else {
                    val messageBody = buildEmailBody(
                        selectedPerson,
                        isTodayOnly,
                        dateFrom,
                        dateTo
                    )
                    sendEmail(context, email, messageBody)
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
        ) {
            Text(text = "Wyślij e-mail", style = MaterialTheme.typography.titleMedium)
        }
    }

    if (showDateFromPicker) {
        DatePickerModal(
            initialDate = dateFrom,
            onDateSelected = {
                dateFrom = it
                showDateFromPicker = false
            },
            onDismiss = { showDateFromPicker = false }
        )
    }
    if (showDateToPicker) {
        DatePickerModal(
            initialDate = dateTo,
            onDateSelected = {
                dateTo = it
                showDateToPicker = false
            },
            onDismiss = { showDateToPicker = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DatePickerModal(
    initialDate: Long,
    onDateSelected: (Long) -> Unit,
    onDismiss: () -> Unit
) {
    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = initialDate
    )
    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(onClick = {
                datePickerState.selectedDateMillis?.let { onDateSelected(it) }
            }) { Text("OK") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Anuluj") }
        }
    ) {
        DatePicker(state = datePickerState)
    }
}

fun getTodayDate(): Long {
    return Calendar.getInstance(Locale("pl", "PL")).timeInMillis
}

fun formatDate(timestamp: Long): String {
    val sdf = SimpleDateFormat("dd.MM.yyyy", Locale("pl", "PL"))
    return sdf.format(Date(timestamp))
}

fun validateInput(
    email: String,
    isTodayOnly: Boolean,
    dateFrom: Long,
    dateTo: Long
): String? {
    if (email.isBlank()) return "Proszę podać adres e-mail"
    if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
        return "Nieprawidłowy format adresu e-mail"
    }
    if (!isTodayOnly && dateFrom > dateTo) {
        return "Data 'Od' nie może być późniejsza niż data 'Do'"
    }
    return null
}

fun buildEmailBody(
    person: String,
    isTodayOnly: Boolean,
    dateFrom: Long,
    dateTo: Long
): String {
    return buildString {
        appendLine("Kto nieobecny: $person")
        if (isTodayOnly) {
            appendLine("Data: ${formatDate(getTodayDate())}")
        } else {
            appendLine("Zakres dat: ${formatDate(dateFrom)} – ${formatDate(dateTo)}")
        }
        appendLine()
        appendLine("Pozdrawiam,")
    }
}

fun sendEmail(context: Context, email: String, body: String) {
    try {
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
            putExtra(Intent.EXTRA_EMAIL, arrayOf(email))
            putExtra(Intent.EXTRA_SUBJECT, "Nieobecność – obiady")
            putExtra(Intent.EXTRA_TEXT, body)
        }
        context.startActivity(intent)
    } catch (e: ActivityNotFoundException) {
        Toast.makeText(
            context,
            "Nie znaleziono aplikacji do wysyłania e-maili",
            Toast.LENGTH_LONG
        ).show()
    }
}
