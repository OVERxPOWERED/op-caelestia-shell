# Live Wallpaper Changes
This file tracks the exact changes made to implement the live wallpaper feature.

## 1. `modules/background/Wallpaper.qml`

### Removed Code:
```qml
    property CachingImage current

    onSourceChanged: {
        if (!source)
            current = null;
        else
            current = imgComp.createObject(this, {
                path: source
            });
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                current = imgComp.createObject(this, {
                    path: source
                });
                completed = true;
            });
    }
```

### Added Code:
```qml
    property Item current

    onSourceChanged: {
        if (!source)
            current = null;
        else {
            const isGif = source.toLowerCase().endsWith(".gif");
            current = (isGif ? animImgComp : imgComp).createObject(this, {
                path: source
            });
        }
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                const isGif = source.toLowerCase().endsWith(".gif");
                current = (isGif ? animImgComp : imgComp).createObject(this, {
                    path: source
                });
                completed = true;
            });
    }
```

### Appended to the end of the file (New Component):
```qml
    Component {
        id: animImgComp

        AnimatedImage {
            id: animImg

            anchors.fill: parent

            opacity: 0
            fillMode: Image.PreserveAspectCrop
            source: "file://" + path
            playing: true

            onStatusChanged: {
                if (status === Image.Ready)
                    anim.start();
            }

            Anim on opacity {
                id: anim

                type: Anim.SlowEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== animImg && root.current?.status === Image.Ready
                interval: anim.duration
                onTriggered: animImg.destroy()
            }
        }
    }
```
