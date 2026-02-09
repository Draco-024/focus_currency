import com.android.build.gradle.BaseExtension

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

// ✅ THE FIX: Force plugins (like usage_stats) to use SDK 34
// This is placed BEFORE evaluationDependsOn to prevent the crash
subprojects {
    afterEvaluate {
        // Only apply to Android libraries (plugins), not the main app (which we config manually)
        if (project.name != "app" && extensions.findByName("android") != null) {
            configure<BaseExtension> {
                compileSdkVersion(34)
                defaultConfig {
                    minSdk = 21
                    targetSdk = 34
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}