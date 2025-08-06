# Preserve class names for Firebase libraries
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Preserve models annotated with @Keep
-keepattributes *Annotation*
-keep class * {
    @com.google.firebase.database.IgnoreExtraProperties *;
}

# General rule to prevent obfuscation for the main application
-keep public class * extends android.app.Application
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Activity
-keep public class * extends android.content.Service

# Add Razorpay-related rules
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# GPay & Paisa SDK used by Razorpay
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# Kotlin metadata (if using Kotlin)
-keepclassmembers class * {
    @kotlin.Metadata *;
}

# Flutter deferred component & Play Core compatibility
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep annotations that may be stripped by R8
-keepattributes *Annotation*
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep <methods>;
}
-keepclassmembers class * {
    @proguard.annotation.KeepClassMembers <fields>;
}
