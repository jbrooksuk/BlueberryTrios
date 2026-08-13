package com.altthree.berroku

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.altthree.berroku.ui.BerrokuApp
import com.altthree.berroku.ui.theme.BerrokuTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BerrokuTheme {
                BerrokuApp()
            }
        }
    }
}
