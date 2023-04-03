package com.cameraroll

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts.StartActivityForResult
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*


class CamerarollModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var launcher: ActivityResultLauncher<Intent>? = null

  fun CamerarollModule(reactContext: ReactApplicationContext?) {
    super(reactContext)
    reactContext.registerForActivityResult
    launcher = registerForActivityResult(StartActivityForResult()) { result ->
      if (result.getResultCode() === Activity.RESULT_OK) {
        val data: Intent = result.getData()
        // handle the result here
      }
    }
  }

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  fun getAssets(params: ReadableMap, promise: Promise) {
    val contentResolver = this.reactApplicationContext.contentResolver

    val isGranted = this.checkReadPermission(promise)
    if (!isGranted) {
      return
    }

    val skip = if (params.hasKey("skip")) params.getInt("skip") else null
    val limit = if (params.hasKey("limit")) params.getInt("limit") else null
    val sortBy = if (params.hasKey("sortBy")) params.getArray("sortBy") else null
    val select = if (params.hasKey("select")) this.readableArray2ArrayString(params.getArray("select")!!) else null
    val mediaType = if (params.hasKey("mediaType")) params.getString("mediaType") else null

    val includes = mapOf(
      "id" to (select == null || select.contains("id")),
      "uri" to (select == null || select.contains("uri")),
      "name" to (select?.contains("uri") ?: false),
      "size" to (select?.contains("size") ?: false),
      "isFavourite" to (select?.contains("isFavourite") ?: false),
      "creationDate" to (select?.contains("creationDate") ?: false),
      "mediaType" to (select?.contains("mediaType") ?: false),
    )

    val projection = this.getProjection(mediaType, includes).toTypedArray()
    val selection = this.getSelection(mediaType)
    val sortOrder = this.getSort(sortBy)

    val cursor: Cursor?
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      val bundle = Bundle()

      if (selection != null) {
        bundle.putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection.toString())
      }

      if (sortOrder != null) {
        bundle.putString(ContentResolver.QUERY_ARG_SQL_SORT_ORDER, sortOrder)
      }

      if (skip != null) {
        bundle.putInt(ContentResolver.QUERY_ARG_OFFSET, skip)
      }

      bundle.putInt(ContentResolver.QUERY_ARG_LIMIT, limit ?: 100000)

      cursor = contentResolver.query(
        MediaStore.Files.getContentUri("external"),
        projection,
        bundle,
        null)
    } else {
      val limitStr = if (skip == null) "limit=${limit ?: 10000}" else "limit=${skip ?: 0},${limit ?: 100000}"

      cursor = contentResolver.query(
        MediaStore.Files.getContentUri("external").buildUpon().encodedQuery(limitStr).build(),
        projection,
        selection,
        null,
        sortOrder
      )
    }

    val items = WritableNativeArray()
    if (cursor != null && cursor.moveToFirst()) {
      do {
        val dict = WritableNativeMap()
        if (includes["id"] == true) {
          val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID))
          dict.putString("id", id.toString())
        }

        if (includes["uri"] == true) {
          val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID))
          val type = when(mediaType) {
            "image" -> MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            "video" -> MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
            else -> cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE))
          }
          val contentUri = when(type) {
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE ->  MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO ->  MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            else -> null
          }

          if (contentUri != null) {
            dict.putString("uri", ContentUris.withAppendedId(contentUri, id).toString())
          }
        }

        if (includes["name"] == true) {
          val name = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME))
          dict.putString("name", name)
        }

        if (includes["size"] == true) {
          val size = cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE))
          dict.putInt("size", size)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
          if (includes["isFavourite"] == true) {
            val isFavourite = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.IS_FAVORITE))
            dict.putString("isFavourite", isFavourite)
          }
        }

        if (includes["creationDate"] == true) {
          val creationDate = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED))
          dict.putString("creationDate", creationDate)
        }

        if (includes["mediaType"] == true) {
          dict.putInt("mediaType", when(mediaType) {
            "image" -> MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
            "video" -> MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
            else -> cursor.getInt(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE))
          })
        }

        items.pushMap(dict)
      } while (cursor.moveToNext())

      cursor.close()
    }

    val result = WritableNativeMap()
    result.putArray("items", items)

    promise.resolve(result)
  }

  @ReactMethod
  fun editIsFavorite(id: String, isFavorite: Boolean, promise: Promise) {
    currentActivity.registerForActivityResult
    val currentActivity = currentActivity
    /* getCurrentActivity().reg
    registerForActivityResul
    currentActivity.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { result ->
      if (result.resultCode == Activity.RESULT_OK) {
        Log.d("deleteResultLauncher", "Android 11 or higher : deleted")
      }
    }
    currentActivity.
    startActivityForResult
    val contentResolver = this.reactApplicationContext.contentResolver
    val uri = Uri.parse(id)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      val pendingIntent = MediaStore.createDeleteRequest(contentResolver, mutableListOf(uri)
      this.deleteResultLauncher.launch(IntentSenderRequest.Builder(pendingIntent.intentSender).build())
    }
  }
*/
    /*
  private fun deleteImages(uris: List<Uri>) {
    val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris.filter {
      checkUriPermission(it, Binder.getCallingPid(), Binder.getCallingUid(), Intent.FLAG_GRANT_WRITE_URI_PERMISSION) != PackageManager.PERMISSION_GRANTED
    })
    startIntentSenderForResult(pendingIntent.intentSender, REQ_CODE, null, 0, 0, 0)
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)
    if (requestCode == REQ_CODE && resultCode == Activity.RESULT_OK) {
      // Image deleted successfully
    }
  }*/
  }

  private fun getSort(sortBy: ReadableArray?): String? {
    if (sortBy == null) {
      return null
    }

    val sorts = mutableListOf<String>()

    for (i in 0 until (sortBy.size() ?: 0)) {
      val item = sortBy.getMap(i)
      val key = item.getString("key")
      val order = if (item.getBoolean("asc")) "ASC" else "DESC"

      sorts.add("$key $order")
    }

    if (sorts.isEmpty()) {
      return null
    }

    return sorts.joinToString(", ")
  }

  private fun getSelection(mediaType: String?): String? {
    val selections = mutableListOf<String>()
    selections.add(when (mediaType) {
      "image" -> "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}"
      "video" -> "${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO}"
      else    -> "${MediaStore.Files.FileColumns.MEDIA_TYPE} IN (${MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE}, ${MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO})"
    })

    if (selections.isEmpty()) {
      return null
    }

    return selections.joinToString(" AND ")
  }

  private fun getProjection(mediaType: String?, includes: Map<String, Boolean>): List<String> {
    return arrayOf(
      if ("id" in includes || "uri" in includes) MediaStore.Files.FileColumns._ID else null,
      if ("name" in includes) MediaStore.Files.FileColumns.DISPLAY_NAME else null,
      if ("size" in includes) MediaStore.Files.FileColumns.SIZE else null,
      if ("isFavourite" in includes && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) MediaStore.Files.FileColumns.IS_FAVORITE else null,
      if ("creationDate" in includes) MediaStore.Files.FileColumns.DATE_ADDED else null,
      if ("mediaType" in includes || "uri" in includes || (mediaType != "image" && mediaType != "video")) MediaStore.Files.FileColumns.MEDIA_TYPE else null,
    ).filterNotNull()
  }

  private fun checkReadPermission(promise: Promise): Boolean {
    val permission = ContextCompat.checkSelfPermission(this.reactApplicationContext, Manifest.permission.READ_EXTERNAL_STORAGE)
    val isGranted = permission == PackageManager.PERMISSION_GRANTED

    if (!isGranted) {
      promise.reject("Permission denied", "READ_EXTERNAL_STORAGE permission required")
    }

    return isGranted
  }

  private fun readableArray2ArrayString(readableArray: ReadableArray): Array<String> {
    val array = arrayOfNulls<String>(readableArray.size() ?: 0)
    for (i in 0 until (readableArray.size() ?: 0)) {
      array[i] = readableArray.getString(i)
    }
    return array.requireNoNulls()
  }


  companion object {
    const val NAME = "Cameraroll"
  }
}
