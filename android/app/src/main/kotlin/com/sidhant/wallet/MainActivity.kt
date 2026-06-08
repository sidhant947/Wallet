package com.sidhant.wallet

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.view.WindowManager
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.app.Activity
import android.net.Uri
import java.io.OutputStream

class MainActivity: FlutterFragmentActivity() 
  {
    private val CHANNEL = "com.sidhant.wallet/save_file"
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(savedInstanceState)
      window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) 
      {
        GeneratedPluginRegistrant.registerWith(flutterEngine) 
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
          if (call.method == "savePkpass") {
            val bytes = call.argument<ByteArray>("bytes")
            val name = call.argument<String>("name")
            if (bytes != null && name != null) {
              pendingBytes = bytes
              pendingResult = result
              val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/vnd.apple.pkpass"
                putExtra(Intent.EXTRA_TITLE, name)
              }
              startActivityForResult(intent, 1001)
            } else {
              result.error("INVALID_ARGUMENTS", "Bytes or name is null", null)
            }
          } else {
            result.notImplemented()
          }
        }
      }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
      super.onActivityResult(requestCode, resultCode, data)
      if (requestCode == 1001) {
        if (resultCode == Activity.RESULT_OK && data != null) {
          val uri = data.data
          if (uri != null) {
            try {
              contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(pendingBytes)
              }
              pendingResult?.success(uri.toString())
            } catch (e: Exception) {
              pendingResult?.error("SAVE_FAILED", e.message, null)
            }
          } else {
            pendingResult?.error("URI_NULL", "Received null URI", null)
          }
        } else {
          pendingResult?.success(null) // Cancelled
        }
        pendingBytes = null
        pendingResult = null
      }
    }
  }
