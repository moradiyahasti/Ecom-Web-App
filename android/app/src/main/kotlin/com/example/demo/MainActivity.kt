package com.example.demo // ⚠️ CHANGE THIS to match your app's package name

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "upi_payment_channel"
    private val UPI_PAYMENT_REQUEST_CODE = 1001
    private var methodChannelResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startUpiPayment") {
                methodChannelResult = result
                
                val pa = call.argument<String>("pa") ?: ""
                val pn = call.argument<String>("pn") ?: ""
                val am = call.argument<String>("am") ?: ""
                val cu = call.argument<String>("cu") ?: "INR"
                val tn = call.argument<String>("tn") ?: ""
                val tr = call.argument<String>("tr") ?: ""
                val app = call.argument<String>("app") ?: ""
                
                try {
                    val uri = Uri.Builder()
                        .scheme("upi")
                        .authority("pay")
                        .appendQueryParameter("pa", pa)
                        .appendQueryParameter("pn", pn)
                        .appendQueryParameter("am", am)
                        .appendQueryParameter("cu", cu)
                        .appendQueryParameter("tn", tn)
                        .appendQueryParameter("tr", tr)
                        .build()
                    
                    val intent = Intent(Intent.ACTION_VIEW)
                    intent.data = uri
                    
                    // Set specific app if provided
                    if (app.isNotEmpty()) {
                        intent.setPackage(app)
                    }
                    
                    startActivityForResult(intent, UPI_PAYMENT_REQUEST_CODE)
                    result.success("UPI Intent Started")
                    
                } catch (e: Exception) {
                    result.error("UPI_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == UPI_PAYMENT_REQUEST_CODE) {
            val response = data?.getStringExtra("response") ?: ""
            val status = data?.getStringExtra("Status") ?: ""
            val txnId = data?.getStringExtra("txnId") ?: ""
            val txnRef = data?.getStringExtra("txnRef") ?: ""
            val approvalRefNo = data?.getStringExtra("ApprovalRefNo") ?: ""
            
            // Parse response string if available
            val responseMap = mutableMapOf<String, String>()
            
            if (response.isNotEmpty()) {
                val pairs = response.split("&")
                for (pair in pairs) {
                    val keyValue = pair.split("=")
                    if (keyValue.size == 2) {
                        responseMap[keyValue[0]] = keyValue[1]
                    }
                }
            }
            
            // Get status (priority: from response map > direct extra > resultCode)
            val finalStatus = when {
                responseMap["Status"]?.lowercase() in listOf("success", "submitted") -> "success"
                status.lowercase() in listOf("success", "submitted") -> "success"
                resultCode == RESULT_OK -> "success"
                responseMap["Status"]?.lowercase() in listOf("failure", "failed") -> "failure"
                status.lowercase() in listOf("failure", "failed") -> "failure"
                resultCode == RESULT_CANCELED -> "cancelled"
                else -> "unknown"
            }
            
            val finalTxnId = when {
                responseMap["txnId"]?.isNotEmpty() == true -> responseMap["txnId"]
                txnId.isNotEmpty() -> txnId
                approvalRefNo.isNotEmpty() -> approvalRefNo
                responseMap["ApprovalRefNo"]?.isNotEmpty() == true -> responseMap["ApprovalRefNo"]
                else -> ""
            }
            
            // Send response back to Flutter
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod(
                    "onUpiResponse",
                    mapOf(
                        "status" to finalStatus,
                        "txnId" to finalTxnId,
                        "txnRef" to (responseMap["txnRef"] ?: txnRef),
                        "response" to response,
                        "rawStatus" to status,
                        "resultCode" to resultCode
                    )
                )
            }
        }
    }
}