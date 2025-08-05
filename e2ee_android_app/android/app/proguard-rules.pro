# Rules for OneSignal SDK
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

-keepattributes Signature


# Rules for Google Play Services (a dependency of OneSignal)
-keep class com.google.android.gms.common.api.internal.IStatusCallback { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# Rules for permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
-keep class io.flutter.plugins.permissionhandler.** { *; }