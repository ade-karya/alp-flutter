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
    val newBuildDir = File(rootProject.buildDir, project.name)
    // Only relocate build directory if the project is part of the main codebase (inside root directory)
    // This prevents "different roots" errors for plugins located in pub cache on other drives (e.g. C: vs D:)
    if (project.projectDir.absolutePath.startsWith(rootProject.projectDir.absolutePath)) {
        project.buildDir = newBuildDir
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
