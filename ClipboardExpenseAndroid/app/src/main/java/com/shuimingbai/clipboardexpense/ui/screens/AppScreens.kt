package com.shuimingbai.clipboardexpense.ui.screens

import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shuimingbai.clipboardexpense.data.ExpenseRecord
import com.shuimingbai.clipboardexpense.parser.ParseConfidence
import com.shuimingbai.clipboardexpense.parser.ParsedPayment
import com.shuimingbai.clipboardexpense.parser.PaymentSource
import com.shuimingbai.clipboardexpense.ui.StatsCalculator
import com.shuimingbai.clipboardexpense.viewmodel.ExpenseViewModel
import java.math.BigDecimal
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val moneyFmt = NumberFormat.getCurrencyInstance(Locale.CHINA)
private val timeFmt = SimpleDateFormat("HH:mm", Locale.CHINA)
private val dayFmt = SimpleDateFormat("yyyy年M月d日", Locale.CHINA)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(vm: ExpenseViewModel, onPaste: () -> Unit) {
    val records by vm.records.collectAsState()
    val hint by vm.clipboardHint.collectAsState()
    val today = StatsCalculator.today(records)
    val week = StatsCalculator.thisWeek(records)
    val month = StatsCalculator.thisMonth(records)

    Scaffold(
        bottomBar = {
            Surface(shadowElevation = 8.dp) {
                Button(
                    onClick = onPaste,
                    modifier = Modifier.fillMaxWidth().padding(16.dp)
                ) { Text("粘贴记账") }
            }
        }
    ) { padding ->
        LazyColumn(modifier = Modifier.padding(padding).fillMaxSize()) {
            item {
                Column(Modifier.padding(16.dp)) {
                    Text("剪贴板记账", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    Text("复制支付文本 → 粘贴 → 确认", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            if (hint) {
                item {
                    Card(
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary),
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text("检测到剪贴板可能有新内容", color = MaterialTheme.colorScheme.onPrimary, modifier = Modifier.weight(1f))
                            TextButton(onClick = { vm.dismissClipboardHint() }) { Text("忽略", color = MaterialTheme.colorScheme.onPrimary) }
                            Button(onClick = onPaste) { Text("粘贴") }
                        }
                    }
                }
            }
            item {
                Row(Modifier.padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    StatCard("今日", today, Modifier.weight(1f))
                    StatCard("本周", week, Modifier.weight(1f))
                    StatCard("本月", month, Modifier.weight(1f))
                }
            }
            if (records.isEmpty()) {
                item {
                    Box(Modifier.fillMaxWidth().padding(48.dp), contentAlignment = Alignment.Center) {
                        Text("暂无账单", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            } else {
                StatsCalculator.groupByDay(records).forEach { (day, items) ->
                    item { Text(dayFmt.format(SimpleDateFormat("yyyy-MM-dd", Locale.CHINA).parse(day)!!), Modifier.padding(16.dp, 8.dp, 16.dp, 4.dp), style = MaterialTheme.typography.labelMedium) }
                    items(items, key = { it.id }) { record ->
                        RecordRow(record, onDelete = { vm.delete(record) })
                    }
                }
            }
            item { Spacer(Modifier.height(80.dp)) }
        }
    }
}

@Composable
private fun StatCard(title: String, stats: com.shuimingbai.clipboardexpense.ui.PeriodStats, modifier: Modifier) {
    Card(modifier) {
        Column(Modifier.padding(12.dp)) {
            Text(title, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Text(moneyFmt.format(stats.total), fontWeight = FontWeight.Bold)
            Text("${stats.count} 笔", style = MaterialTheme.typography.labelSmall)
        }
    }
}

@Composable
private fun RecordRow(record: ExpenseRecord, onDelete: () -> Unit) {
    Card(Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text(record.merchant ?: record.category, fontWeight = FontWeight.SemiBold)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    AssistChip(onClick = {}, label = { Text(record.category) })
                    Text(timeFmt.format(record.time), style = MaterialTheme.typography.labelSmall)
                }
            }
            Text(moneyFmt.format(record.amount), fontWeight = FontWeight.Bold)
            IconButton(onClick = onDelete) { Icon(Icons.Default.Delete, contentDescription = "删除") }
        }
    }
}

@Composable
fun EntryScreen(vm: ExpenseViewModel) {
    var text by remember { mutableStateOf("") }
    Column(Modifier.padding(16.dp).verticalScroll(rememberScrollState())) {
        Text("手动记账", style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(value = text, onValueChange = { text = it }, modifier = Modifier.fillMaxWidth().height(160.dp), placeholder = { Text("粘贴支付文本…") })
        Spacer(Modifier.height(12.dp))
        Button(onClick = { vm.processText(text) }, modifier = Modifier.fillMaxWidth(), enabled = text.isNotBlank()) { Text("解析并记账") }
        OutlinedButton(onClick = { vm.showConfirm(ParsedPayment.manualFallback("")) }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) { Text("手动填写") }
    }
}

@Composable
fun AutoSetupScreen() {
    val context = LocalContext.current
    val steps = listOf(
        "1. 开启通知权限" to "允许本 App 发送「检测到支付」提醒",
        "2. 通知使用权（核心）" to "设置 → 特殊权限 → 通知使用权 → 开启「剪贴板记账」",
        "3. 微信/支付宝通知" to "确保允许通知且显示预览内容",
        "4. 省电白名单" to "将本 App 加入自启动/后台白名单（小米/华为等）",
        "5. 测试" to "付一笔小额 → 应收到「检测到支付」通知 → 点击打开确认页"
    )
    Column(Modifier.padding(16.dp).verticalScroll(rememberScrollState())) {
        Text("通知自动记账", style = MaterialTheme.typography.titleLarge)
        Text("付完款后监听微信/支付宝通知，半自动弹出确认（Android Pro）", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        steps.forEach { (t, d) ->
            Card(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
                Column(Modifier.padding(12.dp)) {
                    Text(t, fontWeight = FontWeight.SemiBold)
                    Text(d, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
        Spacer(Modifier.height(16.dp))
        Button(onClick = {
            context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }, modifier = Modifier.fillMaxWidth()) { Text("打开通知使用权设置") }
    }
}

@Composable
fun CategoryScreen(vm: ExpenseViewModel) {
    val categories by vm.categories.collectAsState()
    var newName by remember { mutableStateOf("") }
    Column(Modifier.padding(16.dp)) {
        Text("分类管理", style = MaterialTheme.typography.titleLarge)
        Spacer(Modifier.height(8.dp))
        categories.forEach { name ->
            Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(name, modifier = Modifier.weight(1f))
                if (name !in com.shuimingbai.clipboardexpense.data.CategoryStore.presets) {
                    TextButton(onClick = { vm.removeCategory(name) }) { Text("删除", color = MaterialTheme.colorScheme.error) }
                } else {
                    Text("预设", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = newName, onValueChange = { newName = it }, modifier = Modifier.weight(1f), placeholder = { Text("新分类") })
            Button(onClick = { vm.addCategory(newName); newName = "" }) { Text("添加") }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConfirmSheet(parsed: ParsedPayment, categories: List<String>, onDismiss: () -> Unit, onSave: (String, String, String, String, Date, PaymentSource, String) -> Unit) {
    var amount by remember(parsed) { mutableStateOf(if (parsed.amount > BigDecimal.ZERO) parsed.amount.toPlainString() else "") }
    var merchant by remember(parsed) { mutableStateOf(parsed.merchant ?: "") }
    var category by remember(parsed) { mutableStateOf(parsed.category) }
    var note by remember { mutableStateOf("") }
    var time by remember(parsed) { mutableLongStateOf(parsed.time.time) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(Modifier.padding(16.dp).navigationBarsPadding()) {
            Text("确认记账", style = MaterialTheme.typography.titleLarge)
            if (parsed.confidence == ParseConfidence.LOW) {
                Text("解析置信度较低，请核对", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }
            Spacer(Modifier.height(8.dp))
            OutlinedTextField(value = amount, onValueChange = { amount = it }, label = { Text("金额") }, modifier = Modifier.fillMaxWidth())
            OutlinedTextField(value = merchant, onValueChange = { merchant = it }, label = { Text("商家") }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp))
            var expanded by remember { mutableStateOf(false) }
            ExposedDropdownMenuBox(expanded = expanded, onExpandedChange = { expanded = it }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp)) {
                OutlinedTextField(value = category, onValueChange = {}, readOnly = true, label = { Text("分类") }, modifier = Modifier.menuAnchor().fillMaxWidth())
                ExposedDropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    categories.forEach { c ->
                        DropdownMenuItem(text = { Text(c) }, onClick = { category = c; expanded = false })
                    }
                }
            }
            OutlinedTextField(value = note, onValueChange = { note = it }, label = { Text("备注") }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp))
            if (parsed.rawText.isNotBlank()) {
                Text("原始：${parsed.rawText.take(120)}", style = MaterialTheme.typography.labelSmall, modifier = Modifier.padding(top = 8.dp))
            }
            Row(Modifier.fillMaxWidth().padding(top = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedButton(onClick = onDismiss, modifier = Modifier.weight(1f)) { Text("取消") }
                Button(
                    onClick = { onSave(amount, merchant, category, note, Date(time), parsed.source, parsed.rawText) },
                    modifier = Modifier.weight(1f),
                    enabled = amount.toBigDecimalOrNull()?.let { it > BigDecimal.ZERO } == true
                ) { Text("保存") }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

fun pasteFromClipboard(context: Context, vm: ExpenseViewModel) {
    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val text = cm.primaryClip?.getItemAt(0)?.text?.toString() ?: ""
    vm.processText(text)
}

fun checkClipboardOnResume(context: Context, vm: ExpenseViewModel) {
    val cm = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    if (cm.hasPrimaryClip() && cm.primaryClip?.getItemAt(0)?.text?.isNotBlank() == true) {
        vm.showClipboardHint()
    }
}
