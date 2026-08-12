package cc.saidian.saydian_app

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.inuker.bluetooth.library.Code
import com.inuker.bluetooth.library.Constants
import com.inuker.bluetooth.library.connect.response.BleNotifyResponse
import com.inuker.bluetooth.library.connect.response.BleWriteResponse
import com.inuker.bluetooth.library.jieli.RcspAuthManager
import com.inuker.bluetooth.library.jieli.dial.JLWatchFaceManager
import com.inuker.bluetooth.library.jieli.dial.WatchManager
import com.inuker.bluetooth.library.jieli.response.RcspAuthResponse
import com.inuker.bluetooth.library.search.SearchResult
import com.inuker.bluetooth.library.search.response.SearchResponse
import com.jieli.jl_fatfs.model.FatFile
import com.jieli.jl_rcsp.interfaces.watch.OnWatchOpCallback
import com.jieli.jl_rcsp.model.base.BaseError
import com.veepoo.protocol.VPOperateManager
import com.veepoo.protocol.listener.IHealthRemindListener
import com.veepoo.protocol.listener.base.IABleConnectStatusListener
import com.veepoo.protocol.listener.base.IBleWriteResponse
import com.veepoo.protocol.listener.base.IConnectResponse
import com.veepoo.protocol.listener.base.INotifyResponse
import com.veepoo.protocol.listener.data.IAutoMeasureSettingDataListener
import com.veepoo.protocol.listener.data.IAlarm2DataListListener
import com.veepoo.protocol.listener.data.IBPDetectDataListener
import com.veepoo.protocol.listener.data.ICameraDataListener
import com.veepoo.protocol.listener.data.IContactOptListener
import com.veepoo.protocol.listener.data.ICustomSettingDataListener
import com.veepoo.protocol.listener.data.IDeviceBTInfoListener
import com.veepoo.protocol.listener.data.IDeviceFuctionDataListener
import com.veepoo.protocol.listener.data.IFindDevicelistener
import com.veepoo.protocol.listener.data.IFunSwitchListener
import com.veepoo.protocol.listener.data.IHeartDataListener
import com.veepoo.protocol.listener.data.IHealthAlarmIntervalListener
import com.veepoo.protocol.listener.data.ILongSeatDataListener
import com.veepoo.protocol.listener.data.IMtuChangeListener
import com.veepoo.protocol.listener.data.INightTurnWristeDataListener
import com.veepoo.protocol.listener.data.IOriginData3Listener
import com.veepoo.protocol.listener.data.IOriginDataListener
import com.veepoo.protocol.listener.data.IPersonInfoDataListener
import com.veepoo.protocol.listener.data.IPwdDataListener
import com.veepoo.protocol.listener.data.ISleepDataListener
import com.veepoo.protocol.listener.data.ISocialMsgDataListener
import com.veepoo.protocol.listener.data.IScreenLightListener
import com.veepoo.protocol.listener.data.IScreenLightTimeListener
import com.veepoo.protocol.listener.data.ISpo2hDataListener
import com.veepoo.protocol.listener.data.ISportModelOriginListener
import com.veepoo.protocol.listener.data.ISportModelStateListener
import com.veepoo.protocol.listener.data.ITemptureDetectDataListener
import com.veepoo.protocol.listener.data.ITextAlarmDataListener
import com.veepoo.protocol.listener.data.IWeatherStatusDataListener
import com.veepoo.protocol.listener.data.IWorldClockOptListener
import com.veepoo.protocol.model.datas.BTInfo
import com.veepoo.protocol.model.datas.BpData
import com.veepoo.protocol.model.datas.AutoMeasureData
import com.veepoo.protocol.model.datas.Contact
import com.veepoo.protocol.model.datas.DeviceFunctionPackage1
import com.veepoo.protocol.model.datas.DeviceFunctionPackage2
import com.veepoo.protocol.model.datas.DeviceFunctionPackage3
import com.veepoo.protocol.model.datas.DeviceFunctionPackage4
import com.veepoo.protocol.model.datas.DeviceFunctionPackage5
import com.veepoo.protocol.model.datas.FunctionDeviceSupportData
import com.veepoo.protocol.model.datas.FunctionSocailMsgData
import com.veepoo.protocol.model.datas.FunSwitchFlags
import com.veepoo.protocol.model.datas.HRVOriginData
import com.veepoo.protocol.model.datas.HeartData
import com.veepoo.protocol.model.datas.HealthAlarmInterval
import com.veepoo.protocol.model.datas.HealthRemind
import com.veepoo.protocol.model.datas.OriginData
import com.veepoo.protocol.model.datas.OriginData3
import com.veepoo.protocol.model.datas.OriginHalfHourData
import com.veepoo.protocol.model.datas.PersonInfoData
import com.veepoo.protocol.model.datas.PwdData
import com.veepoo.protocol.model.datas.SleepData
import com.veepoo.protocol.model.datas.Spo2hOriginData
import com.veepoo.protocol.model.datas.Spo2hData
import com.veepoo.protocol.model.datas.SportModelGPSWatchOriginHeadData
import com.veepoo.protocol.model.datas.SportModelOriginHeadData
import com.veepoo.protocol.model.datas.SportModelOriginItemData
import com.veepoo.protocol.model.datas.SportModelStateData
import com.veepoo.protocol.model.datas.TemptureDetectData
import com.veepoo.protocol.model.datas.TextAlarmData
import com.veepoo.protocol.model.datas.TimeData
import com.veepoo.protocol.model.datas.WorldClock
import com.veepoo.protocol.model.datas.weather.WeatherData
import com.veepoo.protocol.model.datas.weather.WeatherEvery3Hour
import com.veepoo.protocol.model.datas.weather.WeatherEveryDay
import com.veepoo.protocol.model.enums.EBPDetectModel
import com.veepoo.protocol.model.enums.EAutoMeasureType
import com.veepoo.protocol.model.enums.ECameraStatus
import com.veepoo.protocol.model.enums.EContactOpt
import com.veepoo.protocol.model.enums.EFunctionStatus
import com.veepoo.protocol.model.enums.EHealthAlarmType
import com.veepoo.protocol.model.enums.EMultiAlarmOprate
import com.veepoo.protocol.model.enums.EOprateStauts
import com.veepoo.protocol.model.enums.EPwdStatus
import com.veepoo.protocol.model.enums.ESex
import com.veepoo.protocol.model.enums.ESportType
import com.veepoo.protocol.model.enums.EWeatherOprateStatus
import com.veepoo.protocol.model.enums.EWeatherType
import com.veepoo.protocol.model.enums.HealthRemindType
import com.veepoo.protocol.model.settings.Alarm2Setting
import com.veepoo.protocol.model.settings.CustomSettingData
import com.veepoo.protocol.model.settings.LongSeatSetting
import com.veepoo.protocol.model.settings.NightTurnWristSetting
import com.veepoo.protocol.model.settings.ScreenSetting
import com.veepoo.protocol.model.settings.TextAlarm2Setting
import com.veepoo.protocol.model.settings.WeatherStatusSetting
import com.veepoo.protocol.shareprence.VpSpGetUtil
import com.veepoo.protocol.util.TextAlarmSp
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var adapter: VeepooWearableAdapter
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPermissionCall: Pair<MethodCall, MethodChannel.Result>? = null
    private var pendingBluetoothCall: Pair<MethodCall, MethodChannel.Result>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!::adapter.isInitialized) adapter = VeepooWearableAdapter(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // FlutterActivity may configure the engine from super.onCreate before
        // this Activity's onCreate body resumes.
        if (!::adapter.isInitialized) adapter = VeepooWearableAdapter(applicationContext)
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHODS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            prepareCall(call, result)
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
            prepareCall(pending.first, pending.second)
        } else {
            pending.second.error("BLE_PERMISSION_DENIED", "允许相关权限后使用", null)
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != BLE_ENABLE_REQUEST) return
        val pending = pendingBluetoothCall ?: return
        pendingBluetoothCall = null
        if (resultCode == Activity.RESULT_OK && isBluetoothEnabled()) {
            prepareCall(pending.first, pending.second)
        } else {
            pending.second.error("BLUETOOTH_DISABLED", "请开启手机蓝牙后再扫描设备", null)
        }
    }

    private fun prepareCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method !in BLE_PERMISSION_METHODS) {
            dispatch(call, result)
            return
        }
        if (!hasBlePermissions()) {
            pendingPermissionCall = call to result
            ActivityCompat.requestPermissions(this, requiredBlePermissions(), BLE_PERMISSION_REQUEST)
            return
        }
        if (!isBluetoothEnabled()) {
            if (pendingBluetoothCall != null) {
                result.error("BLUETOOTH_ENABLE_IN_PROGRESS", "正在等待开启蓝牙", null)
                return
            }
            pendingBluetoothCall = call to result
            try {
                startActivityForResult(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE), BLE_ENABLE_REQUEST)
            } catch (error: Throwable) {
                pendingBluetoothCall = null
                Log.w("SaidianMain", "Unable to open Bluetooth settings", error)
                result.error("BLUETOOTH_ENABLE_FAILED", "无法打开系统蓝牙开关，请手动开启", null)
            }
            return
        }
        if (call.method == "scanDevices" &&
            Build.VERSION.SDK_INT <= Build.VERSION_CODES.R &&
            !isLocationServiceEnabled()
        ) {
            result.error("LOCATION_SERVICE_DISABLED", "请开启手机定位后再查找手表", null)
            return
        }
        dispatch(call, result)
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result) {
        // The official Veepoo demo calls VPOperateManager from the Activity
        // thread. Dart serializes watch operations, so keep that thread affinity.
        if (Looper.myLooper() == Looper.getMainLooper()) {
            handleMethod(call, result)
        } else {
            mainHandler.post { handleMethod(call, result) }
        }
    }

    private fun handleMethod(call: MethodCall, result: MethodChannel.Result) {
        val callback = FlutterResultCallback<Any?>(result, mainHandler)
        val feature = call.argument<String>("feature").orEmpty()
        adapter.prepareForOperation(call.method, feature) {
            try {
                when (call.method) {
                    "scanDevices" -> adapter.scanDevices(callback)
                    "stopScan" -> adapter.stopScan(callback.unit())
                    "connect" ->
                        adapter.connect(
                            call.argument<String>("deviceId").orEmpty(),
                            WearableProfile.from(call.argument<Map<*, *>>("profile")),
                            callback.unit(),
                        )
                    "disconnect" -> adapter.disconnect(callback.unit())
                    "getCapabilities" -> callback.success(adapter.getCapabilities())
                    "syncHealthData" -> adapter.syncHealthData(call.argument<String>("cursor"), callback)
                    "startMeasurement" ->
                        adapter.startMeasurement(call.argument<String>("metric").orEmpty(), callback.unit())
                    "stopMeasurement" ->
                        adapter.stopMeasurement(call.argument<String>("metric").orEmpty(), callback.unit())
                    "startSport" ->
                        adapter.startSport(call.argument<String>("mode").orEmpty(), callback.unit())
                    "stopSport" -> adapter.stopSport(callback.unit())
                    "readSportRecords" -> adapter.readSportRecords(callback)
                    "readAutoMeasureSettings" -> adapter.readAutoMeasureSettings(callback)
                    "setAutoMeasureSetting" ->
                        adapter.setAutoMeasureSetting(
                            call.argument<String>("type").orEmpty(),
                            call.argument<Boolean>("enabled") == true,
                            callback.unit(),
                        )
                    "readHeartRateWarning" -> adapter.readHeartRateWarning(callback)
                    "setHeartRateWarning" ->
                        adapter.setHeartRateWarning(
                            call.argument<Int>("value") ?: 120,
                            callback.unit(),
                        )
                    "readDeviceFeature" -> adapter.readDeviceFeature(feature, callback)
                    "writeDeviceFeature" ->
                        adapter.writeDeviceFeature(
                            feature,
                            call.argument<Map<*, *>>("values"),
                            callback.unit(),
                        )
                    "triggerDeviceAction" ->
                        adapter.triggerDeviceAction(
                            feature,
                            call.argument<Boolean>("enabled") != false,
                            callback.unit(),
                        )
                    else -> callback.notImplemented()
                }
            } catch (error: Throwable) {
                callback.error("WEARABLE_ERROR", error.message ?: "设备通信失败")
            }
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

    private fun isBluetoothEnabled(): Boolean {
        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return bluetoothManager?.adapter?.isEnabled == true
    }

    private fun isLocationServiceEnabled(): Boolean {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            locationManager.isLocationEnabled
        } else {
            @Suppress("DEPRECATION")
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    override fun onDestroy() {
        if (::adapter.isInitialized) adapter.close()
        super.onDestroy()
    }

    companion object {
        private const val METHODS_CHANNEL = "cc.saidian/wearable_methods"
        private const val EVENTS_CHANNEL = "cc.saidian/wearable_events"
        private const val BLE_PERMISSION_REQUEST = 7001
        private const val BLE_ENABLE_REQUEST = 7002
        private val BLE_PERMISSION_METHODS =
            setOf(
                "scanDevices",
                "connect",
                "startSport",
                "stopSport",
                "readSportRecords",
                "readAutoMeasureSettings",
                "setAutoMeasureSetting",
                "readHeartRateWarning",
                "setHeartRateWarning",
                "readDeviceFeature",
                "writeDeviceFeature",
                "triggerDeviceAction",
            )
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

private data class WearableProfile(
    val gender: Int,
    val heightCm: Int,
    val weightKg: Int,
    val age: Int,
    val targetSteps: Int,
) {
    companion object {
        fun from(value: Map<*, *>?): WearableProfile =
            WearableProfile(
                gender = (value?.get("gender") as? Number)?.toInt()?.coerceIn(1, 2) ?: 1,
                heightCm = (value?.get("heightCm") as? Number)?.toInt()?.coerceIn(80, 240) ?: 175,
                weightKg = (value?.get("weightKg") as? Number)?.toInt()?.coerceIn(20, 250) ?: 70,
                age = (value?.get("age") as? Number)?.toInt()?.coerceIn(5, 120) ?: 30,
                targetSteps =
                    (value?.get("targetSteps") as? Number)?.toInt()?.coerceIn(1000, 100000)
                        ?: 8000,
            )
    }
}

private class VeepooWearableAdapter(context: android.content.Context) {
    private val appContext = context.applicationContext
    private val manager: VPOperateManager
    private val connectionHandler = Handler(Looper.getMainLooper())
    private val devices = linkedMapOf<String, SearchResult>()
    @Volatile private var activeScanCallback: ResultCallback<List<Map<String, Any?>>>? = null
    @Volatile private var scanGeneration = 0
    @Volatile private var connectionGeneration = 0
    @Volatile private var activeConnectionCallback: ResultCallback<Unit>? = null
    @Volatile private var activeTransportConnected = false
    private var connectionTimeoutTask: Runnable? = null
    private var personSyncTimeoutTask: Runnable? = null
    @Volatile private var healthSyncGeneration = 0
    @Volatile private var activeHealthSyncCallback: ResultCallback<List<Map<String, Any?>>>? = null
    @Volatile private var jlWatchFaceSessionActive = false
    private val availableWatchFacePaths = linkedSetOf<String>()
    private var activeHealthSyncDeviceId = ""
    private var healthSyncTimeoutTask: Runnable? = null
    private var connectStatusListener: IABleConnectStatusListener? = null
    private var connectStatusAddress = ""
    private var connectingDeviceId = ""
    private var eventListener: ((Map<String, Any?>) -> Unit)? = null
    private var connectedDeviceId = ""
    private var connectedDeviceName = ""
    private var firmwareVersion = ""
    private var watchDataDays = 3
    private var capabilities = defaultCapabilities()
    private var activeMetric: String? = null
    private val autoMeasureSettings = mutableMapOf<String, AutoMeasureData>()
    private var lastScreenSetting: ScreenSetting? = null
    private var lastSocialMsgSetting: FunctionSocailMsgData? = null
    private val cachedContacts = mutableListOf<Contact>()
    private val cachedHealthReminders = linkedMapOf<HealthRemindType, HealthRemind>()
    private val cachedWorldClocks = mutableListOf<WorldClock>()
    private var weatherCrc = 0
    private var lastWeatherCity = ""
    private var lastWeatherUpdatedAt = 0L
    private val cameraListener =
        object : ICameraDataListener {
            override fun OnCameraDataChange(status: ECameraStatus) {
                if (status == ECameraStatus.TAKEPHOTO_CAN) {
                    emit("cameraShutter", mapOf("deviceId" to connectedDeviceId))
                }
            }
        }

    init {
        // init() can replace the SDK singleton on first use. Re-read it after
        // initialization so scan, connect and protocol operations share state.
        VPOperateManager.getInstance().init(appContext)
        manager = VPOperateManager.getInstance()
        manager.setAutoConnectBTBySdk(false)
        manager.setCameraListener(cameraListener)
    }

    fun setEventListener(listener: ((Map<String, Any?>) -> Unit)?) {
        eventListener = listener
    }

    fun prepareForOperation(_method: String, _feature: String, operation: () -> Unit) {
        // HBand requires JieLi authentication only once for the lifetime of the
        // app/device connection. Releasing it between ordinary device commands
        // leaves the BLE link alive but makes a later authentication time out.
        // Flutter already serializes commands, so retain the session until the
        // watch disconnects or this adapter closes.
        operation()
    }

    private fun releaseJLWatchFaceSession() {
        availableWatchFacePaths.clear()
        if (!jlWatchFaceSessionActive) return
        jlWatchFaceSessionActive = false
        runCatching { manager.releaseJLSDK() }
            .onFailure { Log.w(LOG_TAG, "JL watch-face session release failed", it) }
    }

    fun scanDevices(callback: ResultCallback<List<Map<String, Any?>>>) {
        // The Veepoo SDK caches its Bluetooth state and may briefly report
        // `false` after Android's adapter has already entered STATE_ON. The
        // system adapter is authoritative here; permissions were verified by
        // MainActivity before this method was dispatched.
        if (!isSystemBluetoothEnabled()) {
            callback.error("BLUETOOTH_DISABLED", "请开启手机蓝牙后再扫描设备")
            return
        }
        manager.stopScanDevice()
        finishScan()
        synchronized(devices) { devices.clear() }
        val generation =
            synchronized(this) {
                scanGeneration += 1
                activeScanCallback = callback
                scanGeneration
            }
        emit("state", mapOf("value" to "scanning"))
        manager.startScanDevice(
            12,
            object : SearchResponse {
                override fun onSearchStarted() = Unit

                override fun onDeviceFounded(device: SearchResult) {
                    if (generation != scanGeneration || activeScanCallback == null) return
                    val payload =
                        synchronized(devices) {
                            devices[device.address] = device
                            scanDevicePayload(device)
                        }
                    emit("scanDevice", payload)
                }

                override fun onSearchStopped() = finishScan(generation)

                override fun onSearchCanceled() = finishScan(generation)
            },
        )
    }

    fun stopScan(callback: ResultCallback<Unit>) {
        manager.stopScanDevice()
        finishScan()
        callback.success(Unit)
    }

    private fun finishScan(expectedGeneration: Int? = null) {
        val callback =
            synchronized(this) {
                if (expectedGeneration != null && expectedGeneration != scanGeneration) {
                    return@synchronized null
                }
                val current = activeScanCallback
                activeScanCallback = null
                current
            } ?: return
        val result =
            synchronized(devices) {
                devices.values
                    .sortedByDescending { it.rssi }
                    .map(::scanDevicePayload)
            }
        emit("state", mapOf("value" to "disconnected"))
        callback.success(result)
    }

    private fun scanDevicePayload(device: SearchResult): Map<String, Any?> =
        mapOf(
            "id" to device.address,
            "name" to (device.name?.takeIf { it.isNotBlank() } ?: "未命名设备"),
            "model" to (device.name?.takeIf { it.isNotBlank() } ?: "Veepoo"),
            "rssi" to device.rssi,
        )

    fun connect(
        deviceId: String,
        profile: WearableProfile,
        callback: ResultCallback<Unit>,
    ) {
        val device = synchronized(devices) { devices[deviceId] }
        if (device == null) {
            callback.error("DEVICE_NOT_FOUND", "设备已离开扫描范围，请重新扫描")
            return
        }
        manager.stopScanDevice()
        finishScan()
        val advertisedName = device.name.orEmpty()
        val sdkCurrentAddress = VPOperateManager.getCurrentDeviceAddress().orEmpty()
        val connectedAddress =
            when {
                sdkCurrentAddress.isNotBlank() &&
                    manager.getConnectStatus(sdkCurrentAddress) == Constants.STATUS_CONNECTED ->
                    sdkCurrentAddress
                manager.getConnectStatus(deviceId) == Constants.STATUS_CONNECTED -> deviceId
                else -> ""
            }
        if (connectedAddress.equals(deviceId, ignoreCase = true) &&
            connectedDeviceId.equals(deviceId, ignoreCase = true)
        ) {
            emit("state", mapOf("value" to "ready"))
            callback.success(Unit)
            return
        }

        val generation = beginConnectionAttempt(deviceId, callback)
        emit("state", mapOf("value" to "connecting"))
        if (connectedAddress.isNotBlank()) {
            // connectDevice silently returns for an already connected address.
            // Reset any stale/current SDK session and wait for its real state.
            releaseJLWatchFaceSession()
            unregisterConnectStatusListener()
            manager.disconnectWatch { code ->
                connectionHandler.post {
                    if (!isConnectionAttemptActive(generation, callback)) return@post
                    if (code == Code.REQUEST_SUCCESS) {
                        waitForSdkDisconnect(
                            generation,
                            connectedAddress,
                            deviceId,
                            advertisedName,
                            profile,
                            callback,
                        )
                    } else {
                        failConnection(
                            generation,
                            callback,
                            "RECONNECT_RESET_FAILED",
                            "已有连接未能断开，请关闭手表其他手机的连接后重试",
                        )
                    }
                }
            }
            return
        }
        startSdkConnection(generation, deviceId, advertisedName, profile, callback)
    }

    private fun beginConnectionAttempt(
        deviceId: String,
        callback: ResultCallback<Unit>,
    ): Int {
        cancelActiveHealthSync(
            "HEALTH_SYNC_CANCELLED",
            "连接设备已切换，历史数据同步已取消",
            emitError = false,
        )
        cancelActiveConnectionAttempt(
            "CONNECT_SUPERSEDED",
            "已有连接任务被新的连接操作替代",
            emitError = true,
        )
        firmwareVersion = ""
        watchDataDays = 3
        capabilities = defaultCapabilities()
        val generation =
            synchronized(this) {
                connectionGeneration += 1
                activeConnectionCallback = callback
                activeTransportConnected = false
                connectionGeneration
            }
        val timeout =
            Runnable {
                failConnection(
                    generation,
                    callback,
                    "CONNECT_TIMEOUT",
                    "设备连接超时，请确认手表未连接其他手机后重试",
                )
            }
        connectionTimeoutTask = timeout
        connectionHandler.postDelayed(timeout, CONNECTION_FLOW_TIMEOUT_MS)
        connectingDeviceId = deviceId
        connectedDeviceId = ""
        return generation
    }

    private fun waitForSdkDisconnect(
        generation: Int,
        addressToWait: String,
        deviceId: String,
        advertisedName: String,
        profile: WearableProfile,
        callback: ResultCallback<Unit>,
        remainingChecks: Int = STALE_DISCONNECT_CHECKS,
    ) {
        if (!isConnectionAttemptActive(generation, callback)) return
        if (manager.getConnectStatus(addressToWait) != Constants.STATUS_CONNECTED) {
            startSdkConnection(generation, deviceId, advertisedName, profile, callback)
            return
        }
        if (remainingChecks <= 0) {
            failConnection(
                generation,
                callback,
                "RECONNECT_RESET_TIMEOUT",
                "已有蓝牙连接未能完全断开，请关闭手表蓝牙后重试",
            )
            return
        }
        connectionHandler.postDelayed(
            {
                waitForSdkDisconnect(
                    generation,
                    addressToWait,
                    deviceId,
                    advertisedName,
                    profile,
                    callback,
                    remainingChecks - 1,
                )
            },
            STALE_DISCONNECT_POLL_MS,
        )
    }

    private fun startSdkConnection(
        generation: Int,
        deviceId: String,
        advertisedName: String,
        profile: WearableProfile,
        callback: ResultCallback<Unit>,
    ) {
        if (!isConnectionAttemptActive(generation, callback)) return
        val displayName = advertisedName.ifBlank { "未命名设备" }
        manager.setDeviceShowConfirm(true)
        registerConnectStatusListener(deviceId, generation)
        val authenticationStarted = AtomicBoolean(false)
        val connectResponse =
            IConnectResponse { code, _, _ ->
                connectionHandler.post {
                    if (!isConnectionAttemptActive(generation, callback)) return@post
                    if (code == Code.REQUEST_SUCCESS) {
                        activeTransportConnected = true
                    } else {
                        failConnection(
                            generation,
                            callback,
                            "CONNECT_FAILED",
                            "设备连接失败，请保持手表靠近手机后重试",
                        )
                    }
                }
            }
        val notifyResponse =
            INotifyResponse { code ->
                connectionHandler.post {
                    if (!isConnectionAttemptActive(generation, callback)) return@post
                    if (code == Code.REQUEST_SUCCESS &&
                        authenticationStarted.compareAndSet(false, true)
                    ) {
                        activeTransportConnected = true
                        authenticate(generation, deviceId, displayName, profile, callback)
                    } else if (code != Code.REQUEST_SUCCESS) {
                        failConnection(
                            generation,
                            callback,
                            "NOTIFY_FAILED",
                            "设备连接失败，请保持手表靠近手机后重试",
                        )
                    }
                }
            }
        if (advertisedName.isBlank()) {
            manager.connectDevice(deviceId, connectResponse, notifyResponse)
        } else {
            manager.connectDevice(deviceId, advertisedName, connectResponse, notifyResponse)
        }
    }

    private fun authenticate(
        generation: Int,
        deviceId: String,
        deviceName: String,
        profile: WearableProfile,
        callback: ResultCallback<Unit>,
    ) {
        if (!isConnectionAttemptActive(generation, callback)) return
        emit("state", mapOf("value" to "authenticating"))
        val passwordStarted = AtomicBoolean(false)
        manager.confirmDevicePwd(
            IBleWriteResponse { code ->
                connectionHandler.post {
                    if (!isConnectionAttemptActive(generation, callback)) return@post
                    if (code != Code.REQUEST_SUCCESS) {
                        failConnection(
                            generation,
                            callback,
                            "PASSWORD_WRITE_FAILED",
                            "设备确认失败，请重新连接并在手表上确认",
                        )
                    }
                }
            },
            object : IPwdDataListener {
                override fun onPwdDataChange(data: PwdData) {
                    connectionHandler.post {
                        if (!isConnectionAttemptActive(generation, callback)) return@post
                        firmwareVersion = data.deviceVersion.orEmpty()
                        if (data.getmStatus() in
                            setOf(EPwdStatus.CHECK_SUCCESS, EPwdStatus.CHECK_AND_TIME_SUCCESS) &&
                            passwordStarted.compareAndSet(false, true)
                        ) {
                            syncPersonInfo(
                                generation,
                                deviceId,
                                deviceName,
                                profile,
                                callback,
                            )
                        } else if (data.getmStatus() == EPwdStatus.CHECK_FAIL) {
                            failConnection(
                                generation,
                                callback,
                                "PASSWORD_FAILED",
                                "设备密码校验失败",
                            )
                        }
                    }
                }

                override fun onConnectionConfirmTimeout() {
                    connectionHandler.post {
                        if (!isConnectionAttemptActive(generation, callback)) return@post
                        // The SDK requires an explicit disconnect after this callback.
                        failConnection(
                            generation,
                            callback,
                            "CONFIRM_TIMEOUT",
                            "设备端连接确认超时，请在手表上确认连接",
                        )
                    }
                }
            },
            object : IDeviceFuctionDataListener {
                override fun onFunctionSupportDataChange(data: FunctionDeviceSupportData) {
                    connectionHandler.post {
                        if (connectionGeneration != generation) return@post
                        watchDataDays = data.getWathcDay().coerceAtLeast(1)
                        capabilities = capabilitiesFrom(data)
                    }
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

    private fun syncPersonInfo(
        generation: Int,
        deviceId: String,
        deviceName: String,
        profile: WearableProfile,
        callback: ResultCallback<Unit>,
    ) {
        if (!isConnectionAttemptActive(generation, callback)) return
        emit("state", mapOf("value" to "syncing"))
        val sex = if (profile.gender == 2) ESex.WOMEN else ESex.MAN
        val person =
            PersonInfoData(
                sex,
                profile.heightCm,
                profile.weightKg,
                profile.age,
                profile.targetSteps,
            )
        val timeout =
            Runnable {
                completeConnection(generation, callback, deviceId, deviceName)
            }
        personSyncTimeoutTask?.let(connectionHandler::removeCallbacks)
        personSyncTimeoutTask = timeout
        connectionHandler.postDelayed(timeout, PERSON_SYNC_TIMEOUT_MS)
        manager.syncPersonInfo(
            IBleWriteResponse { code ->
                connectionHandler.post {
                    if (!isConnectionAttemptActive(generation, callback)) return@post
                    if (code != Code.REQUEST_SUCCESS) {
                        completeConnection(generation, callback, deviceId, deviceName)
                    }
                }
            },
            IPersonInfoDataListener {
                connectionHandler.post {
                    if (!isConnectionAttemptActive(generation, callback)) return@post
                    // Password verification establishes protocol readiness. Some
                    // older firmware rejects this profile write; keep the link ready.
                    completeConnection(generation, callback, deviceId, deviceName)
                }
            },
            person,
        )
    }

    private fun isConnectionAttemptActive(
        generation: Int,
        callback: ResultCallback<Unit>,
    ): Boolean =
        synchronized(this) {
            connectionGeneration == generation && activeConnectionCallback === callback
        }

    private fun activeConnectionFor(generation: Int): ResultCallback<Unit>? =
        synchronized(this) {
            activeConnectionCallback?.takeIf { connectionGeneration == generation }
        }

    private fun finishConnectionAttempt(
        generation: Int,
        callback: ResultCallback<Unit>,
    ): Boolean {
        val claimed =
            synchronized(this) {
                if (connectionGeneration != generation ||
                    activeConnectionCallback !== callback
                ) {
                    false
                } else {
                    activeConnectionCallback = null
                    activeTransportConnected = false
                    true
                }
            }
        if (claimed) cancelConnectionTimers()
        return claimed
    }

    private fun completeConnection(
        generation: Int,
        callback: ResultCallback<Unit>,
        deviceId: String,
        deviceName: String,
    ) {
        if (!finishConnectionAttempt(generation, callback)) return
        connectingDeviceId = ""
        connectedDeviceId = deviceId
        connectedDeviceName = deviceName
        emit(
            "deviceDetails",
            buildMap {
                put("id", deviceId)
                put("name", deviceName)
                put("model", deviceName)
                firmwareVersion.takeIf { it.isNotBlank() }?.let { put("firmwareVersion", it) }
            },
        )
        emit("state", mapOf("value" to "ready"))
        callback.success(Unit)
    }

    private fun failConnection(
        generation: Int,
        callback: ResultCallback<Unit>,
        code: String,
        message: String,
    ) {
        if (!finishConnectionAttempt(generation, callback)) return
        connectingDeviceId = ""
        connectedDeviceId = ""
        activeMetric = null
        releaseJLWatchFaceSession()
        unregisterConnectStatusListener()
        runCatching { manager.disconnectWatch { } }
        fail(callback, code, message)
    }

    private fun cancelActiveConnectionAttempt(
        code: String,
        message: String,
        emitError: Boolean,
    ) {
        val callback =
            synchronized(this) {
                val current = activeConnectionCallback
                activeConnectionCallback = null
                activeTransportConnected = false
                connectionGeneration += 1
                current
            }
        cancelConnectionTimers()
        if (callback != null) {
            if (emitError) emit("error", mapOf("code" to code, "message" to message))
            callback.error(code, message)
        }
    }

    private fun cancelConnectionTimers() {
        connectionTimeoutTask?.let(connectionHandler::removeCallbacks)
        connectionTimeoutTask = null
        personSyncTimeoutTask?.let(connectionHandler::removeCallbacks)
        personSyncTimeoutTask = null
    }

    fun disconnect(callback: ResultCallback<Unit>) {
        cancelActiveHealthSync(
            "HEALTH_SYNC_CANCELLED",
            "设备已断开，历史数据同步已取消",
            emitError = false,
        )
        cancelActiveConnectionAttempt(
            "CONNECT_CANCELLED",
            "连接任务已取消",
            emitError = false,
        )
        connectingDeviceId = ""
        releaseJLWatchFaceSession()
        unregisterConnectStatusListener()
        manager.disconnectWatch { code ->
            connectionHandler.post {
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
    }

    fun getCapabilities(): Map<String, Any?> = capabilities

    fun readDeviceFeature(
        feature: String,
        callback: ResultCallback<Any?>,
    ) {
        ensureConnected(callback) ?: return
        when (feature) {
            "watch_faces", "photo_watch_face" -> readWatchFaces(callback)
            "screen_display" -> readScreenDisplay(callback)
            "phone_calls" -> readPhoneCalls(callback)
            "contacts" -> readContacts(callback)
            "notifications" -> readNotifications(callback)
            "alarms" -> readAlarms(callback)
            "weather" -> readWeather(callback)
            "world_clock" -> readWorldClocks(callback)
            "health_reminders" -> readHealthReminders(callback)
            "health_assessment" -> readHealthAssessment(callback)
            else -> callback.error("FEATURE_UNAVAILABLE", "此功能暂时无法使用，请稍后再试")
        }
    }

    private fun readScreenDisplay(callback: ResultCallback<Any?>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        if (!preferences.isSupportScreenlight &&
            !preferences.isSupportScreenlightTime &&
            !preferences.isSupportNightturnSetting
        ) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val values =
            mutableMapOf<String, Any?>(
                "brightness" to 1,
                "maximumBrightness" to 1,
                "automaticBrightness" to false,
                "raiseToWakeSupported" to preferences.isSupportNightturnSetting,
            )

        fun readRaiseToWake() {
            if (!preferences.isSupportNightturnSetting) {
                callback.success(values)
                return
            }
            val completed = AtomicBoolean(false)
            fun finish(success: Boolean) {
                if (!completed.compareAndSet(false, true)) return
                if (success) callback.success(values)
                else callback.error("READ_FAILED", "抬腕亮屏设置读取失败，请稍后重试")
            }
            manager.readNightTurnWriste(
                IBleWriteResponse { code -> if (code != Code.REQUEST_SUCCESS) finish(false) },
                INightTurnWristeDataListener { data ->
                    if (data.oprateStauts?.name != "SUCCESS") {
                        finish(false)
                        return@INightTurnWristeDataListener
                    }
                    values["raiseToWakeEnabled"] = data.isNightTureWirsteStatusOpen
                    values["raiseToWakeCustomTimeSupported"] = data.isSupportCustomSettingTime
                    values["raiseToWakeStartMinutes"] =
                        (data.startTime?.hour ?: 0) * 60 + (data.startTime?.minute ?: 0)
                    values["raiseToWakeEndMinutes"] =
                        (data.endTime?.hour ?: 0) * 60 + (data.endTime?.minute ?: 0)
                    values["raiseToWakeSensitivity"] = data.level.coerceIn(1, 10)
                    finish(true)
                },
            )
        }

        fun readDuration() {
            if (!preferences.isSupportScreenlightTime) {
                readRaiseToWake()
                return
            }
            val completed = AtomicBoolean(false)
            fun finish(success: Boolean) {
                if (!completed.compareAndSet(false, true)) return
                if (success) readRaiseToWake()
                else callback.error("READ_FAILED", "亮屏时长读取失败，请稍后重试")
            }
            manager.readScreenLightTime(
                IBleWriteResponse { code -> if (code != Code.REQUEST_SUCCESS) finish(false) },
                IScreenLightTimeListener { data ->
                    if (data.screenLightState?.name != "READ_SUCCESS") {
                        finish(false)
                        return@IScreenLightTimeListener
                    }
                    values["durationSeconds"] = data.currentDuration
                    values["minimumDurationSeconds"] = data.minDuration
                    values["maximumDurationSeconds"] = data.maxDuration
                    finish(true)
                },
            )
        }

        if (!preferences.isSupportScreenlight) {
            readDuration()
            return
        }
        val completed = AtomicBoolean(false)
        fun finishBrightness(success: Boolean) {
            if (!completed.compareAndSet(false, true)) return
            if (success) readDuration()
            else callback.error("READ_FAILED", "屏幕亮度读取失败，请稍后重试")
        }
        manager.readScreenLight(
            IBleWriteResponse { code -> if (code != Code.REQUEST_SUCCESS) finishBrightness(false) },
            IScreenLightListener { data ->
                val setting = data?.screenSetting
                if (setting == null || data.status?.name != "READ_SUCCESS") {
                    finishBrightness(false)
                    return@IScreenLightListener
                }
                lastScreenSetting = setting
                values["brightness"] = setting.otherLeverl
                values["maximumBrightness"] = setting.maxLevel.coerceAtLeast(1)
                values["automaticBrightness"] = setting.auto == 1
                finishBrightness(true)
            },
        )
    }

    fun writeDeviceFeature(
        feature: String,
        values: Map<*, *>?,
        callback: ResultCallback<Unit>,
    ) {
        ensureConnected(callback) ?: return
        when (feature) {
            "watch_faces", "photo_watch_face" -> writeWatchFaces(feature, values, callback)
            "screen_display" -> writeScreenDisplay(values, callback)
            "phone_calls" -> writePhoneCalls(values, callback)
            "contacts" -> writeContact(values, callback)
            "notifications" -> writeNotifications(values, callback)
            "alarms" -> writeAlarm(values, callback)
            "weather" -> writeWeather(values, callback)
            "world_clock" -> writeWorldClock(values, callback)
            "health_reminders" -> writeHealthReminder(values, callback)
            "health_assessment" -> writeHealthAssessment(values, callback)
            else -> callback.error("FEATURE_UNAVAILABLE", "此功能暂时无法使用，请稍后再试")
        }
    }

    private fun readWatchFaces(callback: ResultCallback<Any?>) {
        if (!manager.isJLCPUPlatform) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val completed = AtomicBoolean(false)
        val authenticationStarted = AtomicBoolean(false)
        val timeout =
            Runnable {
                if (completed.compareAndSet(false, true)) {
                    Log.w(LOG_TAG, "JL watch-face session timed out")
                    callback.error("READ_TIMEOUT", "表盘连接超时，请保持手表亮屏并靠近手机后重试")
                }
            }
        fun fail(code: String, message: String, cause: Any? = null) {
            if (!completed.compareAndSet(false, true)) return
            connectionHandler.removeCallbacks(timeout)
            Log.w(LOG_TAG, "JL watch-face session failed: $cause")
            callback.error(code, message)
        }
        lateinit var loadDialList: () -> Unit
        lateinit var authenticate: () -> Unit
        loadDialList = {
            if (!completed.get()) {
                manager.listJLWatchList(
                    object : JLWatchFaceManager.OnWatchDialInfoGetListener {
                        override fun onGettingWatchDialInfo() {
                            emit(
                                "deviceFeatureProgress",
                                mapOf("feature" to "watch_faces", "progress" to 5),
                            )
                        }

                        override fun onWatchDialInfoGetStart() {
                            emit(
                                "deviceFeatureProgress",
                                mapOf("feature" to "watch_faces", "progress" to 10),
                            )
                        }

                        override fun onWatchDialInfoGetComplete() = Unit

                        override fun onWatchDialInfoGetSuccess(
                            systemFatFiles: MutableList<FatFile>,
                            serverFatFiles: MutableList<FatFile>,
                            picFatFile: FatFile?,
                        ) {
                            val faceManager = JLWatchFaceManager.getInstance()
                            val currentReadFinished = AtomicBoolean(false)
                            val allWatchFiles = mutableListOf<FatFile>()
                            fun completeWithCurrent(current: FatFile?) {
                                connectionHandler.post {
                                    if (!currentReadFinished.compareAndSet(false, true)) return@post
                                    if (!completed.compareAndSet(false, true)) return@post
                                    connectionHandler.removeCallbacks(timeout)
                                    if (current != null) faceManager.currentFatFile = current
                                    val currentPath = current?.path.orEmpty()
                                    val items = mutableListOf<Map<String, Any?>>()
                                    systemFatFiles.forEachIndexed { index, file ->
                                        items += watchFacePayload(file, "system", index, currentPath)
                                    }
                                    serverFatFiles.forEachIndexed { index, file ->
                                        items += watchFacePayload(file, "downloaded", index, currentPath)
                                    }
                                    if (picFatFile != null) {
                                        items += watchFacePayload(picFatFile, "photo", 0, currentPath)
                                    }
                                    Log.i(
                                        LOG_TAG,
                                        "All watch faces: ${allWatchFiles.joinToString { it.path }}",
                                    )
                                    allWatchFiles
                                        .filter { file ->
                                            file.name?.startsWith("WATCH", ignoreCase = true) == true &&
                                                items.none { it["id"] == file.path }
                                        }.forEachIndexed { index, file ->
                                            val type = if (file.path == currentPath) "current" else "other"
                                            items += watchFacePayload(file, type, index, currentPath)
                                        }
                                    if (current != null && items.none { it["id"] == currentPath }) {
                                        items += watchFacePayload(current, "current", 0, currentPath)
                                    }
                                    availableWatchFacePaths.clear()
                                    items.mapNotNullTo(availableWatchFacePaths) {
                                        it["id"]?.toString()?.takeIf(String::isNotBlank)
                                    }
                                    emit(
                                        "deviceFeatureProgress",
                                        mapOf("feature" to "watch_faces", "progress" to 100),
                                    )
                                    callback.success(
                                        mapOf(
                                            "items" to items,
                                            "hasPhotoWatchFace" to (picFatFile != null),
                                        ),
                                    )
                                }
                            }
                            fun queryCurrentWatchFace() {
                                WatchManager.getInstance().getCurrentWatchInfo(
                                    object : OnWatchOpCallback<FatFile> {
                                        override fun onSuccess(result: FatFile?) {
                                            Log.i(LOG_TAG, "Current watch face: ${result?.path}")
                                            completeWithCurrent(result)
                                        }

                                        override fun onFailed(error: BaseError) {
                                            Log.w(LOG_TAG, "Current watch face read failed: $error")
                                            completeWithCurrent(null)
                                        }
                                    },
                                )
                            }
                            connectionHandler.postDelayed(
                                {
                                    if (currentReadFinished.get()) return@postDelayed
                                    Log.w(LOG_TAG, "Current watch face read timed out")
                                    completeWithCurrent(null)
                                },
                                WATCH_FACE_CURRENT_READ_TIMEOUT_MS,
                            )
                            connectionHandler.postDelayed(
                                {
                                    WatchManager.getInstance().listWatchList(
                                        object : OnWatchOpCallback<java.util.ArrayList<FatFile>> {
                                            override fun onSuccess(result: java.util.ArrayList<FatFile>?) {
                                                connectionHandler.post {
                                                    allWatchFiles.clear()
                                                    allWatchFiles.addAll(result.orEmpty())
                                                    queryCurrentWatchFace()
                                                }
                                            }

                                            override fun onFailed(error: BaseError) {
                                                Log.w(LOG_TAG, "Complete watch face list read failed: $error")
                                                connectionHandler.post { queryCurrentWatchFace() }
                                            }
                                        },
                                    )
                                },
                                WATCH_FACE_CURRENT_READ_DELAY_MS,
                            )
                        }

                        override fun onWatchDialInfoGetFailed(error: BaseError) {
                            fail("READ_FAILED", "表盘读取失败，请保持手表靠近手机后重试", error)
                        }
                    },
                )
            }
        }
        authenticate = {
            if (!completed.get() && authenticationStarted.compareAndSet(false, true)) {
                if (RcspAuthManager.getInstance().isAuthPass) {
                    loadDialList()
                } else {
                    emit(
                        "deviceFeatureProgress",
                        mapOf("feature" to "watch_faces", "progress" to 3),
                    )
                    manager.startJLDeviceAuth(
                        object : RcspAuthResponse {
                            override fun onRcspAuthStart() = Unit

                            override fun onRcspAuthSuccess() {
                                connectionHandler.post { loadDialList() }
                            }

                            override fun onRcspAuthFailed() {
                                connectionHandler.post {
                                    fail(
                                        "AUTH_FAILED",
                                        "手表未完成表盘连接，请保持手表亮屏后重试",
                                    )
                                }
                            }
                        },
                    )
                }
            }
        }
        jlWatchFaceSessionActive = true
        connectionHandler.postDelayed(timeout, WATCH_FACE_READ_TIMEOUT_MS)
        emit("deviceFeatureProgress", mapOf("feature" to "watch_faces", "progress" to 1))
        if (manager.isJLNotifyOpened) {
            authenticate()
        } else {
            manager.openJLDataNotify(
                object : BleNotifyResponse {
                    override fun onNotify(service: UUID, characteristic: UUID, value: ByteArray) = Unit

                    override fun onResponse(code: Int) {
                        connectionHandler.post {
                            if (completed.get()) return@post
                            if (code != Code.REQUEST_SUCCESS) {
                                fail("NOTIFY_FAILED", "手表未完成表盘连接，请稍后重试", code)
                                return@post
                            }
                            val mtuCompleted = AtomicBoolean(false)
                            val continueAfterMtu = {
                                if (mtuCompleted.compareAndSet(false, true)) authenticate()
                            }
                            manager.changeMTU(
                                JL_REQUESTED_MTU,
                                IMtuChangeListener { connectionHandler.post(continueAfterMtu) },
                            )
                            // Some Android Bluetooth stacks apply the request but
                            // omit the MTU callback. Authentication can still use
                            // the negotiated/default payload size in that case.
                            connectionHandler.postDelayed(continueAfterMtu, JL_MTU_CALLBACK_GRACE_MS)
                        }
                    }
                },
            )
        }
    }

    private fun watchFacePayload(
        file: FatFile,
        type: String,
        index: Int,
        currentPath: String,
    ): Map<String, Any?> {
        val displayName =
            when (type) {
                "system" -> "系统表盘 ${index + 1}"
                "downloaded" -> "已安装表盘 ${index + 1}"
                "photo" -> "照片表盘"
                "other" -> "手表表盘 ${index + 1}"
                else -> "当前表盘"
            }
        return mapOf(
            "id" to file.path,
            "name" to displayName,
            "fileName" to file.name,
            "type" to type,
            "index" to index,
            "isCurrent" to (currentPath.isNotBlank() && file.path == currentPath),
        )
    }

    private fun writeWatchFaces(
        feature: String,
        values: Map<*, *>?,
        callback: ResultCallback<Unit>,
    ) {
        if (!manager.isJLCPUPlatform) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        when (values?.get("operation")?.toString()) {
            "switch" -> switchWatchFace(values, callback)
            "upload_photo" -> uploadPhotoWatchFace(feature, values, callback)
            else -> callback.error("INVALID_ARGUMENT", "请选择要使用的表盘")
        }
    }

    private fun switchWatchFace(values: Map<*, *>, callback: ResultCallback<Unit>) {
        val targetPath = values["id"]?.toString()?.trim().orEmpty()
        val faceManager = JLWatchFaceManager.getInstance()
        val allowedPaths =
            buildSet {
                faceManager.systemFatFiles.orEmpty().mapTo(this) { it.path }
                faceManager.serverFatFiles.orEmpty().mapTo(this) { it.path }
                faceManager.picFatFile?.path?.let(::add)
                faceManager.currentFatFile?.path?.let(::add)
                WatchManager.getInstance().devFatFileList.orEmpty().mapTo(this) { it.path }
                addAll(availableWatchFacePaths)
            }
        if (targetPath.isBlank() || !allowedPaths.contains(targetPath)) {
            callback.error("INVALID_ARGUMENT", "请选择要使用的表盘")
            return
        }
        val completed = AtomicBoolean(false)
        val timeout =
            Runnable {
                if (completed.compareAndSet(false, true)) {
                    callback.error("WRITE_TIMEOUT", "表盘切换超时，请保持手表靠近手机后重试")
                }
            }
        fun finish(success: Boolean) {
            if (!completed.compareAndSet(false, true)) return
            connectionHandler.removeCallbacks(timeout)
            if (success) callback.success(Unit)
            else callback.error("WRITE_FAILED", "表盘切换失败，请保持手表靠近手机后重试")
        }
        fun verifyCurrentFace() {
            WatchManager.getInstance().getCurrentWatchInfo(
                object : OnWatchOpCallback<FatFile> {
                    override fun onSuccess(result: FatFile?) {
                        connectionHandler.post {
                            if (result != null) faceManager.currentFatFile = result
                            finish(result?.path == targetPath)
                        }
                    }

                    override fun onFailed(error: BaseError) {
                        Log.w(LOG_TAG, "Watch face verification failed: $error")
                        connectionHandler.post { finish(false) }
                    }
                },
            )
        }
        connectionHandler.postDelayed(timeout, WATCH_FACE_SWITCH_TIMEOUT_MS)
        WatchManager.getInstance().setCurrentWatchInfo(
            targetPath,
            object : OnWatchOpCallback<FatFile> {
                override fun onSuccess(result: FatFile?) {
                    connectionHandler.postDelayed(
                        { verifyCurrentFace() },
                        WATCH_FACE_VERIFY_DELAY_MS,
                    )
                }

                override fun onFailed(error: BaseError) {
                    Log.w(LOG_TAG, "Watch face switch failed: $error")
                    connectionHandler.post { finish(false) }
                }
            },
        )
    }

    private fun uploadPhotoWatchFace(
        feature: String,
        values: Map<*, *>?,
        callback: ResultCallback<Unit>,
    ) {
        val path = values?.get("imagePath")?.toString().orEmpty()
        val file = java.io.File(path)
        if (!file.isFile || file.length() <= 100) {
            callback.error("INVALID_ARGUMENT", "请选择一张有效照片")
            return
        }
        manager.setJLWatchPhotoDial(
            path,
            object : JLWatchFaceManager.JLTransferPicDialListener {
                override fun onLowPower() {
                    callback.error("LOW_POWER", "手表电量较低，请充电后再设置表盘")
                }

                override fun onJLTransferPicDialStart() {
                    emit("deviceFeatureProgress", mapOf("feature" to feature, "progress" to 0))
                }

                override fun onTransferPicDialProgress(progress: Int) {
                    emit(
                        "deviceFeatureProgress",
                        mapOf("feature" to feature, "progress" to progress.coerceIn(0, 100)),
                    )
                }

                override fun onScaleBGPFileTransferComplete() = Unit

                override fun onAIPreviewTransferComplete() = Unit

                override fun onBigBGPFileTransferComplete() = Unit

                override fun onTransferComplete() {
                    emit("deviceFeatureProgress", mapOf("feature" to feature, "progress" to 100))
                    callback.success(Unit)
                }

                override fun onTransferError(code: Int, errorMsg: String) {
                    Log.w(LOG_TAG, "Photo watch face failed: code=$code message=$errorMsg")
                    callback.error("TRANSFER_FAILED", "照片表盘设置失败，请保持手表靠近手机后重试")
                }
            },
        )
    }

    private fun readHealthAssessment(callback: ResultCallback<Any?>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportHealthAssessment) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        manager.readFunSwitchState(
            BleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    callback.error("READ_FAILED", "辅助评估设置读取失败，请稍后重试")
                }
            },
            IFunSwitchListener { _, states ->
                val items =
                    states.entries
                        .filter { it.value.isHaveFunction }
                        .sortedBy { it.key }
                        .map { (flag, status) ->
                            mapOf(
                                "id" to flag,
                                "label" to healthAssessmentLabel(flag),
                                "enabled" to status.isOpen,
                            )
                        }
                callback.success(mapOf("items" to items))
            },
        )
    }

    private fun writeHealthAssessment(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportHealthAssessment) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val flag = (values?.get("id") as? Number)?.toInt()
        if (flag == null) {
            callback.error("INVALID_ARGUMENT", "请选择需要设置的辅助评估")
            return
        }
        val expected =
            if (values["enabled"] == true) EFunctionStatus.SUPPORT_OPEN
            else EFunctionStatus.SUPPORT_CLOSE
        manager.setFunSwitchState(
            BleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    callback.error("WRITE_FAILED", "辅助评估设置保存失败，请稍后重试")
                }
            },
            IFunSwitchListener { _, states ->
                val saved = states[flag]
                if (saved == expected || saved?.isOpen == expected.isOpen) callback.success(Unit)
                else callback.error("WRITE_FAILED", "辅助评估设置保存失败，请稍后重试")
            },
            flag,
            expected,
        )
    }

    private fun healthAssessmentLabel(flag: Int): String =
        when (flag) {
            FunSwitchFlags.BLOOD_GLUCOSE -> "血糖趋势评估"
            FunSwitchFlags.BLOOD_PRESSURE -> "血压趋势评估"
            FunSwitchFlags.BLOOD_OXYGEN -> "血氧趋势评估"
            FunSwitchFlags.BODY_TEMPERATURE -> "体温趋势评估"
            FunSwitchFlags.HRV -> "心率变异性评估"
            FunSwitchFlags.STRESS -> "压力评估"
            FunSwitchFlags.MET -> "活动强度评估"
            FunSwitchFlags.BLOOD_COMPONENT -> "血液成分评估"
            FunSwitchFlags.BODY_COMPONENT -> "身体成分评估"
            FunSwitchFlags.MICRO_PHYSICAL_EXAMINATION -> "综合健康评估"
            FunSwitchFlags.EMOTION -> "情绪评估"
            FunSwitchFlags.FATIGUE -> "疲劳评估"
            FunSwitchFlags.FALLING_REMINDER -> "跌倒提醒"
            FunSwitchFlags.SKIN_ELECTRIC_TEST -> "皮肤状态评估"
            else -> "健康辅助功能"
        }

    private fun writeScreenDisplay(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)

        fun writeRaiseToWake() {
            if (!preferences.isSupportNightturnSetting) {
                callback.success(Unit)
                return
            }
            val setting =
                NightTurnWristSetting(
                    values?.get("raiseToWakeEnabled") == true,
                    minutesToTimeData((values?.get("raiseToWakeStartMinutes") as? Number)?.toInt() ?: 0),
                    minutesToTimeData((values?.get("raiseToWakeEndMinutes") as? Number)?.toInt() ?: 0),
                    (values?.get("raiseToWakeSensitivity") as? Number)?.toInt()?.coerceIn(1, 10) ?: 5,
                )
            val completed = AtomicBoolean(false)
            fun finish(success: Boolean) {
                if (!completed.compareAndSet(false, true)) return
                if (success) callback.success(Unit)
                else callback.error("WRITE_FAILED", "抬腕亮屏设置保存失败，请稍后重试")
            }
            manager.settingNightTurnWriste(
                IBleWriteResponse { code -> if (code != Code.REQUEST_SUCCESS) finish(false) },
                INightTurnWristeDataListener { data -> finish(data.oprateStauts?.name == "SUCCESS") },
                setting,
            )
        }

        fun writeDuration() {
            if (!preferences.isSupportScreenlightTime || values?.get("durationSeconds") !is Number) {
                writeRaiseToWake()
                return
            }
            val duration =
                (values["durationSeconds"] as Number).toInt().coerceIn(
                    (values["minimumDurationSeconds"] as? Number)?.toInt() ?: 1,
                    (values["maximumDurationSeconds"] as? Number)?.toInt() ?: 60,
                )
            val completed = AtomicBoolean(false)
            fun finish(success: Boolean) {
                if (!completed.compareAndSet(false, true)) return
                if (success) writeRaiseToWake()
                else callback.error("WRITE_FAILED", "亮屏时长保存失败，请稍后重试")
            }
            manager.setScreenLightTime(
                IBleWriteResponse { code -> if (code != Code.REQUEST_SUCCESS) finish(false) },
                IScreenLightTimeListener { data ->
                    finish(data.screenLightState?.name == "SETTING_SUCCESS")
                },
                duration,
            )
        }

        if (!preferences.isSupportScreenlight) {
            writeDuration()
            return
        }
        val setting = lastScreenSetting
        if (setting == null) {
            callback.error("READ_REQUIRED", "请先刷新屏幕设置后再保存")
            return
        }
        val maximum = setting.maxLevel.coerceAtLeast(1)
        val level = (values?.get("brightness") as? Number)?.toInt()?.coerceIn(1, maximum) ?: 1
        setting.otherLeverl = level
        setting.level = level
        setting.auto = if (values?.get("automaticBrightness") == true) 1 else 2
        val completed = AtomicBoolean(false)
        fun finishBrightness(success: Boolean) {
            if (!completed.compareAndSet(false, true)) return
            if (success) writeDuration()
            else callback.error("WRITE_FAILED", "屏幕亮度保存失败，请稍后重试")
        }
        manager.settingScreenLight(
            IBleWriteResponse { code -> if (code != Code.REQUEST_SUCCESS) finishBrightness(false) },
            IScreenLightListener { data ->
                finishBrightness(data?.status?.name == "SETTING_SUCCESS")
            },
            setting,
        )
    }

    private fun readPhoneCalls(callback: ResultCallback<Any?>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        if (!preferences.isSupportBTFunction) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        manager.readBTInfo(
            writeResponse(callback, "通话设置读取失败，请稍后重试"),
            object : IDeviceBTInfoListener {
                override fun onDeviceBTFunctionNotSupport() {
                    callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
                }

                override fun onDeviceBTInfoSettingSuccess(info: BTInfo) = Unit

                override fun onDeviceBTInfoSettingFailed() = Unit

                override fun onDeviceBTInfoReadSuccess(info: BTInfo) {
                    callback.success(phoneCallPayload(info))
                }

                override fun onDeviceBTInfoReadFailed() {
                    callback.error("READ_FAILED", "通话设置读取失败，请稍后重试")
                }

                override fun onDeviceBTInfoReport(info: BTInfo) = Unit
            },
        )
    }

    private fun writePhoneCalls(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportBTFunction) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        manager.setBTStatus(
            values?.get("autoConnect") != false,
            values?.get("enabled") != false,
            values?.get("audioEnabled") != false,
            false,
            IBleWriteResponse { code ->
                if (code == Code.REQUEST_SUCCESS) callback.success(Unit)
                else callback.error("WRITE_FAILED", "通话设置保存失败，请稍后重试")
            },
        )
    }

    private fun phoneCallPayload(info: BTInfo): Map<String, Any?> =
        mapOf(
            "enabled" to info.isBTOpen,
            "autoConnect" to info.isAutoCon,
            "audioEnabled" to info.isAudioOpen,
            "paired" to info.isHavePairInfo,
            "connectionStatus" to info.status.name.lowercase(Locale.ROOT),
        )

    private fun readNotifications(callback: ResultCallback<Any?>) {
        manager.readSocialMsg(
            writeResponse(callback, "消息通知设置读取失败，请稍后重试"),
            object : ISocialMsgDataListener {
                override fun onSocialMsgSupportDataChange(data: FunctionSocailMsgData) {
                    finishSocialRead(data, callback)
                }

                override fun onSocialMsgSupportDataChange2(data: FunctionSocailMsgData) {
                    finishSocialRead(data, callback)
                }
            },
        )
    }

    private fun finishSocialRead(
        data: FunctionSocailMsgData,
        callback: ResultCallback<Any?>,
    ) {
        lastSocialMsgSetting = data
        callback.success(socialPayload(data))
    }

    private fun socialPayload(data: FunctionSocailMsgData): Map<String, Any?> {
        val supported = mutableListOf<String>()
        fun value(key: String, status: EFunctionStatus?): Boolean {
            if (status?.isHaveFunction == true) supported += key
            return status?.isOpen == true
        }
        return mapOf(
            "incomingCall" to value("incomingCall", data.phone),
            "sms" to value("sms", data.msg),
            "wechat" to value("wechat", data.wechat),
            "qq" to value("qq", data.qq),
            "whatsapp" to value("whatsapp", data.whats),
            "dingtalk" to value("dingtalk", data.dingding),
            "wecom" to value("wecom", data.wxWork),
            "tiktok" to value("tiktok", data.tikTok),
            "telegram" to value("telegram", data.telegram),
            "otherApps" to value("otherApps", data.other),
            "supportedKeys" to supported,
            "notificationAccess" to
                NotificationManagerCompat.getEnabledListenerPackages(appContext)
                    .contains(appContext.packageName),
        )
    }

    private fun writeNotifications(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val setting = lastSocialMsgSetting
        if (setting == null) {
            callback.error("READ_REQUIRED", "请先刷新消息通知设置后再保存")
            return
        }
        fun enabled(key: String, current: EFunctionStatus?): EFunctionStatus =
            if (current?.isHaveFunction == true) {
                if (values?.get(key) == true) EFunctionStatus.SUPPORT_OPEN
                else EFunctionStatus.SUPPORT_CLOSE
            } else {
                current ?: EFunctionStatus.UNSUPPORT
            }
        setting.phone = enabled("incomingCall", setting.phone)
        setting.msg = enabled("sms", setting.msg)
        setting.wechat = enabled("wechat", setting.wechat)
        setting.qq = enabled("qq", setting.qq)
        setting.whats = enabled("whatsapp", setting.whats)
        setting.dingding = enabled("dingtalk", setting.dingding)
        setting.wxWork = enabled("wecom", setting.wxWork)
        setting.tikTok = enabled("tiktok", setting.tikTok)
        setting.telegram = enabled("telegram", setting.telegram)
        setting.other = enabled("otherApps", setting.other)
        manager.settingSocialMsg(
            writeResponse(callback, "消息通知设置保存失败，请稍后重试"),
            object : ISocialMsgDataListener {
                override fun onSocialMsgSupportDataChange(data: FunctionSocailMsgData) {
                    lastSocialMsgSetting = data
                    saveNotificationPreferences(values)
                    callback.success(Unit)
                }

                override fun onSocialMsgSupportDataChange2(data: FunctionSocailMsgData) {
                    lastSocialMsgSetting = data
                    saveNotificationPreferences(values)
                    callback.success(Unit)
                }
            },
            setting,
        )
    }

    private fun saveNotificationPreferences(values: Map<*, *>?) {
        val editor =
            appContext.getSharedPreferences(NOTIFICATION_PREFS, Context.MODE_PRIVATE).edit()
        NOTIFICATION_KEYS.forEach { key -> editor.putBoolean(key, values?.get(key) == true) }
        editor.apply()
    }

    private fun readAlarms(callback: ResultCallback<Any?>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        when {
            preferences.isSupportTextAlarm ->
                readTextAlarmList(
                    onSuccess = { items ->
                        callback.success(mapOf("items" to items.map(::alarmPayload)))
                    },
                    onFailure = { callback.error("READ_FAILED", "闹钟读取失败，请稍后重试") },
                )
            preferences.isSupportMultiAlarm ->
                readSceneAlarmList(
                    onSuccess = { items ->
                        callback.success(mapOf("items" to items.map(::alarmPayload)))
                    },
                    onFailure = { callback.error("READ_FAILED", "闹钟读取失败，请稍后重试") },
                )
            else -> callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
        }
    }

    private fun readSceneAlarmList(
        onSuccess: (List<Alarm2Setting>) -> Unit,
        onFailure: () -> Unit,
    ) {
        val completed = AtomicBoolean(false)
        fun complete(items: List<Alarm2Setting>) {
            if (completed.compareAndSet(false, true)) onSuccess(items)
        }
        fun fail() {
            if (completed.compareAndSet(false, true)) onFailure()
        }
        manager.readAlarm2(
            IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    fail()
                    return@IBleWriteResponse
                }
                // The SDK may either omit the callback or report SAME_CRC with
                // an empty callback list. In both cases its documented source
                // of truth is getAlarm2List().
                connectionHandler.postDelayed(
                    { complete(manager.getAlarm2List().orEmpty()) },
                    ALARM_CACHE_FALLBACK_MS,
                )
            },
            IAlarm2DataListListener { data ->
                when (data.oprate) {
                    EMultiAlarmOprate.READ_SUCCESS,
                    EMultiAlarmOprate.READ_SUCCESS_SAVE,
                    -> {
                        val items = data.alarm2SettingList.orEmpty()
                        if (items.isNotEmpty()) complete(items)
                    }
                    EMultiAlarmOprate.READ_SUCCESS_NULL -> complete(emptyList())
                    EMultiAlarmOprate.READ_SUCCESS_SAME_CRC -> Unit
                    else -> fail()
                }
            },
        )
    }

    private fun readTextAlarmList(
        onSuccess: (List<TextAlarm2Setting>) -> Unit,
        onFailure: () -> Unit,
    ) {
        val completed = AtomicBoolean(false)
        fun complete(items: List<TextAlarm2Setting>) {
            if (completed.compareAndSet(false, true)) onSuccess(items)
        }
        fun fail() {
            if (completed.compareAndSet(false, true)) onFailure()
        }
        // TextAlarmSp appends records instead of replacing the current device's
        // list. Remove only this watch's stale local entries so a full device
        // read cannot resurrect alarms deleted on the watch.
        connectedDeviceId.takeIf { it.isNotBlank() }?.let { address ->
            TextAlarmSp.getInstance(appContext).deleteAllAlarmMac(address)
        }
        manager.readTextAlarm(
            IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    fail()
                    return@IBleWriteResponse
                }
                connectionHandler.postDelayed(
                    { complete(manager.getTextAlarmList().orEmpty()) },
                    ALARM_CACHE_FALLBACK_MS,
                )
            },
            object : ITextAlarmDataListener {
                override fun onAlarmDataChangeListListener(data: TextAlarmData?) {
                    if (data == null) {
                        fail()
                        return
                    }
                    when (data.oprate) {
                        EMultiAlarmOprate.READ_SUCCESS,
                        EMultiAlarmOprate.READ_SUCCESS_SAVE,
                        EMultiAlarmOprate.READ_SUCCESS_SAME_CRC,
                        -> connectionHandler.postDelayed(
                            { complete(manager.getTextAlarmList().orEmpty()) },
                            ALARM_CACHE_SETTLE_MS,
                        )
                        EMultiAlarmOprate.READ_SUCCESS_NULL -> complete(emptyList())
                        else -> fail()
                    }
                }
            },
        )
    }

    private fun writeAlarm(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        when {
            preferences.isSupportTextAlarm -> writeTextAlarm(values, callback)
            preferences.isSupportMultiAlarm -> writeSceneAlarm(values, callback)
            else -> callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
        }
    }

    private fun writeSceneAlarm(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val operation = values?.get("operation")?.toString().orEmpty()
        val setting = Alarm2Setting().apply {
            alarmId = (values?.get("id") as? Number)?.toInt() ?: 0
            alarmHour = (values?.get("hour") as? Number)?.toInt()?.coerceIn(0, 23) ?: 8
            alarmMinute = (values?.get("minute") as? Number)?.toInt()?.coerceIn(0, 59) ?: 0
            isOpen = values?.get("enabled") != false
            val repeatDays =
                (values?.get("repeatDays") as? List<*>)
                    .orEmpty()
                    .mapNotNull { (it as? Number)?.toInt() }
                    .toSet()
            // The protocol stores Sunday at the left and Monday at the right.
            repeatStatus = (7 downTo 1).joinToString("") { if (repeatDays.contains(it)) "1" else "0" }
            unRepeatDate =
                if (repeatDays.isEmpty()) nextAlarmDate(alarmHour, alarmMinute)
                else "0000-00-00"
            scene = 0
        }
        val completed = AtomicBoolean(false)
        fun complete() {
            if (completed.compareAndSet(false, true)) callback.success(Unit)
        }
        fun fail(code: String, message: String) {
            if (completed.compareAndSet(false, true)) callback.error(code, message)
        }
        fun matches(item: Alarm2Setting): Boolean =
            item.alarmHour == setting.alarmHour &&
                item.alarmMinute == setting.alarmMinute &&
                item.isOpen == setting.isOpen &&
                item.repeatStatus.orEmpty() == setting.repeatStatus.orEmpty()
        fun verifyWrite() {
            if (completed.get()) return
            readSceneAlarmList(
                onSuccess = { items ->
                    val verified =
                        when (operation) {
                            "delete" -> items.none { it.alarmId == setting.alarmId }
                            "update" -> items.any { it.alarmId == setting.alarmId && matches(it) }
                            else -> items.any(::matches)
                        }
                    if (verified) complete()
                    else fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                },
                onFailure = { fail("WRITE_FAILED", "闹钟保存失败，请稍后重试") },
            )
        }
        val listener =
            IAlarm2DataListListener { data ->
                val success =
                    when (operation) {
                        "delete" -> data.oprate == EMultiAlarmOprate.CLEAR_SUCCESS
                        else -> data.oprate == EMultiAlarmOprate.SETTING_SUCCESS
                    }
                if (success) complete()
                else if (data.oprate == EMultiAlarmOprate.ALARM_FULL) {
                    fail("LIMIT_REACHED", "手表闹钟数量已满")
                } else {
                    fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                }
            }
        val response =
            IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                } else {
                    connectionHandler.postDelayed(::verifyWrite, ALARM_WRITE_VERIFY_DELAY_MS)
                }
            }
        when (operation) {
            "add" -> manager.addAlarm2(response, listener, setting)
            "update" -> manager.modifyAlarm2(response, listener, setting)
            "delete" -> manager.deleteAlarm2(response, listener, setting)
            else -> callback.error("INVALID_ARGUMENT", "请选择要执行的闹钟操作")
        }
    }

    private fun writeTextAlarm(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val operation = values?.get("operation")?.toString().orEmpty()
        val requestedId = (values?.get("id") as? Number)?.toInt() ?: 0
        val existing =
            if (requestedId > 0) manager.getTextAlarmList().orEmpty().firstOrNull { it.alarmId == requestedId }
            else null
        if ((operation == "update" || operation == "delete") && existing == null) {
            callback.error("ALARM_NOT_FOUND", "没有找到这个闹钟，请刷新后重试")
            return
        }
        // The SDK delete/modify contract expects the object returned by the
        // preceding read. Reusing it preserves BluetoothAddress and MAFlag.
        val setting = existing ?: TextAlarm2Setting()
        if (operation == "delete") {
            deleteTextAlarmWithCompatibility(setting, callback)
            return
        }
        if (operation != "delete") setting.apply {
            alarmId = requestedId
            alarmHour = (values?.get("hour") as? Number)?.toInt()?.coerceIn(0, 23) ?: 8
            alarmMinute = (values?.get("minute") as? Number)?.toInt()?.coerceIn(0, 59) ?: 0
            isOpen = values?.get("enabled") != false
            val repeatDays =
                (values?.get("repeatDays") as? List<*>)
                    .orEmpty()
                    .mapNotNull { (it as? Number)?.toInt() }
                    .toSet()
            repeatStatus = (7 downTo 1).joinToString("") { if (repeatDays.contains(it)) "1" else "0" }
            unRepeatDate =
                if (repeatDays.isEmpty()) nextAlarmDate(alarmHour, alarmMinute)
                else "0000-00-00"
            scene = 0
            content = values?.get("label")?.toString()?.trim().takeUnless { it.isNullOrEmpty() } ?: "闹钟"
        }
        val completed = AtomicBoolean(false)
        fun complete() {
            if (completed.compareAndSet(false, true)) callback.success(Unit)
        }
        fun fail(code: String, message: String) {
            if (completed.compareAndSet(false, true)) callback.error(code, message)
        }
        fun matches(item: TextAlarm2Setting): Boolean =
            item.alarmHour == setting.alarmHour &&
                item.alarmMinute == setting.alarmMinute &&
                item.isOpen == setting.isOpen &&
                item.repeatStatus.orEmpty() == setting.repeatStatus.orEmpty() &&
                item.content.orEmpty() == setting.content.orEmpty()
        fun verifyWrite() {
            if (completed.get()) return
            readTextAlarmList(
                onSuccess = { items ->
                    val verified =
                        when (operation) {
                            "update" -> items.any { it.alarmId == setting.alarmId && matches(it) }
                            else -> items.any(::matches)
                        }
                    if (verified) complete()
                    else fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                },
                onFailure = { fail("WRITE_FAILED", "闹钟保存失败，请稍后重试") },
            )
        }
        val listener =
            object : ITextAlarmDataListener {
                override fun onAlarmDataChangeListListener(data: TextAlarmData?) {
                    if (data == null) {
                        fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                        return
                    }
                    val success =
                        data.oprate == EMultiAlarmOprate.SETTING_SUCCESS
                    if (success) complete()
                    else if (data.oprate == EMultiAlarmOprate.ALARM_FULL) {
                        fail("LIMIT_REACHED", "手表闹钟数量已满")
                    } else {
                        fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                    }
                }
            }
        val response =
            IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    fail("WRITE_FAILED", "闹钟保存失败，请稍后重试")
                } else {
                    connectionHandler.postDelayed(::verifyWrite, ALARM_WRITE_VERIFY_DELAY_MS)
                }
            }
        when (operation) {
            "add" -> manager.addTextAlarm(response, listener, setting)
            "update" -> manager.modifyTextAlarm(response, listener, setting)
            else -> callback.error("INVALID_ARGUMENT", "请选择要执行的闹钟操作")
        }
    }

    private fun deleteTextAlarmWithCompatibility(
        initialSetting: TextAlarm2Setting,
        callback: ResultCallback<Unit>,
    ) {
        val completed = AtomicBoolean(false)
        val repairStarted = AtomicBoolean(false)

        fun complete() {
            if (completed.compareAndSet(false, true)) callback.success(Unit)
        }

        fun fail() {
            if (completed.compareAndSet(false, true)) {
                callback.error("WRITE_FAILED", "闹钟删除失败，请稍后重试")
            }
        }

        lateinit var sendDelete: (TextAlarm2Setting, Boolean) -> Unit

        fun repairAndRetry(target: TextAlarm2Setting) {
            if (completed.get() || !repairStarted.compareAndSet(false, true)) return
            // Some older alarms can be read but their original text cannot be
            // round-tripped by the firmware. Rewriting the same alarm once
            // makes the official delete command acceptable without changing
            // its time, repeat days or enabled state.
            target.content = if (safeAlarmLabel(target.content) == "闹钟") "提醒" else "闹钟"
            val verificationStarted = AtomicBoolean(false)

            fun verifyRepairAndRetry() {
                if (completed.get() || !verificationStarted.compareAndSet(false, true)) return
                readTextAlarmList(
                    onSuccess = { items ->
                        val latest = items.firstOrNull { it.alarmId == target.alarmId }
                        if (latest != null && latest.content == target.content) {
                            sendDelete(latest, false)
                        } else {
                            fail()
                        }
                    },
                    onFailure = ::fail,
                )
            }

            manager.modifyTextAlarm(
                IBleWriteResponse { code ->
                    if (code != Code.REQUEST_SUCCESS) {
                        fail()
                    } else {
                        connectionHandler.postDelayed(
                            ::verifyRepairAndRetry,
                            ALARM_WRITE_VERIFY_DELAY_MS,
                        )
                    }
                },
                object : ITextAlarmDataListener {
                    override fun onAlarmDataChangeListListener(data: TextAlarmData?) {
                        if (data?.oprate == EMultiAlarmOprate.SETTING_SUCCESS) {
                            connectionHandler.postDelayed(
                                ::verifyRepairAndRetry,
                                ALARM_CACHE_SETTLE_MS,
                            )
                        } else if (data?.oprate != null) {
                            fail()
                        }
                    }
                },
                target,
            )
        }

        sendDelete = deleteAttempt@{ target, allowRepair ->
            if (completed.get()) return@deleteAttempt
            val attemptFinished = AtomicBoolean(false)

            fun handleRejectedDelete() {
                if (!attemptFinished.compareAndSet(false, true) || completed.get()) return
                if (allowRepair) {
                    Log.w(LOG_TAG, "Text alarm delete rejected; rewriting id=${target.alarmId} before retry")
                    repairAndRetry(target)
                } else {
                    fail()
                }
            }

            fun verifyDelete() {
                if (attemptFinished.get() || completed.get()) return
                readTextAlarmList(
                    onSuccess = { items ->
                        if (!attemptFinished.compareAndSet(false, true) || completed.get()) {
                            return@readTextAlarmList
                        }
                        if (items.none { it.alarmId == target.alarmId }) {
                            complete()
                        } else if (allowRepair) {
                            Log.w(LOG_TAG, "Text alarm remained after delete; rewriting id=${target.alarmId}")
                            repairAndRetry(target)
                        } else {
                            fail()
                        }
                    },
                    onFailure = {
                        if (attemptFinished.compareAndSet(false, true)) fail()
                    },
                )
            }

            manager.deleteTextAlarm(
                IBleWriteResponse { code ->
                    if (code != Code.REQUEST_SUCCESS) {
                        handleRejectedDelete()
                    } else {
                        connectionHandler.postDelayed(
                            ::verifyDelete,
                            ALARM_WRITE_VERIFY_DELAY_MS,
                        )
                    }
                },
                object : ITextAlarmDataListener {
                    override fun onAlarmDataChangeListListener(data: TextAlarmData?) {
                        when (data?.oprate) {
                            EMultiAlarmOprate.CLEAR_SUCCESS -> {
                                if (attemptFinished.compareAndSet(false, true)) complete()
                            }
                            EMultiAlarmOprate.CLEAR_FAIL -> handleRejectedDelete()
                            null -> handleRejectedDelete()
                            else -> handleRejectedDelete()
                        }
                    }
                },
                target,
            )
        }

        sendDelete(initialSetting, true)
    }

    private fun alarmPayload(setting: Alarm2Setting): Map<String, Any?> =
        mapOf(
            "id" to setting.alarmId,
            "hour" to setting.alarmHour,
            "minute" to setting.alarmMinute,
            "enabled" to setting.isOpen,
            "label" to safeAlarmLabel((setting as? TextAlarm2Setting)?.content),
            "repeatDays" to
                setting.repeatStatus.orEmpty().mapIndexedNotNull { index, value ->
                    if (value == '1') 7 - index else null
                },
        )

    private fun safeAlarmLabel(value: String?): String {
        val text = value?.trim().orEmpty()
        if (text.isEmpty() || text.any { it == '\uFFFD' || Character.isISOControl(it) }) return "闹钟"
        return text.take(MAX_ALARM_LABEL_LENGTH)
    }

    private fun readContacts(callback: ResultCallback<Any?>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportContactFunction) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        manager.readContact(
            -1,
            object : IContactOptListener {
                override fun onContactOptSuccess(opt: EContactOpt, crc: Int) = Unit

                override fun onContactOptFailed(opt: EContactOpt) {
                    callback.error("READ_FAILED", "联系人读取失败，请稍后重试")
                }

                override fun onContactReadSuccess(contacts: List<Contact>) {
                    cachedContacts.clear()
                    cachedContacts.addAll(contacts)
                    callback.success(contactListPayload())
                }

                override fun onContactReadASSameCRC() {
                    callback.success(contactListPayload())
                }

                override fun onContactReadFailed() {
                    callback.error("READ_FAILED", "联系人读取失败，请稍后重试")
                }
            },
            writeResponse(callback, "联系人读取失败，请稍后重试"),
        )
    }

    private fun writeContact(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportContactFunction) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val operation = values?.get("operation")?.toString().orEmpty()
        val id = (values?.get("id") as? Number)?.toInt() ?: nextContactId()
        val contact =
            Contact(
                id,
                values?.get("name")?.toString()?.trim().orEmpty(),
                values?.get("phone")?.toString()?.trim().orEmpty(),
                values?.get("isEmergency") == true,
                values?.get("supportsEmergency") == true ||
                    VpSpGetUtil.getVpSpVariInstance(appContext).contactType == 2,
            )
        if (operation != "delete" && (contact.name.isBlank() || contact.phoneNumber.isBlank())) {
            callback.error("INVALID_ARGUMENT", "请填写联系人姓名和电话")
            return
        }
        val listener =
            object : IContactOptListener {
                override fun onContactOptSuccess(opt: EContactOpt, crc: Int) {
                    cachedContacts.removeAll { it.contactID == contact.contactID }
                    if (operation != "delete") cachedContacts.add(contact)
                    callback.success(Unit)
                }

                override fun onContactOptFailed(opt: EContactOpt) {
                    callback.error("WRITE_FAILED", "联系人保存失败，请稍后重试")
                }

                override fun onContactReadSuccess(contacts: List<Contact>) = Unit

                override fun onContactReadASSameCRC() = Unit

                override fun onContactReadFailed() = Unit
            }
        val response = writeResponse(callback, "联系人保存失败，请稍后重试")
        when (operation) {
            "add" -> manager.addContact(contact, listener, response)
            "delete" -> manager.deleteContact(contact, listener, response)
            "emergency" ->
                manager.setContactSOSState(contact.isSettingSOS, contact, listener, response)
            else -> callback.error("INVALID_ARGUMENT", "请选择要执行的联系人操作")
        }
    }

    private fun contactListPayload(): Map<String, Any?> =
        mapOf("items" to cachedContacts.sortedBy { it.contactID }.map(::contactPayload))

    private fun contactPayload(contact: Contact): Map<String, Any?> =
        mapOf(
            "id" to contact.contactID,
            "name" to contact.name,
            "phone" to contact.phoneNumber,
            "isEmergency" to contact.isSettingSOS,
            "supportsEmergency" to contact.isSupportSOS,
        )

    private fun nextContactId(): Int =
        (1..10).firstOrNull { candidate -> cachedContacts.none { it.contactID == candidate } } ?: 11

    private fun readHealthReminders(callback: ResultCallback<Any?>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        if (!preferences.isSupportHealthRemind && preferences.isSupportLongseat) {
            readLegacySedentaryReminder(callback)
            return
        }
        if (!preferences.isSupportHealthRemind) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        cachedHealthReminders.clear()
        manager.readHealthRemind(
            HealthRemindType.ALL,
            object : IHealthRemindListener {
                override fun functionNotSupport() {
                    callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
                }

                override fun onHealthRemindRead(reminder: HealthRemind) {
                    cachedHealthReminders[reminder.remindType] = reminder
                }

                override fun onHealthRemindReadingComplete() {
                    callback.success(healthReminderListPayload())
                }

                override fun onHealthRemindReadFailed() {
                    callback.error("READ_FAILED", "健康提醒读取失败，请稍后重试")
                }

                override fun onHealthRemindReport(reminder: HealthRemind) {
                    cachedHealthReminders[reminder.remindType] = reminder
                    emit("deviceFeatureChanged", mapOf("feature" to "health_reminders"))
                }

                override fun onHealthRemindReportFailed() = Unit

                override fun onHealthRemindSettingSuccess(reminder: HealthRemind) = Unit

                override fun onHealthRemindSettingFailed(type: HealthRemindType) = Unit
            },
            writeResponse(callback, "健康提醒读取失败，请稍后重试"),
        )
    }

    private fun writeHealthReminder(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        if (values?.get("id")?.toString() == LEGACY_SEDENTARY_ID &&
            !preferences.isSupportHealthRemind &&
            preferences.isSupportLongseat
        ) {
            writeLegacySedentaryReminder(values, callback)
            return
        }
        val type = healthRemindType(values?.get("id")?.toString())
        if (type == null) {
            callback.error("INVALID_ARGUMENT", "请选择健康提醒类型")
            return
        }
        val reminder =
            HealthRemind(
                type,
                minutesToTimeData((values?.get("startMinutes") as? Number)?.toInt() ?: 480),
                minutesToTimeData((values?.get("endMinutes") as? Number)?.toInt() ?: 1320),
                (values?.get("intervalMinutes") as? Number)?.toInt()?.coerceIn(15, 240) ?: 60,
                values?.get("enabled") == true,
            )
        manager.settingHealthRemind(
            reminder,
            object : IHealthRemindListener {
                override fun functionNotSupport() {
                    callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
                }

                override fun onHealthRemindRead(reminder: HealthRemind) = Unit

                override fun onHealthRemindReadingComplete() = Unit

                override fun onHealthRemindReadFailed() = Unit

                override fun onHealthRemindReport(reminder: HealthRemind) = Unit

                override fun onHealthRemindReportFailed() = Unit

                override fun onHealthRemindSettingSuccess(saved: HealthRemind) {
                    cachedHealthReminders[saved.remindType] = saved
                    callback.success(Unit)
                }

                override fun onHealthRemindSettingFailed(type: HealthRemindType) {
                    callback.error("WRITE_FAILED", "健康提醒保存失败，请稍后重试")
                }
            },
            writeResponse(callback, "健康提醒保存失败，请稍后重试"),
        )
    }

    private fun readLegacySedentaryReminder(callback: ResultCallback<Any?>) {
        manager.readLongSeat(
            writeResponse(callback, "久坐提醒读取失败，请稍后重试"),
            ILongSeatDataListener { data ->
                when (data.status?.name) {
                    "READ_SUCCESS" ->
                        callback.success(
                            mapOf(
                                "items" to
                                    listOf(
                                        mapOf(
                                            "id" to LEGACY_SEDENTARY_ID,
                                            "label" to "久坐提醒",
                                            "enabled" to data.isOpen,
                                            "startMinutes" to (data.startHour * 60 + data.startMinute),
                                            "endMinutes" to (data.endHour * 60 + data.endMinute),
                                            "intervalMinutes" to data.threshold,
                                        ),
                                    ),
                            ),
                        )
                    "UNSUPPORT" -> callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
                    else -> callback.error("READ_FAILED", "久坐提醒读取失败，请稍后重试")
                }
            },
        )
    }

    private fun writeLegacySedentaryReminder(
        values: Map<*, *>?,
        callback: ResultCallback<Unit>,
    ) {
        val start = (values?.get("startMinutes") as? Number)?.toInt() ?: 480
        val end = (values?.get("endMinutes") as? Number)?.toInt() ?: 1320
        val expectedOpen = values?.get("enabled") == true
        val setting =
            LongSeatSetting(
                ((start % 1440) + 1440) % 1440 / 60,
                ((start % 60) + 60) % 60,
                ((end % 1440) + 1440) % 1440 / 60,
                ((end % 60) + 60) % 60,
                (values?.get("intervalMinutes") as? Number)?.toInt()?.coerceIn(10, 120) ?: 60,
                expectedOpen,
            )
        manager.settingLongSeat(
            writeResponse(callback, "久坐提醒保存失败，请稍后重试"),
            setting,
            ILongSeatDataListener { data ->
                val success =
                    data.status?.name == if (expectedOpen) "OPEN_SUCCESS" else "CLOSE_SUCCESS"
                if (success) callback.success(Unit)
                else if (data.status?.name == "UNSUPPORT") {
                    callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
                } else {
                    callback.error("WRITE_FAILED", "久坐提醒保存失败，请稍后重试")
                }
            },
        )
    }

    private fun healthReminderListPayload(): Map<String, Any?> =
        mapOf("items" to cachedHealthReminders.values.map(::healthReminderPayload))

    private fun healthReminderPayload(reminder: HealthRemind): Map<String, Any?> =
        mapOf(
            "id" to reminder.remindType.name.lowercase(Locale.ROOT),
            "label" to healthRemindLabel(reminder.remindType),
            "enabled" to reminder.status,
            "startMinutes" to (reminder.startTime.hour * 60 + reminder.startTime.minute),
            "endMinutes" to (reminder.endTime.hour * 60 + reminder.endTime.minute),
            "intervalMinutes" to reminder.interval,
        )

    private fun healthRemindType(value: String?): HealthRemindType? =
        HealthRemindType.values().firstOrNull {
            it != HealthRemindType.ALL && it.name.equals(value, ignoreCase = true)
        }

    private fun healthRemindLabel(type: HealthRemindType): String =
        when (type) {
            HealthRemindType.SEDENTARY -> "久坐提醒"
            HealthRemindType.DRINK_WATER -> "喝水提醒"
            HealthRemindType.OVERLOOK -> "远眺提醒"
            HealthRemindType.SPORTS -> "运动提醒"
            HealthRemindType.TAKE_MEDICINE -> "服药提醒"
            HealthRemindType.READING -> "阅读提醒"
            HealthRemindType.GOING_OUT -> "外出提醒"
            HealthRemindType.WASH -> "洗手提醒"
            else -> "健康提醒"
        }

    private fun readWorldClocks(callback: ResultCallback<Any?>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportWorldClock) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        manager.readWorldClock(
            -1,
            BleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    callback.error("READ_FAILED", "世界时钟读取失败，请稍后重试")
                }
            },
            object : IWorldClockOptListener {
                override fun onWorldClockReadSuccess(clocks: List<WorldClock>, crc: Int) {
                    cachedWorldClocks.clear()
                    cachedWorldClocks.addAll(clocks)
                    callback.success(worldClockListPayload())
                }

                override fun onWorldClockOptSuccess(
                    opt: IWorldClockOptListener.WorldClockOpt,
                    crc: Int,
                ) = Unit

                override fun onWorldClockOptFailed(opt: IWorldClockOptListener.WorldClockOpt) {
                    callback.error("READ_FAILED", "世界时钟读取失败，请稍后重试")
                }
            },
        )
    }

    private fun writeWorldClock(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportWorldClock) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val operation = values?.get("operation")?.toString().orEmpty()
        val id = (values?.get("id") as? Number)?.toInt() ?: nextWorldClockId()
        val city = values?.get("city")?.toString()?.trim().orEmpty()
        val offsetMinutes = (values?.get("utcOffsetMinutes") as? Number)?.toInt() ?: 0
        val clock = WorldClock(id, (offsetMinutes / 15.0).toInt(), city, city).apply {
            isOpen = values?.get("enabled") != false
        }
        if (operation != "delete" && city.isBlank()) {
            callback.error("INVALID_ARGUMENT", "请选择城市")
            return
        }
        val listener =
            object : IWorldClockOptListener {
                override fun onWorldClockReadSuccess(clocks: List<WorldClock>, crc: Int) = Unit

                override fun onWorldClockOptSuccess(
                    opt: IWorldClockOptListener.WorldClockOpt,
                    crc: Int,
                ) {
                    cachedWorldClocks.removeAll { it.id == clock.id }
                    if (operation != "delete") cachedWorldClocks.add(clock)
                    callback.success(Unit)
                }

                override fun onWorldClockOptFailed(opt: IWorldClockOptListener.WorldClockOpt) {
                    callback.error("WRITE_FAILED", "世界时钟保存失败，请稍后重试")
                }
            }
        val response =
            BleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    callback.error("WRITE_FAILED", "世界时钟保存失败，请稍后重试")
                }
            }
        when (operation) {
            "add" -> manager.addWorldClock(clock, response, listener)
            "delete" -> manager.deleteWorldClock(clock, response, listener)
            else -> callback.error("INVALID_ARGUMENT", "请选择要执行的世界时钟操作")
        }
    }

    private fun worldClockListPayload(): Map<String, Any?> =
        mapOf("items" to cachedWorldClocks.sortedBy { it.id }.map(::worldClockPayload))

    private fun worldClockPayload(clock: WorldClock): Map<String, Any?> =
        mapOf(
            "id" to clock.id,
            "city" to clock.timeZoneName,
            "utcOffsetMinutes" to clock.timeZone * 15,
            "enabled" to clock.isOpen,
        )

    private fun nextWorldClockId(): Int =
        (1..10).firstOrNull { candidate -> cachedWorldClocks.none { it.id == candidate } } ?: 11

    private fun readWeather(callback: ResultCallback<Any?>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportWeather) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        manager.readWeatherStatusInfo(
            writeResponse(callback, "天气设置读取失败，请稍后重试"),
            IWeatherStatusDataListener { data ->
                if (data.oprate != EWeatherOprateStatus.READ_SUCCESS) {
                    callback.error("READ_FAILED", "天气设置读取失败，请稍后重试")
                    return@IWeatherStatusDataListener
                }
                weatherCrc = data.crc
                callback.success(
                    mapOf(
                        "enabled" to data.isOpen,
                        "useCelsius" to (data.weatherType == EWeatherType.C),
                        "city" to lastWeatherCity,
                        "updatedAt" to lastWeatherUpdatedAt,
                    ),
                )
            },
        )
    }

    private fun writeWeather(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportWeather) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        if (values?.get("operation")?.toString() == "sync") {
            writeWeatherContent(values, callback)
            return
        }
        writeWeatherStatus(values, callback)
    }

    private fun writeWeatherStatus(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val setting =
            WeatherStatusSetting(
                weatherCrc,
                values?.get("enabled") == true,
                if (values?.get("useCelsius") != false) EWeatherType.C else EWeatherType.F,
            )
        manager.settingWeatherStatusInfo(
            writeResponse(callback, "天气设置保存失败，请稍后重试"),
            setting,
            IWeatherStatusDataListener { data ->
                if (data.oprate == EWeatherOprateStatus.SETTING_STATUS_SUCCESS) {
                    weatherCrc = data.crc
                    callback.success(Unit)
                } else {
                    callback.error("WRITE_FAILED", "天气设置保存失败，请稍后重试")
                }
            },
        )
    }

    private fun writeWeatherContent(values: Map<*, *>?, callback: ResultCallback<Unit>) {
        val city = values?.get("city")?.toString()?.trim().orEmpty()
        val updatedAt = (values?.get("updatedAt") as? Number)?.toLong() ?: System.currentTimeMillis()
        val hourlyMaps = mapList(values?.get("hourly"))
        val dailyMaps = mapList(values?.get("daily"))
        if (city.isBlank() || hourlyMaps.isEmpty() || dailyMaps.isEmpty()) {
            callback.error("INVALID_ARGUMENT", "暂时没有可同步的天气数据")
            return
        }
        val crc = ((updatedAt xor city.hashCode().toLong()) and 0xffff).toInt()
        val hourly =
            hourlyMaps.map { item ->
                val temperatureC = (item["temperatureC"] as? Number)?.toInt() ?: 0
                WeatherEvery3Hour(
                    timeDataFromMillis((item["time"] as? Number)?.toLong() ?: updatedAt),
                    celsiusToFahrenheit(temperatureC),
                    temperatureC,
                    (item["uvIndex"] as? Number)?.toInt()?.coerceIn(0, 15) ?: 0,
                    (item["weatherCode"] as? Number)?.toInt()?.coerceIn(0, 155) ?: 120,
                    item["windLevel"]?.toString().orEmpty().ifBlank { "0" },
                    ((item["visibilityMeters"] as? Number)?.toDouble() ?: 5000.0) / 1000.0,
                )
            }
        val daily =
            dailyMaps.map { item ->
                val maximumC = (item["maximumC"] as? Number)?.toInt() ?: 0
                val minimumC = (item["minimumC"] as? Number)?.toInt() ?: 0
                WeatherEveryDay(
                    timeDataFromMillis((item["time"] as? Number)?.toLong() ?: updatedAt),
                    celsiusToFahrenheit(maximumC),
                    celsiusToFahrenheit(minimumC),
                    maximumC,
                    minimumC,
                    (item["uvIndex"] as? Number)?.toInt()?.coerceIn(0, 15) ?: 0,
                    (item["dayWeatherCode"] as? Number)?.toInt()?.coerceIn(0, 155) ?: 120,
                    (item["nightWeatherCode"] as? Number)?.toInt()?.coerceIn(0, 155) ?: 120,
                    item["windLevel"]?.toString().orEmpty().ifBlank { "0" },
                    ((item["visibilityMeters"] as? Number)?.toDouble() ?: 5000.0) / 1000.0,
                )
            }
        val weatherData =
            WeatherData(
                crc,
                city,
                0,
                timeDataFromMillis(updatedAt),
                hourly,
                daily,
            )
        manager.settingWeatherData(
            IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    callback.error("WRITE_FAILED", "天气同步失败，请稍后重试")
                }
            },
            weatherData,
            IWeatherStatusDataListener { data ->
                if (data.oprate != EWeatherOprateStatus.SETTING_CONTENT_SUCCESS) {
                    callback.error("WRITE_FAILED", "天气同步失败，请稍后重试")
                    return@IWeatherStatusDataListener
                }
                weatherCrc = data.crc
                lastWeatherCity = city
                lastWeatherUpdatedAt = updatedAt
                writeWeatherStatus(values, callback)
            },
        )
    }

    private fun mapList(value: Any?): List<Map<*, *>> =
        (value as? List<*>)?.mapNotNull { it as? Map<*, *> }.orEmpty()

    private fun timeDataFromMillis(value: Long): TimeData {
        val calendar = Calendar.getInstance().apply { timeInMillis = value }
        return TimeData(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH) + 1,
            calendar.get(Calendar.DAY_OF_MONTH),
            calendar.get(Calendar.HOUR_OF_DAY),
            calendar.get(Calendar.MINUTE),
            calendar.get(Calendar.SECOND),
        )
    }

    private fun celsiusToFahrenheit(value: Int): Int =
        kotlin.math.round(value * 9.0 / 5.0 + 32.0).toInt()

    private fun minutesToTimeData(value: Int): TimeData {
        val normalized = ((value % 1440) + 1440) % 1440
        return TimeData(normalized / 60, normalized % 60)
    }

    private fun nextAlarmDate(hour: Int, minute: Int): String {
        val alarm = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(alarm.time)
    }

    fun triggerDeviceAction(
        feature: String,
        enabled: Boolean,
        callback: ResultCallback<Unit>,
    ) {
        ensureConnected(callback) ?: return
        if (feature == "camera") {
            triggerCamera(enabled, callback)
            return
        }
        if (feature == "notifications") {
            runCatching {
                val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                appContext.startActivity(intent)
            }.onSuccess {
                callback.success(Unit)
            }.onFailure {
                callback.error("SETTINGS_UNAVAILABLE", "无法打开系统设置，请稍后重试")
            }
            return
        }
        if (feature != "find_watch") {
            callback.error("FEATURE_UNAVAILABLE", "此功能暂时无法使用，请稍后再试")
            return
        }
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportFindDeviceByPhone) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val listener =
            object : IFindDevicelistener {
                override fun unSupportFindDeviceByPhone() {
                    callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
                }

                override fun findedDevice() {
                    callback.success(Unit)
                }

                override fun unFindDevice() {
                    callback.success(Unit)
                }

                override fun findingDevice() {
                    callback.success(Unit)
                }
            }
        val writeResponse =
            IBleWriteResponse { code ->
                if (code != Code.REQUEST_SUCCESS) {
                    callback.error("WRITE_FAILED", "暂时无法查找手表，请稍后重试")
                }
            }
        if (enabled) {
            manager.startFindDeviceByPhone(writeResponse, listener)
        } else {
            manager.stopFindDeviceByPhone(writeResponse, listener)
        }
    }

    private fun triggerCamera(enabled: Boolean, callback: ResultCallback<Unit>) {
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportCamera) {
            callback.error("FEATURE_UNSUPPORTED", "当前手表不支持此功能")
            return
        }
        val listener =
            object : ICameraDataListener {
                override fun OnCameraDataChange(status: ECameraStatus) {
                    when (status) {
                        ECameraStatus.TAKEPHOTO_CAN ->
                            emit("cameraShutter", mapOf("deviceId" to connectedDeviceId))
                        ECameraStatus.OPEN_SUCCESS,
                        ECameraStatus.DEVICE_OPEN_SUCCESS,
                        ECameraStatus.CLOSE_SUCCESS,
                        -> callback.success(Unit)
                        ECameraStatus.OPEN_FALI,
                        ECameraStatus.CLOSE_FAIL,
                        ECameraStatus.TAKEPHOTO_CAN_NOT,
                        -> callback.error("CAMERA_FAILED", "相机遥控暂时无法使用，请稍后重试")
                        else -> Unit
                    }
                }
            }
        manager.setCameraListener(listener)
        val response = writeResponse(callback, "相机遥控暂时无法使用，请稍后重试")
        if (enabled) manager.startCamera(response, listener)
        else manager.stopCamera(response, listener)
    }

    fun startSport(mode: String, callback: ResultCallback<Unit>) {
        ensureConnected(callback) ?: return
        val sportType =
            when (mode) {
                "walking" -> ESportType.OUTDOOR_WALK
                "cycling" -> ESportType.OUTDOOR_RIDING
                "hiking" -> ESportType.HIKE
                else -> ESportType.OUTDOOR_RUNNING
            }
        manager.startMultSportModel(
            writeResponse(callback, "运动模式暂时无法开启"),
            object : ISportModelStateListener {
                override fun onSportModelStateChange(data: SportModelStateData) {
                    emit(
                        "sportState",
                        mapOf(
                            "value" to "running",
                            "mode" to mode,
                            "deviceStatus" to (data.getDeviceStauts()?.name ?: "unknown"),
                        ),
                    )
                    callback.success(Unit)
                }

                override fun onSportStopped() {
                    emit("sportState", mapOf("value" to "stopped", "mode" to mode))
                }
            },
            sportType,
        )
    }

    private fun isSystemBluetoothEnabled(): Boolean =
        try {
            val bluetoothManager =
                appContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            bluetoothManager?.adapter?.isEnabled == true
        } catch (_: SecurityException) {
            false
        }

    fun stopSport(callback: ResultCallback<Unit>) {
        ensureConnected(callback) ?: return
        manager.stopSportModel(
            writeResponse(callback, "运动模式暂时无法结束"),
            object : ISportModelStateListener {
                override fun onSportModelStateChange(data: SportModelStateData) {
                    emit("sportState", mapOf("value" to "stopped"))
                    callback.success(Unit)
                }

                override fun onSportStopped() {
                    emit("sportState", mapOf("value" to "stopped"))
                    callback.success(Unit)
                }
            },
        )
    }

    fun readSportRecords(callback: ResultCallback<List<Map<String, Any?>>>) {
        ensureConnected(callback) ?: return
        val records = mutableListOf<Map<String, Any?>>()
        manager.readSportModelOrigin(
            writeResponse(callback, "运动记录暂时无法读取"),
            object : ISportModelOriginListener {
                override fun onReadOriginProgress(progress: Float) {
                    emit("sportSyncProgress", mapOf("progress" to progress.toDouble()))
                }

                override fun onReadOriginProgressDetail(
                    crc: Int,
                    date: String,
                    progress: Int,
                    total: Int,
                ) {
                    emit(
                        "sportSyncProgress",
                        mapOf("crc" to crc, "date" to date, "progress" to progress, "total" to total),
                    )
                }

                override fun onHeadChangeListListener(data: SportModelOriginHeadData) {
                    records += sportRecord(data)
                }

                override fun onGPSWatchSportModeHeadChange(data: SportModelGPSWatchOriginHeadData) {
                    records += sportRecord(data)
                }

                override fun onItemChangeListListener(items: MutableList<SportModelOriginItemData>) = Unit

                override fun onReadOriginComplete() {
                    callback.success(records.distinctBy { it["id"] })
                }
            },
        )
    }

    private fun sportRecord(data: SportModelOriginHeadData): Map<String, Any?> {
        val startedAt = data.getStartTime()?.toFullDateTimeString().orEmpty()
        return mapOf(
            "id" to "${data.getSportType()}-$startedAt-${data.getCrc()}",
            "mode" to sportModeName(data.getSportType()),
            "startedAt" to startedAt,
            "durationSeconds" to data.getSportTime(),
            "distanceKm" to data.getDistance(),
            "calories" to data.getKcals(),
        )
    }

    private fun sportRecord(data: SportModelGPSWatchOriginHeadData): Map<String, Any?> {
        val startedAt = data.getStartTime()?.toFullDateTimeString().orEmpty()
        return mapOf(
            "id" to "${data.getSportType()}-$startedAt-${data.getCrc()}",
            "mode" to sportModeName(data.getSportType()),
            "startedAt" to startedAt,
            "durationSeconds" to data.getSportTime(),
            "distanceKm" to data.getDistance(),
            "calories" to data.getCalories(),
        )
    }

    private fun sportModeName(type: Int): String =
        when (type) {
            2, 4 -> "walking"
            7, 8 -> "cycling"
            5, 11 -> "hiking"
            else -> "running"
        }

    fun readAutoMeasureSettings(callback: ResultCallback<Map<String, Boolean>>) {
        ensureConnected(callback) ?: return
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        if (!preferences.isSupportAutoMeasure) {
            autoMeasureSettings.clear()
            callback.success(emptyMap())
            return
        }
        val guardedCallback =
            withOperationTimeout(
                callback,
                "AUTO_MEASURE_READ_TIMEOUT",
                "暂时未读取到自动检测设置，请稍后重试",
            )
        manager.readAutoMeasureSettingData(
            writeResponse(guardedCallback, "自动检测设置暂时无法读取"),
            object : IAutoMeasureSettingDataListener {
                override fun onSettingDataChange(items: MutableList<AutoMeasureData>) {
                    autoMeasureSettings.clear()
                    items.forEach { item ->
                        autoMeasureName(item.funType)?.let { name ->
                            autoMeasureSettings[name] = item
                        }
                    }
                    guardedCallback.success(
                        autoMeasureSettings.mapValues { (_, item) -> item.isSwitchOpen },
                    )
                }

                override fun onSettingDataChangeFail() {
                    guardedCallback.error("AUTO_MEASURE_READ_FAILED", "手表不支持或无法读取自动检测设置")
                }

                override fun onSettingDataChangeSuccess() = Unit
            },
        )
    }

    fun setAutoMeasureSetting(
        type: String,
        enabled: Boolean,
        callback: ResultCallback<Unit>,
    ) {
        ensureConnected(callback) ?: return
        val setting = autoMeasureSettings[type]
        if (setting == null) {
            callback.error("AUTO_MEASURE_UNSUPPORTED", "当前手表不支持该自动检测功能，请先刷新设置")
            return
        }
        setting.isSwitchOpen = enabled
        manager.setAutoMeasureSettingData(
            writeResponse(callback, "自动检测设置保存失败"),
            setting,
            object : IAutoMeasureSettingDataListener {
                override fun onSettingDataChange(items: MutableList<AutoMeasureData>) = Unit

                override fun onSettingDataChangeFail() {
                    callback.error("AUTO_MEASURE_WRITE_FAILED", "自动检测设置写入失败")
                }

                override fun onSettingDataChangeSuccess() {
                    callback.success(Unit)
                }
            },
        )
    }

    fun readHeartRateWarning(callback: ResultCallback<Int?>) {
        ensureConnected(callback) ?: return
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        if (!preferences.isSupportHeartwaring) {
            callback.success(null)
            return
        }
        val guardedCallback =
            withOperationTimeout(
                callback,
                "HEART_WARNING_READ_TIMEOUT",
                "暂时未读取到心率预警设置，请稍后重试",
            )
        manager.readHealthAlarmInterval(
            EHealthAlarmType.HEART_RATE_ALARM,
            writeResponse(guardedCallback, "心率预警暂时无法读取"),
            object : IHealthAlarmIntervalListener {
                override fun functionNotSupport() {
                    guardedCallback.success(null)
                }

                override fun onHealthAlarmIntervalReadSuccess(
                    data: HealthAlarmInterval,
                    support: Boolean,
                ) {
                    if (support) guardedCallback.success(data.ceilingValue.toInt())
                    else guardedCallback.success(null)
                }

                override fun onHealthAlarmIntervalSetting(
                    data: HealthAlarmInterval,
                    success: Boolean,
                ) = Unit
            },
        )
    }

    fun setHeartRateWarning(value: Int, callback: ResultCallback<Unit>) {
        ensureConnected(callback) ?: return
        if (!VpSpGetUtil.getVpSpVariInstance(appContext).isSupportHeartwaring) {
            callback.error("HEART_WARNING_UNSUPPORTED", "当前手表不支持心率过高预警")
            return
        }
        val setting = HealthAlarmInterval(
            EHealthAlarmType.HEART_RATE_ALARM,
            value.coerceIn(70, 190).toFloat(),
            0f,
            true,
        )
        manager.setHealthAlarmInterval(
            setting,
            writeResponse(callback, "心率预警保存失败"),
            object : IHealthAlarmIntervalListener {
                override fun functionNotSupport() {
                    callback.error("HEART_WARNING_UNSUPPORTED", "当前手表不支持心率过高预警")
                }

                override fun onHealthAlarmIntervalReadSuccess(
                    data: HealthAlarmInterval,
                    support: Boolean,
                ) = Unit

                override fun onHealthAlarmIntervalSetting(
                    data: HealthAlarmInterval,
                    success: Boolean,
                ) {
                    if (success) callback.success(Unit)
                    else callback.error("HEART_WARNING_WRITE_FAILED", "心率预警设置失败")
                }
            },
        )
    }

    private fun autoMeasureName(type: EAutoMeasureType?): String? =
        when (type) {
            EAutoMeasureType.PULSE_RATE -> "heartRate"
            EAutoMeasureType.BLOOD_PRESSURE -> "bloodPressure"
            EAutoMeasureType.BLOOD_GLUCOSE -> "bloodGlucose"
            EAutoMeasureType.BODY_TEMPERATURE -> "bodyTemperature"
            else -> null
        }

    fun syncHealthData(cursor: String?, callback: ResultCallback<List<Map<String, Any?>>>) {
        ensureConnected(callback) ?: return
        cancelActiveHealthSync(
            "HEALTH_SYNC_SUPERSEDED",
            "历史数据同步已由新的同步任务替代",
            emitError = false,
        )
        val deviceId = connectedDeviceId
        val generation =
            synchronized(this) {
                healthSyncGeneration += 1
                activeHealthSyncCallback = callback
                activeHealthSyncDeviceId = deviceId
                healthSyncGeneration
            }
        val records = mutableListOf<Map<String, Any?>>()
        emitHealthSyncProgress(deviceId, cursor, 0.0)
        armHealthSyncTimeout(generation, callback, deviceId, "睡眠数据")
        manager.readSleepData(
            healthReadWriteResponse(generation, callback, deviceId, "睡眠数据"),
            object : ISleepDataListener {
                override fun onSleepDataChange(day: String, sleep: SleepData) {
                    connectionHandler.post {
                        if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                        if (sleep.allSleepTime > 0) {
                            records +=
                                record(
                                    "sleep",
                                    mapOf("value" to sleep.allSleepTime / 60.0),
                                    "h",
                                    sleepRecordDate(day, sleep),
                                )
                        }
                        armHealthSyncTimeout(generation, callback, deviceId, "睡眠数据")
                    }
                }

                override fun onSleepProgress(progress: Float) {
                    connectionHandler.post {
                        if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                        emitHealthSyncProgress(deviceId, cursor, progress.coerceIn(0f, 1f) * 0.1)
                        armHealthSyncTimeout(generation, callback, deviceId, "睡眠数据")
                    }
                }

                override fun onSleepProgressDetail(day: String, currentPackage: Int) {
                    connectionHandler.post {
                        if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                        armHealthSyncTimeout(generation, callback, deviceId, "睡眠数据")
                    }
                }

                override fun onReadSleepComplete() {
                    connectionHandler.post {
                        if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                        emitHealthSyncProgress(deviceId, cursor, 0.1)
                        readOriginHealthData(
                            generation,
                            callback,
                            deviceId,
                            cursor,
                            records,
                        )
                    }
                }
            },
            watchDataDays,
        )
    }

    private fun readOriginHealthData(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        cursor: String?,
        records: MutableList<Map<String, Any?>>,
    ) {
        if (!isHealthSyncActive(generation, callback, deviceId)) return
        val originProtocolVersion =
            runCatching {
                VpSpGetUtil.getVpSpVariInstance(appContext).originProtocolVersion
            }.getOrDefault(0)
        val usesOriginData3 = originProtocolVersion == 3 || originProtocolVersion == 5
        Log.i(
            LOG_TAG,
            "readOriginHealthData device=$deviceId protocol=$originProtocolVersion listener=${if (usesOriginData3) "v3" else "legacy"}",
        )
        armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
        val writeResponse =
            healthReadWriteResponse(generation, callback, deviceId, "日常健康数据")
        if (usesOriginData3) {
            manager.readOriginData(
                writeResponse,
                object : IOriginData3Listener {
                    override fun onOriginFiveMinuteListDataChange(items: MutableList<OriginData3>) {
                        connectionHandler.post {
                            if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                            items.forEach { appendOriginData3(it, records) }
                            armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
                        }
                    }

                    override fun onOriginHalfHourDataChange(origin: OriginHalfHourData) {
                        connectionHandler.post {
                            if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                            appendHalfHourData(origin, records)
                            armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
                        }
                    }

                    override fun onOriginHRVOriginListDataChange(items: MutableList<HRVOriginData>) = Unit

                    override fun onOriginSpo2OriginListDataChange(items: MutableList<Spo2hOriginData>) = Unit

                    override fun onReadOriginProgressDetail(
                        day: Int,
                        date: String,
                        allPackage: Int,
                        currentPackage: Int,
                    ) {
                        touchOriginHealthSync(generation, callback, deviceId)
                    }

                    override fun onReadOriginProgress(progress: Float) {
                        updateOriginHealthProgress(generation, callback, deviceId, cursor, progress)
                    }

                    override fun onReadOriginComplete() {
                        completeOriginHealthSync(generation, callback, deviceId, cursor, records)
                    }

                    override fun onReadTimeout(type: Int) {
                        timeoutOriginHealthSync(generation, callback, deviceId, type)
                    }
                },
                watchDataDays,
            )
        } else {
            manager.readOriginData(
                writeResponse,
                object : IOriginDataListener {
                    override fun onOringinFiveMinuteDataChange(origin: OriginData) {
                        connectionHandler.post {
                            if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                            appendOriginData(origin, records)
                            armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
                        }
                    }

                    override fun onOringinHalfHourDataChange(origin: OriginHalfHourData) {
                        connectionHandler.post {
                            if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                            appendHalfHourData(origin, records)
                            armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
                        }
                    }

                    override fun onReadOriginProgressDetail(
                        day: Int,
                        date: String,
                        allPackage: Int,
                        currentPackage: Int,
                    ) {
                        touchOriginHealthSync(generation, callback, deviceId)
                    }

                    override fun onReadOriginProgress(progress: Float) {
                        updateOriginHealthProgress(generation, callback, deviceId, cursor, progress)
                    }

                    override fun onReadOriginComplete() {
                        completeOriginHealthSync(generation, callback, deviceId, cursor, records)
                    }

                    override fun onReadTimeout(type: Int) {
                        timeoutOriginHealthSync(generation, callback, deviceId, type)
                    }
                },
                watchDataDays,
            )
        }
    }

    private fun appendOriginData(
        origin: OriginData,
        records: MutableList<Map<String, Any?>>,
        includeHeartRate: Boolean = true,
    ) {
        val at = origin.getmTime()?.toCalendar()?.time ?: parseOriginTime(origin.date, origin.getmTime()?.clock)
        if (includeHeartRate && origin.rateValue > 0) {
            records += record("heart_rate", mapOf("value" to origin.rateValue), "bpm", at)
        }
        if (origin.highValue > 0 && origin.lowValue > 0) {
            records +=
                record(
                    "blood_pressure",
                    mapOf("systolic" to origin.highValue, "diastolic" to origin.lowValue),
                    "mmHg",
                    at,
                )
        }
        if (origin.temperature > 0) {
            records += record("body_temperature", mapOf("value" to origin.temperature), "℃", at)
        }
    }

    private fun appendOriginData3(
        origin: OriginData3,
        records: MutableList<Map<String, Any?>>,
    ) {
        appendOriginData(origin, records, includeHeartRate = false)
        val at = origin.getmTime()?.toCalendar()?.time ?: parseOriginTime(origin.date, origin.getmTime()?.clock)
        val pulseSamples = origin.ppgs?.filter { it in 30..240 }.orEmpty()
        if (pulseSamples.isNotEmpty()) {
            records +=
                record(
                    "heart_rate",
                    mapOf("value" to pulseSamples.average()),
                    "bpm",
                    at,
                )
        }
        val oxygenSamples = origin.oxygens?.filter { it in 50..100 }.orEmpty()
        if (oxygenSamples.isNotEmpty()) {
            records +=
                record(
                    "blood_oxygen",
                    mapOf("value" to oxygenSamples.average()),
                    "%",
                    at,
                )
        }
    }

    private fun appendHalfHourData(
        origin: OriginHalfHourData,
        records: MutableList<Map<String, Any?>>,
    ) {
        origin.halfHourSportDatas.orEmpty().forEach { sport ->
            val at = sport.time?.toCalendar()?.time ?: parseOriginTime(sport.date, sport.time?.clock)
            if (sport.stepValue > 0) records += record("steps", mapOf("value" to sport.stepValue), "步", at)
            if (sport.disValue > 0) records += record("distance", mapOf("value" to sport.disValue), "km", at)
            if (sport.calValue > 0) records += record("calories", mapOf("value" to sport.calValue), "kcal", at)
        }
    }

    private fun touchOriginHealthSync(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
    ) {
        connectionHandler.post {
            if (!isHealthSyncActive(generation, callback, deviceId)) return@post
            armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
        }
    }

    private fun updateOriginHealthProgress(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        cursor: String?,
        progress: Float,
    ) {
        connectionHandler.post {
            if (!isHealthSyncActive(generation, callback, deviceId)) return@post
            emitHealthSyncProgress(
                deviceId,
                cursor,
                0.1 + progress.coerceIn(0f, 1f) * 0.9,
            )
            armHealthSyncTimeout(generation, callback, deviceId, "日常健康数据")
        }
    }

    private fun completeOriginHealthSync(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        cursor: String?,
        records: MutableList<Map<String, Any?>>,
    ) {
        connectionHandler.post {
            if (!finishHealthSync(generation, callback, deviceId)) return@post
            emitHealthSyncProgress(deviceId, cursor, 1.0)
            callback.success(records.distinctBy { it["id"] })
        }
    }

    private fun timeoutOriginHealthSync(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        type: Int,
    ) {
        connectionHandler.post {
            failHealthSync(
                generation,
                callback,
                deviceId,
                "HEALTH_READ_TIMEOUT",
                "设备日常健康数据读取超时（类型 $type）",
            )
        }
    }

    private fun healthReadWriteResponse(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        stage: String,
    ) =
        IBleWriteResponse { code ->
            connectionHandler.post {
                if (!isHealthSyncActive(generation, callback, deviceId)) return@post
                if (code == Code.REQUEST_SUCCESS) {
                    armHealthSyncTimeout(generation, callback, deviceId, stage)
                } else {
                    failHealthSync(
                        generation,
                        callback,
                        deviceId,
                        "HEALTH_READ_WRITE_FAILED",
                        "${stage}读取失败，请保持手表靠近手机后重试",
                    )
                }
            }
        }

    private fun emitHealthSyncProgress(deviceId: String, cursor: String?, progress: Double) {
        emit(
            "syncProgress",
            mapOf(
                "deviceId" to deviceId,
                "progress" to progress.coerceIn(0.0, 1.0),
                "cursor" to cursor,
            ),
        )
    }

    private fun isHealthSyncActive(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
    ): Boolean =
        synchronized(this) {
            healthSyncGeneration == generation &&
                activeHealthSyncCallback === callback &&
                activeHealthSyncDeviceId.equals(deviceId, ignoreCase = true) &&
                connectedDeviceId.equals(deviceId, ignoreCase = true)
        }

    private fun armHealthSyncTimeout(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        stage: String,
    ) {
        if (!isHealthSyncActive(generation, callback, deviceId)) return
        healthSyncTimeoutTask?.let(connectionHandler::removeCallbacks)
        val timeout =
            Runnable {
                Log.w(LOG_TAG, "health sync idle timeout device=$deviceId stage=$stage")
                failHealthSync(
                    generation,
                    callback,
                    deviceId,
                    "HEALTH_READ_TIMEOUT",
                    "设备${stage}读取超时",
                )
            }
        healthSyncTimeoutTask = timeout
        connectionHandler.postDelayed(timeout, HEALTH_SYNC_IDLE_TIMEOUT_MS)
    }

    private fun finishHealthSync(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
    ): Boolean {
        val claimed =
            synchronized(this) {
                if (healthSyncGeneration != generation ||
                    activeHealthSyncCallback !== callback ||
                    !activeHealthSyncDeviceId.equals(deviceId, ignoreCase = true)
                ) {
                    false
                } else {
                    activeHealthSyncCallback = null
                    activeHealthSyncDeviceId = ""
                    true
                }
            }
        if (claimed) {
            healthSyncTimeoutTask?.let(connectionHandler::removeCallbacks)
            healthSyncTimeoutTask = null
        }
        return claimed
    }

    private fun failHealthSync(
        generation: Int,
        callback: ResultCallback<List<Map<String, Any?>>>,
        deviceId: String,
        code: String,
        message: String,
    ) {
        if (!finishHealthSync(generation, callback, deviceId)) return
        emit("error", mapOf("code" to code, "message" to message, "deviceId" to deviceId))
        callback.error(code, message)
    }

    private fun cancelActiveHealthSync(
        code: String,
        message: String,
        emitError: Boolean,
    ) {
        val callback =
            synchronized(this) {
                val current = activeHealthSyncCallback
                activeHealthSyncCallback = null
                activeHealthSyncDeviceId = ""
                healthSyncGeneration += 1
                current
            }
        healthSyncTimeoutTask?.let(connectionHandler::removeCallbacks)
        healthSyncTimeoutTask = null
        if (callback != null) {
            if (emitError) emit("error", mapOf("code" to code, "message" to message))
            callback.error(code, message)
        }
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
            else callback.error("MEASUREMENT_COMMAND_FAILED", "暂时无法开始测量，请稍后重试")
        }

    private fun writeResponse(callback: ResultCallback<*>, message: String) =
        IBleWriteResponse { code ->
            if (code != Code.REQUEST_SUCCESS) callback.error("WRITE_FAILED", message)
        }

    private fun <T> withOperationTimeout(
        callback: ResultCallback<T>,
        code: String,
        message: String,
    ): ResultCallback<T> {
        val completed = AtomicBoolean(false)
        lateinit var timeout: Runnable
        val guarded =
            object : ResultCallback<T> {
                override fun success(value: T) {
                    if (!completed.compareAndSet(false, true)) return
                    connectionHandler.removeCallbacks(timeout)
                    callback.success(value)
                }

                override fun error(code: String, message: String) {
                    if (!completed.compareAndSet(false, true)) return
                    connectionHandler.removeCallbacks(timeout)
                    callback.error(code, message)
                }
            }
        timeout = Runnable { guarded.error(code, message) }
        connectionHandler.postDelayed(timeout, DEVICE_SETTING_TIMEOUT_MS)
        return guarded
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

    private fun registerConnectStatusListener(address: String, generation: Int) {
        unregisterConnectStatusListener()
        val listener =
            object : IABleConnectStatusListener() {
                override fun onConnectStatusChanged(mac: String, status: Int) {
                    if (!mac.equals(address, ignoreCase = true)) return
                    connectionHandler.post {
                        if (connectionGeneration != generation) return@post
                        val activeCallback = activeConnectionFor(generation)
                        if (status == Constants.STATUS_CONNECTED) {
                            // Low-level GATT may connect briefly while the SDK
                            // is still retrying service discovery. Only the
                            // official connect/notify callbacks advance stage.
                            return@post
                        }
                        if (status != Constants.STATUS_DISCONNECTED) return@post
                        if (activeCallback != null) {
                            // Ignore the listener's initial disconnected state;
                            // once transport connected, a drop must finish the
                            // pending MethodChannel call instead of hanging it.
                            if (activeTransportConnected) {
                                failConnection(
                                    generation,
                                    activeCallback,
                                    "CONNECTION_DROPPED",
                                    "设备连接中断，请将手表靠近手机后重试",
                                )
                            }
                            return@post
                        }
                        if (connectedDeviceId.equals(address, ignoreCase = true)) {
                            cancelActiveHealthSync(
                                "HEALTH_SYNC_CANCELLED",
                                "设备连接已断开，历史数据同步已取消",
                                emitError = false,
                            )
                            connectingDeviceId = ""
                            connectedDeviceId = ""
                            activeMetric = null
                            releaseJLWatchFaceSession()
                            emit("disconnected", mapOf("deviceId" to mac))
                        }
                    }
                }
            }
        connectStatusAddress = address
        connectStatusListener = listener
        manager.registerConnectStatusListener(address, listener)
    }

    private fun unregisterConnectStatusListener() {
        val address = connectStatusAddress
        val listener = connectStatusListener
        connectStatusAddress = ""
        connectStatusListener = null
        if (address.isNotBlank() && listener != null) {
            runCatching { manager.unregisterConnectStatusListener(address, listener) }
        }
    }

    private fun fail(callback: ResultCallback<Unit>, code: String, message: String) {
        emit("error", mapOf("code" to code, "message" to message))
        callback.error(code, message)
    }

    fun close() {
        cancelActiveHealthSync(
            "HEALTH_SYNC_CANCELLED",
            "设备服务已关闭，历史数据同步已取消",
            emitError = false,
        )
        cancelActiveConnectionAttempt(
            "CONNECT_CANCELLED",
            "连接任务已取消",
            emitError = false,
        )
        manager.stopScanDevice()
        finishScan()
        unregisterConnectStatusListener()
        connectingDeviceId = ""
        connectedDeviceId = ""
        releaseJLWatchFaceSession()
        manager.disconnectWatch { }
        eventListener = null
    }

    private fun capabilitiesFrom(data: FunctionDeviceSupportData): Map<String, Any?> {
        val metrics = mutableListOf("steps", "distance", "calories", "sleep")
        if (data.heartDetect.haveFunction()) metrics += "heart_rate"
        if (data.bp.haveFunction()) metrics += "blood_pressure"
        if (data.spo2H.haveFunction()) metrics += "blood_oxygen"
        if (data.bloodGlucose.haveFunction()) metrics += "blood_glucose"
        if (data.temperatureFunction.haveFunction() || data.temptureType > 0) metrics += "body_temperature"
        if (data.ecg.haveFunction()) metrics += "ecg"
        if (data.hrvFunction.haveFunction()) metrics += "hrv"
        if (data.bodyComponent.haveFunction()) metrics += "body_composition"
        if (data.bloodComponent.haveFunction()) metrics += "blood_composition"
        val preferences = VpSpGetUtil.getVpSpVariInstance(appContext)
        val features = mutableListOf("health_monitoring")
        if (data.watchUiServerCount > 0 || data.watchUiCoustomCount > 0 || manager.isJLCPUPlatform) {
            features += "watch_faces"
        }
        if (data.watchUiCoustomCount > 0 || manager.isJLCPUPlatform) {
            features += "photo_watch_face"
        }
        if (preferences.isSupportFindDeviceByPhone) features += "find_watch"
        if (preferences.isSupportCamera) features += "camera"
        if (preferences.isSupportBTFunction) features += "phone_calls"
        if (preferences.isSupportContactFunction) features += "contacts"
        if (data.allMsgLength > 0) features += "notifications"
        if (preferences.isSupportMultiAlarm || preferences.isSupportTextAlarm) features += "alarms"
        if (preferences.isSupportWeather) features += "weather"
        if (preferences.isSupportWorldClock) features += "world_clock"
        if (preferences.isSupportHealthRemind || preferences.isSupportLongseat) features += "health_reminders"
        if (preferences.isSupportHealthAssessment) features += "health_assessment"
        if (preferences.isSupportScreenlight ||
            preferences.isSupportScreenlightTime ||
            preferences.isSupportNightturnSetting
        ) {
            features += "screen_display"
        }
        val integratedFeatures =
            listOf(
                "watch_faces",
                "photo_watch_face",
                "find_watch",
                "camera",
                "phone_calls",
                "contacts",
                "notifications",
                "alarms",
                "weather",
                "world_clock",
                "health_reminders",
                "health_monitoring",
                "health_assessment",
                "screen_display",
            ).filter { feature ->
                features.contains(feature) &&
                    (feature !in setOf("watch_faces", "photo_watch_face") || manager.isJLCPUPlatform)
            }
        return mapOf(
            "metrics" to metrics,
            "features" to features.distinct(),
            "integratedFeatures" to integratedFeatures,
            "supportsBackgroundSync" to true,
            "supportsWatchFaces" to features.contains("watch_faces"),
            "supportsOta" to false,
        )
    }

    companion object {
        private const val LOG_TAG = "SaidianVeepoo"
        private const val PERSON_SYNC_TIMEOUT_MS = 8_000L
        private const val CONNECTION_FLOW_TIMEOUT_MS = 180_000L
        private const val HEALTH_SYNC_IDLE_TIMEOUT_MS = 45_000L
        private const val DEVICE_SETTING_TIMEOUT_MS = 15_000L
        private const val ALARM_CACHE_FALLBACK_MS = 1_000L
        private const val ALARM_CACHE_SETTLE_MS = 120L
        private const val ALARM_WRITE_VERIFY_DELAY_MS = 1_200L
        private const val MAX_ALARM_LABEL_LENGTH = 20
        private const val WATCH_FACE_READ_TIMEOUT_MS = 45_000L
        private const val WATCH_FACE_CURRENT_READ_DELAY_MS = 200L
        private const val WATCH_FACE_CURRENT_READ_TIMEOUT_MS = 8_000L
        private const val JL_REQUESTED_MTU = 247
        private const val JL_MTU_CALLBACK_GRACE_MS = 1_500L
        private const val WATCH_FACE_SWITCH_TIMEOUT_MS = 20_000L
        private const val WATCH_FACE_VERIFY_DELAY_MS = 1_200L
        private const val STALE_DISCONNECT_CHECKS = 20
        private const val STALE_DISCONNECT_POLL_MS = 150L
        private const val NOTIFICATION_PREFS = "saidian_notification_settings"
        private const val LEGACY_SEDENTARY_ID = "legacy_sedentary"
        private val NOTIFICATION_KEYS =
            listOf(
                "incomingCall",
                "sms",
                "wechat",
                "qq",
                "whatsapp",
                "dingtalk",
                "wecom",
                "tiktok",
                "telegram",
                "otherApps",
            )

        private fun defaultCapabilities(): Map<String, Any?> =
            mapOf(
                "metrics" to listOf("steps", "distance", "calories", "sleep"),
                "features" to listOf("health_monitoring"),
                "integratedFeatures" to listOf("health_monitoring"),
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

        private fun sleepRecordDate(day: String, sleep: SleepData): Date {
            val sdkDate = sleep.date?.trim().orEmpty()
            if (sdkDate.isNotEmpty()) return dateAtNoon(sdkDate)
            val daysAgo = day.toIntOrNull()?.coerceAtLeast(0) ?: 0
            return Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, -daysAgo)
                set(Calendar.HOUR_OF_DAY, 12)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.time
        }

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
