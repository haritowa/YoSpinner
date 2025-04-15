import ProjectDescription

let project = Project(
    name: "YoSpinner",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableSynthesizedResourceAccessors: true
    ),
    targets: [
        .target(
            name: "YoSpinner",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "io.tuist.YoSpinner",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "LaunchScreenBackground",
                        "UIImageName": "",
                    ],
                    "UIApplicationSceneManifest": [
                        "UIApplicationSupportsMultipleScenes": false,
                        "UISceneConfigurations": [
                            "UIWindowSceneSessionRoleApplication": [
                                [
                                    "UISceneConfigurationName": "Default Configuration",
                                    "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                                ]
                            ]
                        ]
                    ],
                    "UIMainStoryboardFile": "",
                    "UIRequiredDeviceCapabilities": ["armv7"],
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ]
                ]
            ),
            sources: ["YoSpinner/Sources/**"],
            resources: ["YoSpinner/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "YoSpinnerTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "io.tuist.YoSpinnerTests",
            infoPlist: .default,
            sources: ["YoSpinner/Tests/**"],
            resources: [],
            dependencies: [.target(name: "YoSpinner")]
        ),
    ]
)
