allprojects {
    repositories {
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://maven.aliyun.com/repository/public")
        val yuchengPluginSource = gradle.extra.properties["yuchengPluginSource"] as? String
        if (yuchengPluginSource != null) {
            flatDir {
                dirs(file("$yuchengPluginSource/android/libs"))
            }
        }
        google()
        mavenCentral()
    }

    configurations.configureEach {
        resolutionStrategy {
            // Flutter's integration_test plugin still declares dynamic
            // AndroidX test versions. Pin the versions already used by this
            // project so release builds remain reproducible and do not need
            // Maven metadata access merely to package the application.
            force("androidx.test:runner:1.3.0")
            force("androidx.test:rules:1.2.0")
            force("androidx.test.espresso:espresso-core:3.3.0")
        }
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
