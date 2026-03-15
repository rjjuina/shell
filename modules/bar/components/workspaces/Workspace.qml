import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isTop: Config.bar.position === "top"
    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: isTop
        ? implicitWidth + (hasWindows ? Appearance.padding.small : 0)
        : implicitHeight + (hasWindows ? Appearance.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    columns: isTop ? 1 : 1
    rows: isTop ? 1 : -1
    flow: isTop ? GridLayout.LeftToRight : GridLayout.TopToBottom

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.preferredHeight: isTop ? -1 : size
    Layout.preferredWidth: isTop ? size : -1

    columnSpacing: 0
    rowSpacing: 0

    StyledText {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.preferredHeight: isTop ? Config.bar.sizes.innerHeight - Appearance.padding.small * 2 : Config.bar.sizes.innerWidth - Appearance.padding.small * 2
        Layout.preferredWidth: isTop ? Config.bar.sizes.innerHeight - Appearance.padding.small * 2 : -1

        animate: true
        text: {
            const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
            const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
            let displayName = wsName.toString();
            if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
                displayName = displayName.toUpperCase();
            } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
                displayName = displayName.toLowerCase();
            }
            const label = Config.bar.workspaces.label || displayName;
            const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
            const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
            return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
    }

    Loader {
        id: windows

        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.fillHeight: !isTop
        Layout.fillWidth: isTop
        Layout.topMargin: isTop ? 0 : -Config.bar.sizes.innerWidth / 10
        Layout.leftMargin: isTop ? -Config.bar.sizes.innerHeight / 10 : 0

        visible: active
        active: root.hasWindows

        sourceComponent: Grid {
            columns: root.isTop ? -1 : 1
            rows: root.isTop ? 1 : -1
            flow: root.isTop ? Grid.LeftToRight : Grid.TopToBottom
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: Hypr.toplevels.values.filter(c => c.workspace?.id === root.ws)
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }
}
