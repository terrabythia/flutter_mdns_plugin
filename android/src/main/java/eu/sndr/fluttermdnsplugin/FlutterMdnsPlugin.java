package eu.sndr.fluttermdnsplugin;

import android.annotation.SuppressLint;
import android.content.Context;
import android.net.nsd.NsdManager;
import android.net.nsd.NsdServiceInfo;
import android.util.Log;
import android.os.Handler;
import android.os.Looper;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Collections;

import eu.sndr.fluttermdnsplugin.handlers.DiscoveryRunningHandler;
import eu.sndr.fluttermdnsplugin.handlers.ServiceDiscoveredHandler;
import eu.sndr.fluttermdnsplugin.handlers.ServiceResolvedHandler;
import eu.sndr.fluttermdnsplugin.handlers.ServiceLostHandler;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static android.content.ContentValues.TAG;

/** FlutterMdnsPlugin */
public class FlutterMdnsPlugin implements MethodCallHandler {

  // MethodChannel.Result wrapper that responds on the platform thread.
  private static class MethodResultWrapper implements Result {
    private Result methodResult;
    private Handler handler;

    MethodResultWrapper(Result result) {
      methodResult = result;
      handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public void success(final Object result) {
      handler.post(
              new Runnable() {
                @Override
                public void run() {
                  methodResult.success(result);
                }
              });
    }

    @Override
    public void error(
            final String errorCode, final String errorMessage, final Object errorDetails) {
      handler.post(
              new Runnable() {
                @Override
                public void run() {
                  methodResult.error(errorCode, errorMessage, errorDetails);
                }
              });
    }

    @Override
    public void notImplemented() {
      handler.post(
              new Runnable() {
                @Override
                public void run() {
                  methodResult.notImplemented();
                }
              });
    }
  }

  private final static String NAMESPACE = "eu.sndr.mdns";

  private NsdManager mNsdManager;
  private NsdManager.DiscoveryListener mDiscoveryListener;
  private ArrayList<NsdServiceInfo> mDiscoveredServices;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {

    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_mdns_plugin");
    channel.setMethodCallHandler(new FlutterMdnsPlugin(registrar));

  }

  FlutterMdnsPlugin(Registrar r) {

    mDiscoveredServices = new ArrayList<>();

    EventChannel serviceDiscoveredChannel = new EventChannel(r.messenger(), NAMESPACE + "/discovered");
    mDiscoveredHandler = new ServiceDiscoveredHandler();
    serviceDiscoveredChannel.setStreamHandler(mDiscoveredHandler);

    EventChannel serviceResolved = new EventChannel(r.messenger(), NAMESPACE + "/resolved");
    mResolvedHandler = new ServiceResolvedHandler();
    serviceResolved.setStreamHandler(mResolvedHandler);

    EventChannel serviceLost = new EventChannel(r.messenger(), NAMESPACE + "/lost");
    mLostHandler = new ServiceLostHandler();
    serviceLost.setStreamHandler(mLostHandler);

    EventChannel discoveryRunning = new EventChannel(r.messenger(), NAMESPACE + "/running");
    mDiscoveryRunningHandler = new DiscoveryRunningHandler();
    discoveryRunning.setStreamHandler(mDiscoveryRunningHandler);

    mRegistrar = r;

  }

  private Registrar mRegistrar;
  private DiscoveryRunningHandler mDiscoveryRunningHandler;
  private ServiceDiscoveredHandler mDiscoveredHandler;
  private ServiceResolvedHandler mResolvedHandler;
  private ServiceLostHandler mLostHandler;

  @Override
  public void onMethodCall(MethodCall call, Result rawResult) {

    Result result = new MethodResultWrapper(rawResult);

    switch (call.method) {
      case "startDiscovery":
        startDiscovery((String) call.argument("serviceType"));
        result.success(null);
        break;
      case "stopDiscovery" :
        stopDiscovery();
        result.success(null);
        break;
      case "requestDiscoveredServices":
        for (NsdServiceInfo serviceInfo : mDiscoveredServices) {

        }
        break;
      default:
        result.notImplemented();
        break;
    }

  }

  @SuppressLint("NewApi")
  private void startDiscovery(String serviceName) {

    mNsdManager = (NsdManager)mRegistrar.activity().getSystemService(Context.NSD_SERVICE);

    mDiscoveryListener = new NsdManager.DiscoveryListener(){

      @Override
      public void onStartDiscoveryFailed(String serviceType, int errorCode) {
        Log.e(TAG, String.format(Locale.US,
                "Discovery failed to start on %s with error : %d", serviceType, errorCode));
        mDiscoveryRunningHandler.onDiscoveryStopped();
      }

      @Override
      public void onStopDiscoveryFailed(String serviceType, int errorCode) {
        Log.e(TAG, String.format(Locale.US,
                "Discovery failed to stop on %s with error : %d", serviceType, errorCode));
        mDiscoveryRunningHandler.onDiscoveryStarted();
      }

      @Override
      public void onDiscoveryStarted(String serviceType) {
        Log.d(TAG, "Started discovery for : " + serviceType);
        mDiscoveryRunningHandler.onDiscoveryStarted();
      }

      @Override
      public void onDiscoveryStopped(String serviceType) {
        Log.d(TAG, "Stopped discovery for : " + serviceType);
        mDiscoveryRunningHandler.onDiscoveryStopped();
      }

      @Override
      public void onServiceFound(NsdServiceInfo nsdServiceInfo) {
        Log.d(TAG, "Found Service : " + nsdServiceInfo.toString());
        mDiscoveredServices.add(nsdServiceInfo);
        mDiscoveredHandler.onServiceDiscovered(ServiceToMap(nsdServiceInfo));

        mNsdManager.resolveService(nsdServiceInfo, new NsdManager.ResolveListener() {
          @Override
          public void onResolveFailed(NsdServiceInfo nsdServiceInfo, int errorCode) {
            Log.d(TAG, "Failed to resolve service : " + nsdServiceInfo.toString());

            switch (errorCode) {
              case NsdManager.FAILURE_ALREADY_ACTIVE:
                  Log.e(TAG, "FAILURE_ALREADY_ACTIVE");
                  // Retry x number of times and dont re'add to the list in another function
                  onServiceFoundRetry(nsdServiceInfo, 0);
                  break;
              case NsdManager.FAILURE_INTERNAL_ERROR:
                  Log.e(TAG, "FAILURE_INTERNAL_ERROR");
                  break;
              case NsdManager.FAILURE_MAX_LIMIT:
                  Log.e(TAG, "FAILURE_MAX_LIMIT");
                  break;
            }
          }

          @Override
          public void onServiceResolved(NsdServiceInfo nsdServiceInfo) {
            mResolvedHandler.onServiceResolved(ServiceToMap(nsdServiceInfo));
          }
        });
      }

      //TODO: Check if this implementation is ok
      public void onServiceFoundRetry(NsdServiceInfo nsdServiceInfo, int counter) {
        final int newCounter = counter;
        if (counter > 20) return;
        Log.d(TAG, "Found Service retry : " + nsdServiceInfo.toString());
        mDiscoveredHandler.onServiceDiscovered(ServiceToMap(nsdServiceInfo));

        mNsdManager.resolveService(nsdServiceInfo, new NsdManager.ResolveListener() {
          @Override
          public void onResolveFailed(NsdServiceInfo nsdServiceInfo, int errorCode) {
            Log.d(TAG, "Failed to resolve service : " + nsdServiceInfo.toString());

            switch (errorCode) {
              case NsdManager.FAILURE_ALREADY_ACTIVE:
                Log.e(TAG, "FAILURE_ALREADY_ACTIVE");
                // Just try again...
                try {
                  Thread.sleep(1000);
                } catch(InterruptedException ex) {
                  Thread.currentThread().interrupt();
                }
                onServiceFoundRetry(nsdServiceInfo, newCounter + 1);
                break;
              case NsdManager.FAILURE_INTERNAL_ERROR:
                Log.e(TAG, "FAILURE_INTERNAL_ERROR");
                break;
              case NsdManager.FAILURE_MAX_LIMIT:
                Log.e(TAG, "FAILURE_MAX_LIMIT");
                break;
            }
          }

          @Override
          public void onServiceResolved(NsdServiceInfo nsdServiceInfo) {
            mResolvedHandler.onServiceResolved(ServiceToMap(nsdServiceInfo));
          }
        });
      }

      @Override
      public void onServiceLost(NsdServiceInfo nsdServiceInfo) {
        Log.d(TAG, "Lost Service : " + nsdServiceInfo.toString());
        mLostHandler.onServiceLost(ServiceToMap(nsdServiceInfo));
      }
    };

    mNsdManager.discoverServices(serviceName, NsdManager.PROTOCOL_DNS_SD, mDiscoveryListener);

  }

  private void stopDiscovery() {

    if (mNsdManager != null && mDiscoveryListener != null) {
      mNsdManager.stopServiceDiscovery(mDiscoveryListener);
      mDiscoveredServices = new ArrayList<>();
    }

  }

  /**
   * serviceToMap converts an NsdServiceInfo object into a map of relevant info
   * The map can be interpreted by the StandardMessageCodec of Flutter and makes sending data back and forth simpler.
   * @param info The ServiceInfo to convert
   * @return The map that can be interpreted by Flutter and sent back on an EventChannel
   */
  private static Map<String, Object> ServiceToMap(NsdServiceInfo info) {
    Map<String, Object> map = new HashMap<>();

    map.put("attr", info.getAttributes() != null ? info.getAttributes() : Collections.emptyMap());

    map.put("name", info.getServiceName() != null ? info.getServiceName() : "");

    map.put("type", info.getServiceType() != null ? info.getServiceType() : "");

    map.put("hostName", info.getHost() != null ? info.getHost().getHostName() : "");

    map.put("address", info.getHost() != null ? info.getHost().getHostAddress() : "");

    map.put("port", info.getPort());

    return map;
  }

}
