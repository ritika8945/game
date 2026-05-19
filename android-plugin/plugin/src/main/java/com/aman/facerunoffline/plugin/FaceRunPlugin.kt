package com.aman.facerunoffline.plugin

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.graphics.Rect
import android.net.Uri
import android.util.Log
import androidx.exifinterface.media.ExifInterface
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.io.File
import java.io.FileOutputStream
import org.json.JSONArray
import org.json.JSONObject

class FaceRunPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "FaceRunPlugin"
        private const val PICK_IMAGE_REQUEST = 9001
        private const val PICK_AUDIO_REQUEST = 9002
        private const val FACE_DIR = "faces"
        private const val VOICE_DIR = "voices"
    }

    private val faceDetectorOptions = FaceDetectorOptions.Builder()
        .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_ACCURATE)
        .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
        .setMinFaceSize(0.15f)
        .build()

    private val faceDetector = FaceDetection.getClient(faceDetectorOptions)
    private var pendingImageUri: Uri? = null

    override fun getPluginName() = BuildConfig.GODOT_PLUGIN_NAME

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        return mutableSetOf(
            SignalInfo("image_picked", String::class.java),
            SignalInfo("faces_detected", String::class.java),
            SignalInfo("face_cropped", String::class.java),
            SignalInfo("face_detection_failed", String::class.java),
            SignalInfo("no_faces_found"),
            SignalInfo("plugin_ready"),
            SignalInfo("audio_picked", String::class.java),
            SignalInfo("audio_pick_failed", String::class.java)
        )
    }

    override fun onMainCreate(pActivity: Activity?): android.view.View? {
        Log.i(TAG, "FaceRunPlugin initialized")
        emitSignal("plugin_ready")
        return null
    }

    @UsedByGodot
    fun pickImageFromGallery() {
        runOnHostThread {
            try {
                val intent = Intent(Intent.ACTION_PICK).apply {
                    type = "image/*"
                }
                activity?.startActivityForResult(intent, PICK_IMAGE_REQUEST)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open gallery: ${e.message}")
            }
        }
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == Activity.RESULT_OK) {
            data?.data?.let { uri ->
                pendingImageUri = uri
                val path = copyImageToLocal(uri)
                if (path != null) {
                    emitSignal("image_picked", path)
                }
            }
        } else if (requestCode == PICK_AUDIO_REQUEST && resultCode == Activity.RESULT_OK) {
            data?.data?.let { uri ->
                val path = copyAudioToLocal(uri)
                if (path != null) {
                    emitSignal("audio_picked", path)
                } else {
                    emitSignal("audio_pick_failed", "Could not copy audio file")
                }
            }
        }
    }

    @UsedByGodot
    fun detectFacesFromImage(imagePath: String) {
        try {
            val bitmap = loadBitmapFromPath(imagePath) ?: run {
                emitSignal("face_detection_failed", "Could not load image")
                return
            }
            val inputImage = InputImage.fromBitmap(bitmap, 0)
            faceDetector.process(inputImage)
                .addOnSuccessListener { faces ->
                    if (faces.isEmpty()) {
                        emitSignal("no_faces_found")
                        return@addOnSuccessListener
                    }
                    val jsonArray = JSONArray()
                    for (face in faces) {
                        val box = face.boundingBox
                        val faceJson = JSONObject().apply {
                            put("left", box.left)
                            put("top", box.top)
                            put("width", box.width())
                            put("height", box.height())
                            put("smile_prob", face.smilingProbability ?: -1f)
                            put("left_eye_open", face.leftEyeOpenProbability ?: -1f)
                            put("right_eye_open", face.rightEyeOpenProbability ?: -1f)
                            put("euler_y", face.headEulerAngleY)
                            put("euler_z", face.headEulerAngleZ)
                        }
                        jsonArray.put(faceJson)
                    }
                    emitSignal("faces_detected", jsonArray.toString())
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Face detection failed: ${e.message}")
                    emitSignal("face_detection_failed", e.message ?: "Unknown error")
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error in detectFacesFromImage: ${e.message}")
            emitSignal("face_detection_failed", e.message ?: "Unknown error")
        }
    }

    @UsedByGodot
    fun cropFaceToPng(imagePath: String, left: Int, top: Int, width: Int, height: Int) {
        try {
            val bitmap = loadBitmapFromPath(imagePath) ?: run {
                emitSignal("face_detection_failed", "Could not load image for crop")
                return
            }
            val safeLeft = left.coerceIn(0, bitmap.width - 1)
            val safeTop = top.coerceIn(0, bitmap.height - 1)
            val safeWidth = width.coerceIn(1, bitmap.width - safeLeft)
            val safeHeight = height.coerceIn(1, bitmap.height - safeTop)

            val cropped = Bitmap.createBitmap(bitmap, safeLeft, safeTop, safeWidth, safeHeight)

            val size = minOf(safeWidth, safeHeight)
            val scaled = Bitmap.createScaledBitmap(cropped, size, size, true)

            val outputFile = getFaceFile("cropped_face_${System.currentTimeMillis()}.png")
            FileOutputStream(outputFile).use { out ->
                scaled.compress(Bitmap.CompressFormat.PNG, 100, out)
            }

            cropped.recycle()
            scaled.recycle()

            emitSignal("face_cropped", outputFile.absolutePath)
        } catch (e: Exception) {
            Log.e(TAG, "Error cropping face: ${e.message}")
            emitSignal("face_detection_failed", e.message ?: "Crop failed")
        }
    }

    @UsedByGodot
    fun saveFaceAssignment(entityType: String, pngPath: String) {
        try {
            val prefs = activity?.getSharedPreferences("face_assignments", Activity.MODE_PRIVATE)
            prefs?.edit()?.putString(entityType, pngPath)?.apply()
            Log.i(TAG, "Face assigned: $entityType -> $pngPath")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving face assignment: ${e.message}")
        }
    }

    @UsedByGodot
    fun getSavedFaceAssignments(): String {
        return try {
            val prefs = activity?.getSharedPreferences("face_assignments", Activity.MODE_PRIVATE)
            val json = JSONObject()
            prefs?.all?.forEach { (key, value) ->
                json.put(key, value.toString())
            }
            json.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting face assignments: ${e.message}")
            "{}"
        }
    }

    @UsedByGodot
    fun deleteAllFaceData() {
        try {
            val facesDir = getFacesDirectory()
            facesDir.listFiles()?.forEach { it.delete() }

            val prefs = activity?.getSharedPreferences("face_assignments", Activity.MODE_PRIVATE)
            prefs?.edit()?.clear()?.apply()

            Log.i(TAG, "All face data deleted")
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting face data: ${e.message}")
        }
    }

    @UsedByGodot
    fun pickAudioFromDevice() {
        runOnHostThread {
            try {
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "audio/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                    putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("audio/mpeg", "audio/wav", "audio/x-wav", "audio/ogg"))
                }
                activity?.startActivityForResult(
                    Intent.createChooser(intent, "Select Audio File"),
                    PICK_AUDIO_REQUEST
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to open audio picker: ${e.message}")
                emitSignal("audio_pick_failed", e.message ?: "Unknown error")
            }
        }
    }

    @UsedByGodot
    fun saveVoiceAssignment(category: String, audioPath: String) {
        try {
            val prefs = activity?.getSharedPreferences("voice_assignments", Activity.MODE_PRIVATE)
            prefs?.edit()?.putString(category, audioPath)?.apply()
            Log.i(TAG, "Voice assigned: $category -> $audioPath")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving voice assignment: ${e.message}")
        }
    }

    @UsedByGodot
    fun getSavedVoiceAssignments(): String {
        return try {
            val prefs = activity?.getSharedPreferences("voice_assignments", Activity.MODE_PRIVATE)
            val json = JSONObject()
            prefs?.all?.forEach { (key, value) ->
                json.put(key, value.toString())
            }
            json.toString()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting voice assignments: ${e.message}")
            "{}"
        }
    }

    @UsedByGodot
    fun deleteAllVoiceData() {
        try {
            val voicesDir = getVoicesDirectory()
            voicesDir.listFiles()?.forEach { it.delete() }
            val prefs = activity?.getSharedPreferences("voice_assignments", Activity.MODE_PRIVATE)
            prefs?.edit()?.clear()?.apply()
            Log.i(TAG, "All voice data deleted")
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting voice data: ${e.message}")
        }
    }

    @UsedByGodot
    fun isPluginReady(): Boolean = true

    private fun copyImageToLocal(uri: Uri): String? {
        return try {
            val inputStream = activity?.contentResolver?.openInputStream(uri) ?: return null
            val outputFile = getFaceFile("picked_${System.currentTimeMillis()}.png")
            val bitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()

            if (bitmap == null) return null

            val rotatedBitmap = correctOrientation(uri, bitmap)

            FileOutputStream(outputFile).use { out ->
                rotatedBitmap.compress(Bitmap.CompressFormat.PNG, 90, out)
            }

            if (rotatedBitmap != bitmap) bitmap.recycle()

            outputFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Error copying image: ${e.message}")
            null
        }
    }

    private fun correctOrientation(uri: Uri, bitmap: Bitmap): Bitmap {
        return try {
            val inputStream = activity?.contentResolver?.openInputStream(uri) ?: return bitmap
            val exif = ExifInterface(inputStream)
            inputStream.close()
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL
            )
            val matrix = Matrix()
            when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
                ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.preScale(-1f, 1f)
                ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.preScale(1f, -1f)
            }
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        } catch (e: Exception) {
            bitmap
        }
    }

    private fun loadBitmapFromPath(path: String): Bitmap? {
        return try {
            val options = BitmapFactory.Options().apply {
                inSampleSize = calculateInSampleSize(path, 1024, 1024)
            }
            BitmapFactory.decodeFile(path, options)
        } catch (e: Exception) {
            Log.e(TAG, "Error loading bitmap: ${e.message}")
            null
        }
    }

    private fun calculateInSampleSize(path: String, reqWidth: Int, reqHeight: Int): Int {
        val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, options)
        val (height, width) = options.outHeight to options.outWidth
        var inSampleSize = 1
        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    private fun copyAudioToLocal(uri: Uri): String? {
        return try {
            val inputStream = activity?.contentResolver?.openInputStream(uri) ?: return null
            val mimeType = activity?.contentResolver?.getType(uri)
            val ext = when {
                mimeType?.contains("mpeg") == true -> "mp3"
                mimeType?.contains("wav") == true -> "wav"
                mimeType?.contains("ogg") == true -> "ogg"
                else -> "mp3"
            }
            val outputFile = getVoiceFile("audio_${System.currentTimeMillis()}.$ext")
            val outputStream = FileOutputStream(outputFile)
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            outputFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Error copying audio: ${e.message}")
            null
        }
    }

    private fun getFacesDirectory(): File {
        val dir = File(activity?.filesDir, FACE_DIR)
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun getVoicesDirectory(): File {
        val dir = File(activity?.filesDir, VOICE_DIR)
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    private fun getFaceFile(filename: String): File {
        return File(getFacesDirectory(), filename)
    }

    private fun getVoiceFile(filename: String): File {
        return File(getVoicesDirectory(), filename)
    }
}
