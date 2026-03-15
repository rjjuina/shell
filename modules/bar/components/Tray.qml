pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon
    readonly property bool isTop: Config.bar.position === "top"

    readonly property int padding: Config.bar.tray.background ? Appearance.padding.normal : Appearance.padding.small
    readonly property int spacing: Config.bar.tray.background ? Appearance.spacing.small : 0

    property bool expanded

    readonly property real nonAnimHeight: {
        if (!Config.bar.tray.compact)
            return layout.implicitHeight + padding * 2;
        return (expanded ? expandIcon.implicitHeight + layout.implicitHeight + spacing : expandIcon.implicitHeight) + padding * 2;
    }

    readonly property real nonAnimWidth: {
        if (!Config.bar.tray.compact)
            return layout.implicitWidth + padding * 2;
        return (expanded ? expandIcon.implicitWidth + layout.implicitWidth + spacing : expandIcon.implicitWidth) + padding * 2;
    }

    clip: true
    visible: isTop ? width > 0 : height > 0

    implicitWidth: isTop ? nonAnimWidth : Config.bar.sizes.innerWidth
    implicitHeight: isTop ? Config.bar.sizes.innerHeight : nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Appearance.rounding.full

    Grid {
        id: layout

        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined
        anchors.top: isTop ? undefined : parent.top
        anchors.left: isTop ? parent.left : undefined
        anchors.topMargin: isTop ? 0 : root.padding
        anchors.leftMargin: isTop ? root.padding : 0

        columns: isTop ? -1 : 1
        rows: isTop ? 1 : -1
        flow: isTop ? Grid.LeftToRight : Grid.TopToBottom
        spacing: Appearance.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

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
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !Config.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {}
        }
    }

    Loader {
        id: expandIcon

        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined
        anchors.bottom: isTop ? undefined : parent.bottom
        anchors.right: isTop ? parent.right : undefined

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth - (isTop ? Appearance.padding.small * 2 : 0)
            implicitHeight: expandIconInner.implicitHeight - (isTop ? 0 : Appearance.padding.small * 2)

            MaterialIcon {
                id: expandIconInner

                anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
                anchors.verticalCenter: isTop ? parent.verticalCenter : undefined
                anchors.bottom: isTop ? undefined : parent.bottom
                anchors.right: isTop ? parent.right : undefined
                anchors.bottomMargin: isTop ? 0 : (Config.bar.tray.background ? Appearance.padding.small : -Appearance.padding.small)
                anchors.rightMargin: isTop ? (Config.bar.tray.background ? Appearance.padding.small : -Appearance.padding.small) : 0
                text: isTop ? "expand_more" : "expand_less"
                font.pointSize: Appearance.font.size.large
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }
}
