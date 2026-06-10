package com.shuimingbai.clipboardexpense

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.navigation.compose.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.shuimingbai.clipboardexpense.service.PaymentNotificationHelper
import com.shuimingbai.clipboardexpense.ui.screens.*
import com.shuimingbai.clipboardexpense.ui.theme.ClipboardExpenseTheme
import com.shuimingbai.clipboardexpense.viewmodel.ExpenseViewModel
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private lateinit var vm: ExpenseViewModel

    private val requestNotification = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PaymentNotificationHelper.ensureChannel(this)
        requestPostNotificationsIfNeeded()

        vm = ViewModelProvider(this, ExpenseViewModelFactory(application))[ExpenseViewModel::class.java]
        handleIntentAction(intent)

        setContent {
            ClipboardExpenseTheme {
                MainScaffold(vm)
            }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntentAction(intent)
    }

    override fun onResume() {
        super.onResume()
        checkClipboardOnResume(this, vm)
    }

    private fun handleIntentAction(intent: android.content.Intent?) {
        if (intent?.action == ACTION_CONFIRM) {
            lifecycleScope.launch {
                // PendingConfirmStore 已在通知服务中设置
            }
        }
    }

    private fun requestPostNotificationsIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestNotification.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    companion object {
        const val ACTION_CONFIRM = "com.shuimingbai.clipboardexpense.CONFIRM"
    }
}

@Composable
private fun MainScaffold(vm: ExpenseViewModel) {
    val nav = rememberNavController()
    val backStack by nav.currentBackStackEntryAsState()
    val current = backStack?.destination?.route
    val confirm by vm.confirmSheet.collectAsState()
    val categories by vm.categories.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current

    val tabs = listOf("home" to "账单", "entry" to "记账", "auto" to "自动", "categories" to "分类")
    val icons = mapOf("home" to Icons.Default.Home, "entry" to Icons.Default.Add, "auto" to Icons.Default.Notifications, "categories" to Icons.Default.Category)

    Scaffold(
        bottomBar = {
            if (current == "home") {
                // paste button inside HomeScreen
            }
            NavigationBar {
                tabs.forEach { (route, label) ->
                    NavigationBarItem(
                        selected = current == route,
                        onClick = {
                            nav.navigate(route) {
                                popUpTo(nav.graph.findStartDestination().id) { saveState = true }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(icons[route]!!, contentDescription = label) },
                        label = { Text(label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(nav, startDestination = "home", modifier = Modifier.padding(padding)) {
            composable("home") { HomeScreen(vm) { pasteFromClipboard(context, vm) } }
            composable("entry") { EntryScreen(vm) }
            composable("auto") { AutoSetupScreen() }
            composable("categories") { CategoryScreen(vm) }
        }
    }

    if (confirm != null) {
        ConfirmSheet(
            parsed = confirm!!,
            categories = categories,
            onDismiss = { vm.dismissConfirm() },
            onSave = { a, m, c, n, t, s, r -> vm.saveFromParsed(a, m, c, n, t, s, r) }
        )
    }
}

class ExpenseViewModelFactory(private val app: android.app.Application) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : androidx.lifecycle.ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(ExpenseViewModel::class.java)) {
            return ExpenseViewModel(app) as T
        }
        throw IllegalArgumentException("Unknown ViewModel")
    }
}
