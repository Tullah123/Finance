import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (name == "google_mlkit_commons" ||
        name == "google_mlkit_text_recognition" ||
        name == "flutter_native_timezone"
    ) {
        plugins.withId("com.android.library") {
            val androidExt = extensions.findByType(LibraryExtension::class.java)
            when (name) {
                "google_mlkit_commons" -> {
                    androidExt?.namespace = "com.google_mlkit_commons"
                }
                "google_mlkit_text_recognition" -> {
                    androidExt?.namespace = "com.google_mlkit_text_recognition"
                }
                "flutter_native_timezone" -> {
                    androidExt?.namespace = "com.whelksoft.flutter_native_timezone"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
