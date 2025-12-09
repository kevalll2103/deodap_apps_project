# Suppress warnings about Java 8 Stream Support library
-dontwarn j$.util.concurrent.ConcurrentHashMap$TreeBin
-dontwarn j$.util.concurrent.ConcurrentHashMap
-dontwarn j$.util.concurrent.ConcurrentHashMap$CounterCell
-dontwarn j$.util.IntSummaryStatistics
-dontwarn j$.util.LongSummaryStatistics
-dontwarn j$.util.DoubleSummaryStatistics

# Keep required classes
-keep class j$.util.concurrent.ConcurrentHashMap { *; }
-keep class j$.util.IntSummaryStatistics { *; }
-keep class j$.util.LongSummaryStatistics { *; }
-keep class j$.util.DoubleSummaryStatistics { *; }

# Additional rules for your app
-keep class com.google.gson.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
