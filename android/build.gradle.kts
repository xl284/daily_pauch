allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 统一所有第三方 Android 库模块的 compileSdk 为 app 的 compileSdk，
// 避免插件各自声明不同 compileSdkVersion 而本机没装对应平台时构建失败。
subprojects {
    project.afterEvaluate {
        if (plugins.hasPlugin("com.android.library")) {
            runCatching {
                extensions.configure<com.android.build.gradle.LibraryExtension> {
                    compileSdk = 37
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
