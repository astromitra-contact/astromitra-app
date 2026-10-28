# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.OpenSSLProvider

# ── Flutter Video Player (ExoPlayer) ─────────────────────────────────────────
-keep class io.flutter.plugins.videoplayer.** { *; }
-dontwarn io.flutter.plugins.videoplayer.**

# ExoPlayer - keep all media/player classes from being stripped by R8
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Keep ExoPlayer extractors and decoders (required for video decoding)
-keepclassmembers class com.google.android.exoplayer2.** { *; }
-keepclassmembers class androidx.media3.** { *; }

# Keep OkHttp (used internally by video_player for network streams)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# Keep Dio / HTTP networking
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Startup
-keep class androidx.startup.** { *; }
-dontwarn androidx.startup.**

# Room
-keep class androidx.room.** { *; }
-dontwarn androidx.room.**

# Code obfuscation compression ratio, between 0 and 7, the default is 5, generally do not modify
-optimizationpasses 5

# Do not use case mixing when mixing, and the mixed class name is lowercase
-dontusemixedcaseclassnames

# Specify not to ignore non-public library classes
-dontskipnonpubliclibraryclasses

# This sentence can confuse our project to generate a mapping file
# Contains the mapping relationship of class name -> obfuscated class name
-verbose

# Specify not to ignore class members of non-public libraries
-dontskipnonpubliclibraryclassmembers

# Without pre-verification, preverify is one of the four steps of proguard. Android does not need preverify. Removing this step can speed up the obfuscation.
-dontpreverify

# Keep Annotation not confusing
-keepattributes *Annotation*,InnerClasses

# Avoid confusing generics
-keepattributes Signature

# Keep code line numbers when throwing exceptions
-keepattributes SourceFile,LineNumberTable

# Specify the algorithm to use for obfuscation, and the following parameter is a filter
# This filter is the algorithm recommended by Google and generally does not change
-optimizations !code/simplification/cast,!field/*,!class/merging/*

