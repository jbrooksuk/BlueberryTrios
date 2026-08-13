# Keep serialized save and puzzle model names stable across release builds.
-keepattributes *Annotation*
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}
