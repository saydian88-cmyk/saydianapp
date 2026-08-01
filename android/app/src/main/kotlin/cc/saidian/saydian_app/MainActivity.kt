package cc.saidian.saydian_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.inuker.bluetooth.library.Code
import com.inuker.bluetooth.library.search.SearchResult
import com.inuker.bluetooth.library.search.response.SearchResponse
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.data.IAllHealthDataListener
import com.veepoo.protocol.listener.data.IBPDetectDataListener
import com.veepoo.protocol.listener.data.ICustomSettingDataListener
import com.veepoo.protocol.listener.data.IDeviceFuctionDataListener
import com.veepoo.protocol.listener.data.IHeartDataListener
import com.veepoo.protocol.listener.data.IPersonInfoDataListener
import com.veepoo.protocol.listener.data.IPwdDataListener
import com.veepoo.protocol.listener.data.ISocialMsgDataListener
import com.veepoo.protocol.listener.data.ISpo2hDataListener
import com.veepoo.protocol.listener.data.ITemptureDetectDataListener
import com.veepoo.protocol.model.datas.BpData
import com.veepoo.protocol.model.datas.DeviceFunctionPackage1
import com.veepoo.protocol.model.datas.DeviceFunctionPackage2
import com.veepoo.protocol.model.datas.DeviceFunctionPackage3
import com.veepoo.protocol.model.datas.DeviceFunctionPackage4
import com.veepoo.protocol.model.datas.DeviceFunctionPackage5
import com.veepoo.protocol.model.datas.FunctionDeviceSupportData
import com.veepoo.protocol.model.datas.FunctionSocailMsgData
import com.veepoo.protocol.model.datas.HeartData
import com.veepoo.protocol.model.datas.OriginData
import com.veepoo.protocol.model.datas.OriginHalfHourData
import com.veepoo.protocol.model.datas.PersonInfoData
import com.veepoo.protocol.model.datas.PwdData
import com.veepoo.protocol.model.datas.SleepData
import com.veepoo.protocol.model.datas.Spo2hData
import com.veepoo.protocol.model.datas.TemptureDetectData
import com.veepoo.protocol.model.enums.EBPDetectModel
import com.veepoo.protocol.model.enums.EFunctionStatus
import com.veepoo.protocol.model.enums.EOprateStauts
import com.veepoo.protocol.model.enums.EPwdStatus
import com.veepoo.protocol.model.enums.ESex
import com.veepoo.protocol.model.settings.CustomSettingData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val operationExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var adapter: VeepooWearableAdapter
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionCall: Pair<MethodCall, MethodChannel.Result>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        adapter = VeepooWearableAdapter(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHODS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method in BLE_PERMISSION_METHODS && !hasBlePermissions()) {
                pendingPermissionCall = call to result
                ActivityCompat.requestPermissions(this, requiredBlePermissions(), BLE_PERMISSION_REQUEST)
            } else {
                dispatch(call, result)
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != BLE_PERMISSION_REQUEST) return
        val pending = pendingPermissionCall ?: return
        pendingPermissionCall = null
        if (hasBlePermissions()) {
            dispatch(pending.first, pending.second)
        } else {
            pending.second.error("BLE_PERMISSION_DENIED", "需要蓝牙权限才能连接赛电设备", null)
        }
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        operationExecutor.execute { handleMethod(call, result) }
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        val callback = FlutterResultCallback<Any?>(result, mainHandler)
        try {
            when (call.method) {
                "scanDevices" -> adapter.scanDevices(callback)
                "connect" -> adapter.connect(call.argument<String>("deviceId").orEmpty(), callback.unit())
                "disconnect" -> adapter.disconnect(callback.unit())
                "getCapabilities" -> callback.success(adapter.getCapabilities())
                "syncHealthData" -> adapter.syncHealthData(call.argument<String>("cursor"), callback)
                "startMeasurement" ->
                    adapter.startMeasurement(call.argument<String>("metric").orEmpty(), callback.unit())
                "stopMeasurement" ->
                    adapter.stopMeasurement(call.argument<String>("metric").orEmpty(), callback.unit())
                else -> callback.notImplemented()
            }
        } catch (error: Throwable) {
            callback.error("WEARABLE_ERROR", error.message ?: "设备通信失败")
        }
    }

    private fun hasBlePermissions(): Boolean =
        requiredBlePermissions().all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }

    private fun requiredBlePermissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    override fun onDestroy() {
        if (::adapter.isInitialized) adapter.close()
        operationExecutor.shutdownNow()
        super.onDestroy()
    }

    companion object {
        private const val METHODS_CHANNEL = "cc.saidian/wearable_methods"
        private const val EVENTS_CHANNEL = "cc.saidian/wearable_events"
        private const val BLE_PERMISSION_REQUEST = 7001
        private val BLE_PERMISSION_METHODS = setOf("scanDevices", "connect")
    }
}

private interface ResultCallback<in T> {
    fun success(value: T)
    fun error(code: String, message: String)
}

private class FlutterResultCallback<T>(
    private val result: MethodChannel.Result,
    private val handler: Handler,
) : ResultCallback<T> {
    private val completed = AtomicBoolean(false)

    override fun success(value: T) = finish { result.success(value) }

    override fun error(code: String, message: String) = finish { result.error(code, message, null) }

    fun notImplemented() = finish { result.notImplemented() }

    fun unit(): ResultCallback<Unit> =
        object : ResultCallback<Unit> {
            override fun success(value: Unit) = finish { result.success(null) }
            override fun error(code: String, message: String) = this@FlutterResultCallback.error(code, message)
        }

    private fun finish(block: () -> Unit) {
        if (completed.compareAndSet(false, true)) handler.post(block)
    }
}

private class VeepooWearableAdapter(context: android.content.Context) {
    private val manager = VPOperateManager.getInstance()
    private val devices = linkedMapOf<String, SearchResult>()
    private var eventListener: ((Map<String, Any?>) -> Unit)? = null
    private var connectedDeviceId = ""
    private var connectedDeviceName = ""
    private var firmwareVersion = ""
    private var watchDataDays = 3
    private var capabilities = defaultCapabilities()
    private var activeMetric: String? = null

    init {
        manager.init(context.applicationContext)
    }

    fun setEventListener(listener: ((Map<String, Any?>) -> Unit)?) {
        eventListener = listener
    }

    fun scanDevices(callback: ResultCallback<List<Map<String, Any?>>>) {
        devices.clear()
        emit("state", mapOf("value" to "scanning"))
        manager.startScanDevice(
            8,
            object : SearchResponse {
                override fun onSearchStarted() = Unit

                override fun onDeviceFounded(device: SearchResult) {
                    devices[device.address] = device
                }

                override fun onSearchStopped() = finishScan(callback)

                override fun onSearchCanceled() = finishScan(callback)
            },
        )
    }

    private fun finishScan(callback: ResultCallback<List<Map<String, Any?>>>) {
        val result =
            devices.values
                .sortedByDescending { it.rssi }
                .map {
                    mapOf(
                        "id" to it.address,
                        "name" to (it.name ?: "赛电设备"),
                        "model" to (it.name ?: "Veepoo"),
                        "rssi" to it.rssi,
                    )
                }
        emit("state", mapOf("value" to "disconnected"))
        callback.success(result)
    }

    fun connect(deviceId: String, callback: ResultCallback<Unit>) {
        val device = devices[deviceId]
        if (device == null) {
            callback.error("DEVICE_NOT_FOUND", "设备已离开扫描范围，请重新扫描")
            return
        }
        connectedDeviceId = deviceId
        connectedDeviceName = device.name ?: "赛电设备"
        emit("state", mapOf("value" to "connecting"))
        manager.connectDevice(
            deviceId,
            connectedDeviceName,
            { code, _, _ ->
                if (code != Code.REQUEST_SUCCESS) {
                    fail(callback, "CONNECT_FAILED", "设备连接失败")
                }
            },
            { code ->
                if (code == Code.REQUEST_SUCCESS) {
                    authenticate(callback)
                } else {
                    fail(callback, "NOTIFY_FAILED", "设备数据通道订阅失败")
                }
            },
        )
    }

    private fun authenticate(callback: ResultCallback<Unit>) {
        emit("state", mapOf("value" to "authenticating"))
        val passwordStarted = AtomicBoolean(false)
        manager.confirmDevicePwd(
            writeResponse(callback, "密码校验指令发送失败"),
            object : IPwdDataListener {
                override fun onPwdDataChange(data: PwdData) {
                    firmwareVersion = data.deviceVersion.orEmpty()
                    if (data.getmStatus() in setOf(EPwdStatus.CHECK_SUCCESS, EPwdStatus.CHECK_AND_TIME_SUCCESS) &&
                        passwordStarted.compareAndSet(false, true)
                    ) {
                        syncPersonInfo(callback)
                    } else if (data.getmStatus() == EPwdStatus.CHECK_FAIL) {
                        fail(callback, "PASSWORD_FAILED", "设备密码校验失败")
                    }
                }

                override fun onConnectionConfirmTimeout() {
                    fail(callback, "CONFIRM_TIMEOUT", "设备端连接确认超时")
                }
            },
            object : IDeviceFuctionDataListener {
                override fun onFunctionSupportDataChange(data: FunctionDeviceSupportData) {
                    watchDataDays = data.getWathcDay().coerceAtLeast(1)
                    capabilities = capabilitiesFrom(data)
                }

                override fun onDeviceFunctionPackage1Report(data: DeviceFunctionPackage1) = Unit
                override fun onDeviceFunctionPackage2Report(data: DeviceFunctionPackage2) = Unit
                override fun onDeviceFunctionPackage3Report(data: DeviceFunctionPackage3) = Unit
                override fun onDeviceFunctionPackage4Report(data: DeviceFunctionPackage4) = Unit
                override fun onDeviceFunctionPackage5Report(data: DeviceFunctionPackage5) = Unit
            },
            object : ISocialMsgDataListener {
                override fun onSocialMsgSupportDataChange(data: FunctionSocailMsgData) = Unit
                override fun onSocialMsgSupportDataChange2(data: FunctionSocailMsgData) = Unit
            },
            object : ICustomSettingDataListener {
                override fun OnSettingDataChange(data: CustomSettingData) = Unit
            },
            "0000",
            true,
        )
    }

    private fun syncPersonInfo(callback: ResultCallback<Unit>) {
        emit("state", mapOf("value" to "syncing"))
        val person = PersonInfoData(ESex.MAN, 175, 70, 30, 8000)
        manager.syncPersonInfo(
            writeResponse(callback, "个人信息同步指令发送失败"),
            IPersonInfoDataListener { status ->
                if (status == EOprateStauts.OPRATE_SUCCESS) {
                    emit("state", mapOf("value" to "ready"))
                    callback.success(Unit)
                } else {
                    fail(callback, "PERSON_SYNC_FAILED", "个人信息同步失败")
                }
            },
            person,
        )
    }

    fun disconnect(callback: ResultCallback<Unit>) {
        manager.disconnectWatch { code ->
            if (code == Code.REQUEST_SUCCESS) {
                connectedDeviceId = ""
                activeMetric = null
                emit("disconnected", emptyMap())
                callback.success(Unit)
            } else {
                callback.error("DISCONNECT_FAILED", "设备断开失败")
            }
        }
    }

    fun getCapabilities(): Map<String, Any?> = capabilities

    fun syncHealthData(cursor: String?, callback: ResultCallback<List<Map<String, Any?>>>) {
        ensureConnected(callback) ?: return
        emit("syncProgress", mapOf("progress" to 0.0, "cursor" to cursor))
        val records = mutableListOf<Map<String, Any?>>()
        var sleepFinished = false
        var originFinished = false

        fun completeIfReady() {
            if (sleepFinished && originFinished) {
                emit("syncProgress", mapOf("progress" to 1.0, "cursor" to cursor))
                callback.success(records.distinctBy { it["id"] })
            }
        }

        manager.readAllHealthData(
            object : IAllHealthDataListener {
                override fun onProgress(progress: Float) {
                    emit("syncProgress", mapOf("progress" to progress.toDouble(), "cursor" to cursor))
                }

                override fun onSleepDataChange(day: String, sleep: SleepData) {
                    if (sleep.allSleepTime > 0) {
                        records += record("sleep", mapOf("value" to sleep.allSleepTime / 60.0), "h", dateAtNoon(day))
                    }
                }

                override fun onReadSleepComplete() {
                    sleepFinished = true
                    completeIfReady()
                }

                override fun onOringinFiveMinuteDataChange(origin: OriginData) {
                    val at = origin.getmTime()?.toCalendar()?.time ?: parseOriginTime(origin.date, origin.getmTime()?.clock)
                    if (origin.rateValue > 0) records += record("heart_rate", mapOf("value" to origin.rateValue), "bpm", at)
                    if (origin.highValue > 0 && origin.lowValue > 0) {
                        records += record("blood_pressure", mapOf("systolic" to origin.highValue, "diastolic" to origin.lowValue), "mmHg", at)
                    }
                    if (origin.temperature > 0) records += record("body_temperature", mapOf("value" to origin.temperature), "℃", at)
                }

                override fun onOringinHalfHourDataChange(origin: OriginHalfHourData) {
                    origin.halfHourSportDatas.orEmpty().forEach { sport ->
                        val at = sport.time?.toCalendar()?.time ?: parseOriginTime(sport.date, sport.time?.clock)
                        if (sport.stepValue > 0) records += record("steps", mapOf("value" to sport.stepValue), "步", at)
                        if (sport.disValue > 0) records += record("distance", mapOf("value" to sport.disValue), "km", at)
                        if (sport.calValue > 0) records += record("calories", mapOf("value" to sport.calValue), "kcal", at)
                    }
                }

                override fun onReadOriginComplete() {
                    originFinished = true
                    completeIfReady()
                }
            },
            watchDataDays,
        )
    }

    fun startMeasurement(metric: String, callback: ResultCallback<Unit>) {
        ensureConnected(callback) ?: return
        if (!(capabilities["metrics"] as List<*>).contains(metric)) {
            callback.error("UNSUPPORTED_METRIC", "当前设备不支持该指标")
            return
        }
        activeMetric = metric
        emit("state", mapOf("value" to "measuring", "metric" to metric))
        when (metric) {
            "heart_rate" -> manager.startDetectHeart(measurementWrite(callback), IHeartDataListener(::onHeartData))
            "blood_pressure" -> manager.startDetectBP(measurementWrite(callback), IBPDetectDataListener(::onBloodPressureData), EBPDetectModel.DETECT_MODEL_PUBLIC)
            "blood_oxygen" -> manager.startDetectSPO2H(measurementWrite(callback), ISpo2hDataListener(::onOxygenData))
            "body_temperature" -> manager.startDetectTempture(measurementWrite(callback), ITemptureDetectDataListener(::onTemperatureData))
            else -> callback.error("MEASUREMENT_NOT_AVAILABLE", "该指标仅支持同步手表历史数据")
        }
    }

    fun stopMeasurement(metric: String, callback: ResultCallback<Unit>) {
        val response = measurementWrite(callback)
        when (metric) {
            "heart_rate" -> manager.stopDetectHeart(response)
            "blood_pressure" -> manager.stopDetectBP(response, EBPDetectModel.DETECT_MODEL_PUBLIC)
            "blood_oxygen" -> manager.stopDetectSPO2H(response, ISpo2hDataListener { })
            "body_temperature" -> manager.stopDetectTempture(response, ITemptureDetectDataListener { })
            else -> callback.error("MEASUREMENT_NOT_AVAILABLE", "该指标没有可停止的实时测量")
        }
        activeMetric = null
    }

    private fun onHeartData(data: HeartData) {
        if (data.data > 0) emitRecord(record("heart_rate", mapOf("value" to data.data), "bpm", Date()))
    }

    private fun onBloodPressureData(data: BpData) {
        if (data.highPressure > 0 && data.lowPressure > 0) {
            emitRecord(record("blood_pressure", mapOf("systolic" to data.highPressure, "diastolic" to data.lowPressure), "mmHg", Date()))
        }
    }

    private fun onOxygenData(data: Spo2hData) {
        if (data.value > 0) emitRecord(record("blood_oxygen", mapOf("value" to data.value), "%", Date()))
    }

    private fun onTemperatureData(data: TemptureDetectData) {
        if (data.tempture > 0) emitRecord(record("body_temperature", mapOf("value" to data.tempture), "℃", Date()))
    }

    private fun measurementWrite(callback: ResultCallback<Unit>) =
        IBleWriteResponse { code ->
            if (code == Code.REQUEST_SUCCESS) callback.success(Unit)
            else callback.error("MEASUREMENT_COMMAND_FAILED", "测量指令发送失败")
        }

    private fun writeResponse(callback: ResultCallback<Unit>, message: String) =
        IBleWriteResponse { code ->
            if (code != Code.REQUEST_SUCCESS) callback.error("WRITE_FAILED", message)
        }

    private fun ensureConnected(callback: ResultCallback<*>): Unit? {
        if (connectedDeviceId.isBlank()) {
            callback.error("NOT_CONNECTED", "请先连接赛电设备")
            return null
        }
        return Unit
    }

    private fun record(type: String, values: Map<String, Number>, unit: String, measuredAt: Date): Map<String, Any?> {
        val timestamp = iso8601(measuredAt)
        return mapOf(
            "id" to "$connectedDeviceId:$type:$timestamp",
            "type" to type,
            "values" to values,
            "unit" to unit,
            "measuredAt" to timestamp,
            "timezone" to timezoneOffset(),
            "deviceId" to connectedDeviceId,
            "firmwareVersion" to firmwareVersion,
            "quality" to "device_reported",
            "source" to "wearable",
            "rawVersion" to 1,
        )
    }

    private fun emitRecord(record: Map<String, Any?>) {
        emit("healthRecord", record)
    }

    private fun emit(type: String, payload: Map<String, Any?>) {
        eventListener?.invoke(mapOf("type" to type, "payload" to payload))
    }

    private fun fail(callback: ResultCallback<Unit>, code: String, message: String) {
        emit("error", mapOf("code" to code, "message" to message))
        callback.error(code, message)
    }

    fun close() {
        manager.stopScanDevice()
        if (connectedDeviceId.isNotBlank()) manager.disconnectWatch { }
        eventListener = null
    }

    private fun capabilitiesFrom(data: FunctionDeviceSupportData): Map<String, Any?> {
        val metrics = mutableListOf("steps", "distance", "calories", "sleep")
        if (data.heartDetect.haveFunction()) metrics += "heart_rate"
        if (data.bp.haveFunction()) metrics += "blood_pressure"
        if (data.spo2H.haveFunction()) metrics += "blood_oxygen"
        if (data.temperatureFunction.haveFunction() || data.temptureType > 0) metrics += "body_temperature"
        return mapOf(
            "metrics" to metrics,
            "supportsBackgroundSync" to true,
            "supportsWatchFaces" to false,
            "supportsOta" to false,
        )
    }

    companion object {
        private fun defaultCapabilities(): Map<String, Any?> =
            mapOf(
                "metrics" to listOf("steps", "distance", "calories", "sleep"),
                "supportsBackgroundSync" to true,
                "supportsWatchFaces" to false,
                "supportsOta" to false,
            )

        private fun EFunctionStatus?.haveFunction(): Boolean = this?.isHaveFunction == true

        private fun iso8601(date: Date): String =
            SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSXXX", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(date)

        private fun timezoneOffset(): String {
            val offset = TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 60000
            return String.format(Locale.US, "%+03d:%02d", offset / 60, kotlin.math.abs(offset % 60))
        }

        private fun dateAtNoon(value: String): Date =
            parseOriginTime(value, "12:00")

        private fun parseOriginTime(date: String?, time: String?): Date {
            val input = "${date.orEmpty()} ${time ?: "00:00"}".trim()
            val patterns = listOf("yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy/MM/dd HH:mm:ss", "yyyy/MM/dd HH:mm")
            for (pattern in patterns) {
                runCatching { SimpleDateFormat(pattern, Locale.US).parse(input) }.getOrNull()?.let { return it }
            }
            return Date()
        }
    }
}
