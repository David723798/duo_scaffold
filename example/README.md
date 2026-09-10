# Duo Scaffold Mail example

This is the package's complete reference implementation. It demonstrates how a single `DuoScaffold` manages its drawer, floating action button, snack bars, and adaptive content and controls.

Run it from this directory:

```sh
flutter pub get
flutter run
```

## What to look for

| In the app | Relevant API | Why it matters |
| --- | --- | --- |
| Inbox and message detail | `DuoBody` | Shows one selected pane in compact layouts and both panes in book or expanded landscape layouts. |
| Layout label and posture preview | `DuoLayoutPolicy` | Resolves the page layout and lets the example inject a preview override. |
| Simulated book and tabletop hinge | `DuoDisplayFeature` | Shows that book and tabletop come from half-open display features, not window shape. |
| App-bar actions, bottom navigation, and side rail | `DuoScaffold` | Preserves top-and-bottom controls on narrow windows and moves declared controls to a physical rail on wide windows. |
| Drawer button and drawer edge | `DuoScaffold.drawer` | Keeps the drawer on the same physical edge as the side rail. |

`MailDemoPage` owns the selected mailbox, selected message, and compact inbox/detail state. `DuoBody` only decides which panes are visible. Keep domain and navigation state in the page or its state-management layer, then pass the current compact pane to `DuoBody`.

## Preview controls

Use the preview icon in the app bar to select automatic sizing or one of the six layouts. Book and tabletop previews inject a simulated half-open hinge, so they can be inspected without a foldable device. **Automatic** restores the real `MediaQuery.displayFeatures` source; the layout banner identifies simulated previews.

Controls move to a physical right-side rail when the window is at least 600 logical pixels wide, including a wide portrait window. Use the split icon to force top-and-bottom, left-rail, or right-rail controls. Choose **Automatic** to restore the responsive default. This preview changes a Flutter layout choice; it does not emulate native hardware-control detection.

The app keeps its selection while changing either preview. On compact layouts, opening a message changes to the detail pane. On two-pane layouts, the inbox and detail remain visible together.

## Platforms

The example includes web, iOS, and macOS runners.

```sh
flutter run -d chrome
flutter run -d ios
flutter run -d macos
```

For a production web build, run `flutter build web`.

The iOS runner uses bundle identifier `dev.duoscaffold.duoScaffoldExample` and iOS 15.0 as its minimum deployment target. Open `ios/Runner.xcworkspace` or `macos/Runner.xcworkspace` in Xcode to inspect or edit the native projects.

In VS Code, select **Duo Scaffold Example** to choose an available device, or select a platform-specific Duo Scaffold Example launch configuration from Run and Debug. The configurations are defined in `../.vscode/launch.json`.
