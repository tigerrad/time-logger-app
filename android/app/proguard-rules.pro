# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# local notifications
-keep class com.dexterous.** { *; }

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# general
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn okhttp3.**
-dontwarn okio.**