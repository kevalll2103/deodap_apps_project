package com.deodap.staffpacking.staff_packing_app

import android.Manifest
import android.app.Dialog
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.Gravity
import android.view.WindowManager
import android.widget.EditText
import android.widget.TextView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.android.FlutterActivity
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {

    companion object {
        private const val LOCATION_PERMISSION_REQUEST_CODE = 1001

        // Default fallback
        private var TARGET_LAT = 22.327853728361685
        private var TARGET_LNG = 70.85214247288079
        private var ALLOWED_RADIUS_METERS = 1000.0

        private const val ADMIN_PASSWORD = "admin@deodap7070"
        private const val CONFIG_URL = "https://customprint.deodap.com/common-page/location_staff_packaging.php"
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var permissionDialogShown = false
    private var overrideAllowed = false
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        
        fetchConfigFromServer {
            checkLocationPermissionAndValidate()
        }
    }


    private fun fetchConfigFromServer(onDone: () -> Unit) {
        Thread {
            try {
                val url = URL(CONFIG_URL)
                val conn = url.openConnection() as HttpURLConnection
                conn.requestMethod = "GET"

                val result = conn.inputStream.bufferedReader().readText()
                val json = JSONObject(result)

                if (json.getBoolean("success")) {
                    TARGET_LAT = json.getDouble("latitude")
                    TARGET_LNG = json.getDouble("longitude")
                    ALLOWED_RADIUS_METERS = json.getDouble("radius")
                }

            } catch (e: Exception) {
                e.printStackTrace()
            }

            runOnUiThread { onDone() }
        }.start()
    }


    private fun checkLocationPermissionAndValidate() {
        if (overrideAllowed) return

        val fine = Manifest.permission.ACCESS_FINE_LOCATION
        val coarse = Manifest.permission.ACCESS_COARSE_LOCATION

        val hasFine = ContextCompat.checkSelfPermission(this, fine) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(this, coarse) == PackageManager.PERMISSION_GRANTED

        if (!hasFine && !hasCoarse) {
            if (!permissionDialogShown) {
                permissionDialogShown = true
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(fine, coarse),
                    LOCATION_PERMISSION_REQUEST_CODE
                )
            }
        } else {
            validateCurrentLocation()
        }
    }


    private fun validateCurrentLocation() {
        if (overrideAllowed) return

        val tokenSrc = CancellationTokenSource()

        fusedLocationClient.getCurrentLocation(
            Priority.PRIORITY_HIGH_ACCURACY, tokenSrc.token
        ).addOnSuccessListener { location: Location? ->

            if (overrideAllowed) return@addOnSuccessListener

            if (location == null) {
                showAdminDialog("Location Error", "Unable to fetch your location.")
                return@addOnSuccessListener
            }

            val dist = distance(
                location.latitude,
                location.longitude,
                TARGET_LAT,
                TARGET_LNG
            )

            if (dist > ALLOWED_RADIUS_METERS) {
                showAdminDialog(
                    "Access Restricted",
                    "You are outside warehouse zone.\nDistance: ${dist.toInt()} meters."
                )
            }

        }.addOnFailureListener {
            if (!overrideAllowed)
                showAdminDialog("Location Error", "Unable to fetch your location.")
        }
    }

    private fun distance(a: Double, b: Double, c: Double, d: Double): Double {
        val arr = FloatArray(1)
        Location.distanceBetween(a, b, c, d, arr)
        return arr[0].toDouble()
    }

  

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
                validateCurrentLocation()
            } else {
                showAdminDialog(
                    "Permission Required",
                    "Location access is needed.\nAdmin password can override."
                )
            }
        }
    }


    private fun showAdminDialog(title: String, message: String) {
        if (isFinishing || overrideAllowed) return

        val dialog = Dialog(this)
        dialog.requestWindowFeature(android.view.Window.FEATURE_NO_TITLE)
        dialog.setCancelable(false)
        dialog.setContentView(R.layout.dialog_admin_password)

        val titleText = dialog.findViewById<TextView>(R.id.dialogTitle)
        val msgText = dialog.findViewById<TextView>(R.id.dialogMsg)
        val inputField = dialog.findViewById<EditText>(R.id.passwordInput)
        val cancelBtn = dialog.findViewById<TextView>(R.id.cancelBtn)
        val unlockBtn = dialog.findViewById<TextView>(R.id.unlockBtn)

        titleText.text = title
        msgText.text = message

        val window = dialog.window
        window?.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
        window?.setLayout(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT
        )
        window?.setGravity(Gravity.CENTER)
        window?.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)

        cancelBtn.setOnClickListener {
            dialog.dismiss()
            finishAffinity()
        }

        unlockBtn.setOnClickListener {
            val value = inputField.text.toString().trim()

            if (value == ADMIN_PASSWORD) {
                overrideAllowed = true
                dialog.dismiss()
            } else {
                inputField.error = "Incorrect Password"
            }
        }

        dialog.show()
    }
}
