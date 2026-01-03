package com.example.offline_anti_fraud_app;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.tencent.map.geolocation.TencentLocation;
import com.tencent.map.geolocation.TencentLocationListener;
import com.tencent.map.geolocation.TencentLocationManager;
import com.tencent.map.geolocation.TencentLocationRequest;
import com.tencent.map.geolocation.TencentLocationManagerOptions;

/**
 * TencentLocationFlutterChannel handles communication between Flutter and Tencent Location SDK
 */
public class TencentLocationFlutterChannel implements MethodCallHandler {
  private static final String TAG = "TencentLocationChannel";
  private static final String CHANNEL_NAME = "tencent_location_channel";
  
  private final Context applicationContext;
  private final MethodChannel channel;
  private TencentLocationManager locationManager;
  private Result pendingResult;

  public TencentLocationFlutterChannel(FlutterEngine flutterEngine, Context context) {
    this.applicationContext = context;
    this.channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
    
    // 获取TencentLocationManager实例，SDK的key已经在AppApplication中初始化
    locationManager = TencentLocationManager.getInstance(applicationContext);
    
    Log.d(TAG, "TencentLocationFlutterChannel initialized");
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getCurrentLocation")) {
      getCurrentLocation(result);
    } else {
      result.notImplemented();
    }
  }

  private void getCurrentLocation(final Result result) {
        if (pendingResult != null) {
            pendingResult.error("ALREADY_RUNNING", "Location request is already running", null);
            return;
        }

        pendingResult = result;

        // Create location request with optimal parameters
        TencentLocationRequest request = TencentLocationRequest.create()
            .setInterval(0) // Set to 0 for single location request
            .setRequestLevel(TencentLocationRequest.REQUEST_LEVEL_ADMIN_AREA) // Lower level for faster response
            .setAllowCache(true) // Allow cache for faster response
            .setAllowGPS(true); // Allow GPS for better accuracy

        // Request location update
        int errorCode = locationManager.requestLocationUpdates(request, locationListener);
        if (errorCode != 0) { // 0 means success in Tencent Location SDK
            String errorMsg = getErrorMsg(errorCode);
            Log.e(TAG, "Request location update failed: " + errorMsg);
            pendingResult.error("REQUEST_FAILED", errorMsg, errorCode);
            pendingResult = null;
        }
    }

  private final TencentLocationListener locationListener = new TencentLocationListener() {
    @Override
    public void onLocationChanged(@NonNull TencentLocation location, int error, @NonNull String reason) {
      if (pendingResult == null) {
        return;
      }

      if (error == 0 && location != null) { // 0 means success in Tencent Location SDK
        // Location obtained successfully
        Bundle resultData = new Bundle();
        resultData.putDouble("latitude", location.getLatitude());
        resultData.putDouble("longitude", location.getLongitude());
        resultData.putString("address", location.getAddress());
        resultData.putString("province", location.getProvince());
        resultData.putString("city", location.getCity());
        resultData.putString("district", location.getDistrict());
        resultData.putString("street", location.getStreet());
        resultData.putString("streetNo", location.getStreetNo());
        
        Log.d(TAG, "Location obtained: " + location.getAddress());
        pendingResult.success(resultData);
      } else {
        // Location failed
        String errorMsg = getErrorMsg(error);
        Log.e(TAG, "Location update failed: " + errorMsg);
        pendingResult.error("LOCATION_FAILED", errorMsg, error);
      }

      // Remove location updates after getting the first location
      locationManager.removeUpdates(this);
      pendingResult = null;
    }

    @Override
    public void onStatusUpdate(String name, int status, String desc) {
      // Location provider status update
      Log.d(TAG, "Status update: " + name + " - " + status + " - " + desc);
    }
  };

  private String getErrorMsg(int errorCode) {
    switch (errorCode) {
      case 1: // TencentLocation.ERROR_NETWORK
        return "Network error";
      case 2: // TencentLocation.ERROR_GPS
        return "GPS error";
      case 3: // TencentLocation.ERROR_SERVER
        return "Server error";
      case 4: // TencentLocation.ERROR_TIMEOUT
        return "Location timeout";
      case 5: // TencentLocation.ERROR_UNKNOWN
        return "Unknown error";
      case 6: // TencentLocation.ERROR_PERMISSION_DENIED
        return "Location permission denied";
      case 7: // TencentLocation.ERROR_FUSED_LOCATION_SERVICE_DISABLED
        return "Fused location service disabled";
      case 8: // TencentLocation.ERROR_LOCATION_SERVICE_DISABLED
        return "Location service disabled";
      case 9: // TencentLocation.ERROR_GPS_SERVICE_DISABLED
        return "GPS service disabled";
      case 10: // TencentLocation.ERROR_LOCATION_PARAMETER_INVALID
        return "Location parameter invalid";
      case 11: // TencentLocation.ERROR_LOCATION_CACHE_FAILED
        return "Location cache failed";
      case 12: // TencentLocation.ERROR_REQUEST_TOO_FREQUENTLY
        return "Request too frequently";
      default:
        return "Error code: " + errorCode;
    }
  }
}