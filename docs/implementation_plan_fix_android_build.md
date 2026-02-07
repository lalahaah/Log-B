# 안드로이드 빌드 오류 해결 계획 (The supplied phased action failed with an exception)

## 문제 분석
사용자가 겪고 있는 `The supplied phased action failed with an exception` 오류는 주로 Gradle 동기화(Sync) 과정에서 설정 파일의 오류로 인해 발생합니다. 구체적으로 `android/build.gradle.kts`의 첫 번째 라인에서 문제가 발생하고 있습니다.

현재 코드:
```kotlin
layout.buildDirectory.value(layout.buildDirectory.dir("../../build").get())
```

### 주요 문제점:
1. **순환 참조 및 조기 평가**: `layout.buildDirectory`를 설정하면서 동시에 자기 자신에 대해 `.get()`을 호출하고 있습니다. 이는 Gradle의 Lazy Configuration 원칙에 어긋나며, 설정 단계에서 값이 확정되지 않은 상태에서 호출할 경우 예외를 발생시킵니다.
2. **잘못된 경로**: `../../build`는 `android/` 폴더를 기준으로 두 단계 위인 바탕화면(`Desktop/`)을 가리킬 가능성이 높습니다. Flutter 프로젝트의 표준 빌드 경로는 프로젝트 루트의 `build/` 폴더이므로 `../build`가 적절합니다.
3. **명시적 참조 부족**: 루트 프로젝트 수준의 파일이므로 `rootProject`를 명시하는 것이 좋습니다.

## 해결 단계
1. `android/build.gradle.kts` 파일을 수정하여 빌드 디렉토리 설정을 올바르게 변경합니다.
2. `.get()` 호출을 제거하여 지연 평가(Lazy Evaluation)가 이루어지도록 합니다.
3. 경로를 `../build`로 수정합니다.
4. Gradle 동기화가 정상적으로 이루어지는지 확인합니다.

## 수정 제안 코드
```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../build"))

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```
