# Veepoo's scanner passes SearchResponse callbacks through java.lang.reflect.Proxy.
# R8 must not merge or rewrite these SDK callback types to concrete classes.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
-keep class com.veepoo.** { *; }
-keep interface com.veepoo.** { *; }
-keep class com.inuker.bluetooth.library.** { *; }
-keep interface com.inuker.bluetooth.library.** { *; }

# JL's authentication libraries register native methods by their Java names.
# Keep these names in release builds so libjl_auth can resolve setLinkKey and
# the watch-face/photo-watch-face session can initialize.
-keep class com.jieli.** { *; }
-keep interface com.jieli.** { *; }

# Keep the app-side anonymous callbacks separate from Veepoo's internal callback
# implementations. Horizontal class merging caused $Proxy instances to be cast
# to the merged concrete callback class in the previous release APK.
-keep class cc.saidian.saydian_app.VeepooWearableAdapter** { *; }
