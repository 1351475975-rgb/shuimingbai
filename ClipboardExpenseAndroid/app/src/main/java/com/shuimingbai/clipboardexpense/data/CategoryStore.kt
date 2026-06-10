package com.shuimingbai.clipboardexpense.data

import android.content.Context

object CategoryStore {
    val presets = listOf("餐饮", "交通", "购物", "生活", "娱乐", "其他")

    private const val PREFS = "categories"
    private const val KEY_CUSTOM = "custom"

    fun all(context: Context): List<String> {
        val custom = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY_CUSTOM, emptySet()) ?: emptySet()
        return presets + custom.filter { it !in presets }
    }

    fun add(context: Context, name: String) {
        val trimmed = name.trim()
        if (trimmed.isEmpty() || trimmed in presets) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val set = prefs.getStringSet(KEY_CUSTOM, emptySet())?.toMutableSet() ?: mutableSetOf()
        set.add(trimmed)
        prefs.edit().putStringSet(KEY_CUSTOM, set).apply()
    }

    fun removeCustom(context: Context, name: String) {
        if (name in presets) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val set = prefs.getStringSet(KEY_CUSTOM, emptySet())?.toMutableSet() ?: return
        set.remove(name)
        prefs.edit().putStringSet(KEY_CUSTOM, set).apply()
    }
}
