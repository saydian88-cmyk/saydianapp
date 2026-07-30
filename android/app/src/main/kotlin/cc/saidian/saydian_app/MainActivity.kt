package cc.saidian.saydian_app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val operationExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val adapter: WearableAdapter = UnconfiguredVeepooAdapter()
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHODS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            operationExecutor.execute {
                handleMethod(call, result)
            }
        }
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENTS_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    adapter.setEventListener { payload ->
                        mainHandler.post { eventSink?.success(payload) }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    adapter.setEventListener(null)
                }
            },
        )
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        try {
            val value =
                when (call.method) {
                    "scanDevices" -> adapter.scanDevices()
                    "connect" -> {
                        adapter.connect(call.argument<String>("deviceId").orEmpty())
                        null
                    }
                    "disconnect" -> {
                        adapter.disconnect()
                        null
                    }
                    "getCapabilities" -> adapter.getCapabilities()
                    "syncHealthData" ->
                        adapter.syncHealthData(call.argument<String>("cursor"))
                    "startMeasurement" -> {
                        adapter.startMeasurement(call.argument<String>("metric").orEmpty())
                        null
                    }
                    "stopMeasurement" -> {
                        adapter.stopMeasurement(call.argument<String>("metric").orEmpty())
                        null
                    }
                    else -> {
                        mainHandler.post { result.notImplemented() }
                        return
                    }
                }
            mainHandler.post { result.success(value) }
        } catch (error: SdkNotConfiguredException) {
            mainHandler.post {
                result.error("SDK_NOT_CONFIGURED", error.message, null)
            }
        } catch (error: Throwable) {
            mainHandler.post {
                result.error("WEARABLE_ERROR", "设备通信失败", null)
            }
        }
    }

    override fun onDestroy() {
        adapter.close()
        operationExecutor.shutdownNow()
        super.onDestroy()
    }

    companion object {
        private const val METHODS_CHANNEL = "cc.saidian/wearable_methods"
        private const val EVENTS_CHANNEL = "cc.saidian/wearable_events"
    }
}

private interface WearableAdapter {
    fun setEventListener(listener: ((Map<String, Any?>) -> Unit)?)
    fun scanDevices(): List<Map<String, Any?>>
    fun connect(deviceId: String)
    fun disconnect()
    fun getCapabilities(): Map<String, Any?>
    fun syncHealthData(cursor: String?): List<Map<String, Any?>>
    fun startMeasurement(metric: String)
    fun stopMeasurement(metric: String)
    fun close()
}

private class SdkNotConfiguredException :
    IllegalStateException(
        if (BuildConfig.VEEPOO_SDK_PRESENT) {
            "Veepoo AAR 已检测到，仍需目标型号真机验证后启用适配器"
        } else {
            "Veepoo AAR 未配置；请按 android/app/libs/README.md 放入官方 2.3.74.15 依赖"
        },
    )

/**
 * Safe build-time adapter. Replace this class with the official
 * VPOperateManager-backed implementation only after the matching production
 * watch, firmware matrix and partner SDK authorization are available.
 */
private class UnconfiguredVeepooAdapter : WearableAdapter {
    override fun setEventListener(listener: ((Map<String, Any?>) -> Unit)?) = Unit
    override fun scanDevices(): List<Map<String, Any?>> = missing()
    override fun connect(deviceId: String): Unit = missing()
    override fun disconnect(): Unit = missing()
    override fun getCapabilities(): Map<String, Any?> = missing()
    override fun syncHealthData(cursor: String?): List<Map<String, Any?>> = missing()
    override fun startMeasurement(metric: String): Unit = missing()
    override fun stopMeasurement(metric: String): Unit = missing()
    override fun close() = Unit

    private fun <T> missing(): T = throw SdkNotConfiguredException()
}
