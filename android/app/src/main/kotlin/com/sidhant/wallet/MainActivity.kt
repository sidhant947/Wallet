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
import java.io.File
import java.io.OutputStream
import java.io.ByteArrayOutputStream
import android.provider.DocumentsContract
import android.os.ParcelFileDescriptor
import android.graphics.pdf.PdfRenderer
import android.graphics.Bitmap

class MainActivity: FlutterFragmentActivity() 
  {
    private val CHANNEL = "com.sidhant.wallet/save_file"
    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingFilename: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(savedInstanceState)
      window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) 
      {
        GeneratedPluginRegistrant.registerWith(flutterEngine) 
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
          when (call.method) {
            "savePkpass" -> {
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
            }
            "pickDirectory" -> {
              pendingResult = result
              val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
              startActivityForResult(intent, 1002)
            }
            "writeToUri" -> {
              val uriString = call.argument<String>("uri")
              val bytes = call.argument<ByteArray>("bytes")
              val filename = call.argument<String>("filename")
              if (uriString != null && bytes != null && filename != null) {
                try {
                  val treeUri = Uri.parse(uriString)
                  val docUri = buildChildUri(treeUri, filename)
                  val targetUri = if (documentExists(docUri)) {
                    docUri
                  } else {
                    val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
                    val parentDocumentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, treeDocumentId)
                    DocumentsContract.createDocument(
                      contentResolver,
                      parentDocumentUri,
                      "application/octet-stream",
                      filename
                    ) ?: throw Exception("Failed to create document")
                  }
                  contentResolver.openOutputStream(targetUri, "w")?.use { it.write(bytes) }
                  result.success(true)
                } catch (e: Exception) {
                  result.error("WRITE_FAILED", e.message, null)
                }
              } else {
                result.error("INVALID_ARGUMENTS", "Missing uri, bytes, or filename", null)
              }
            }
            "readFromUri" -> {
              val uriString = call.argument<String>("uri")
              val filename = call.argument<String>("filename")
              if (uriString != null && filename != null) {
                try {
                  val treeUri = Uri.parse(uriString)
                  val docUri = buildChildUri(treeUri, filename)
                  val bytes = contentResolver.openInputStream(docUri)?.use { it.readBytes() }
                  if (bytes != null) {
                    result.success(bytes)
                  } else {
                    result.error("READ_FAILED", "Could not read file", null)
                  }
                } catch (e: Exception) {
                  result.error("READ_FAILED", e.message, null)
                }
              } else {
                result.error("INVALID_ARGUMENTS", "Missing uri or filename", null)
              }
            }
            "deleteFromUri" -> {
              val uriString = call.argument<String>("uri")
              val filename = call.argument<String>("filename")
              if (uriString != null && filename != null) {
                try {
                  val treeUri = Uri.parse(uriString)
                  val docUri = buildChildUri(treeUri, filename)
                  contentResolver.delete(docUri, null, null)
                  result.success(true)
                } catch (e: Exception) {
                  result.success(false)
                }
              } else {
                result.error("INVALID_ARGUMENTS", "Missing uri or filename", null)
              }
            }
            "renderPdfPages" -> {
              val path = call.argument<String>("path")
              val maxPages = call.argument<Int>("maxPages") ?: 3
              if (path != null) {
                try {
                  val file = File(path)
                  val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                  val pdfRenderer = PdfRenderer(fileDescriptor)
                  val pageCount = minOf(pdfRenderer.pageCount, maxPages)
                  val pagesBytes = mutableListOf<ByteArray>()

                  for (i in 0 until pageCount) {
                    val page = pdfRenderer.openPage(i)
                    val width = (page.width * 2).coerceIn(600, 2400)
                    val height = (page.height * 2).coerceIn(800, 3200)
                    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    page.close()

                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    bitmap.recycle()
                    pagesBytes.add(stream.toByteArray())
                  }
                  pdfRenderer.close()
                  fileDescriptor.close()
                  result.success(pagesBytes)
                } catch (e: Exception) {
                  result.error("PDF_RENDER_FAILED", e.message, null)
                }
              } else {
                result.error("INVALID_ARGUMENTS", "Path is null", null)
              }
            }
            else -> result.notImplemented()
          }
        }
      }

    private fun buildChildUri(treeUri: Uri, filename: String): Uri {
      val treeDocumentId = DocumentsContract.getTreeDocumentId(treeUri)
      val childDocumentId = "$treeDocumentId/$filename"
      return DocumentsContract.buildDocumentUriUsingTree(treeUri, childDocumentId)
    }

    private fun documentExists(uri: Uri): Boolean {
      return try {
        contentResolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID), null, null, null)?.use { cursor ->
          cursor.count > 0
        } ?: false
      } catch (e: Exception) {
        false
      }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
      super.onActivityResult(requestCode, resultCode, data)
      when (requestCode) {
        1001 -> {
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
            pendingResult?.success(null)
          }
          pendingBytes = null
          pendingResult = null
        }
        1002 -> {
          if (resultCode == Activity.RESULT_OK && data != null) {
            val uri = data.data
            if (uri != null) {
              try {
                contentResolver.takePersistableUriPermission(
                  uri,
                  Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
                pendingResult?.success(uri.toString())
              } catch (e: Exception) {
                pendingResult?.error("PERMISSION_FAILED", e.message, null)
              }
            } else {
              pendingResult?.error("URI_NULL", "Received null URI", null)
            }
          } else {
            pendingResult?.success(null)
          }
          pendingResult = null
        }
      }
    }
  }
