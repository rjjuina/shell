pragma ComponentBehavior: Bound

import qs.components
import qs.config
import "popouts" as BarPopouts
import Quickshell
import QtQuick

Item {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    required property bool disabled

    readonly property bool isTop: Config.bar.position === "top"
    readonly property int padding: Math.max(Appearance.padding.smaller, Config.border.thickness)
    readonly property int contentWidth: isTop ? 0 : Config.bar.sizes.innerWidth + padding * 2
    readonly property int contentHeight: isTop ? Config.bar.sizes.innerHeight + padding * 2 : 0
    readonly property int exclusiveZone: {
        if (disabled)
            return Config.border.thickness;
        if (isTop)
            return (Config.bar.persistent || visibilities.bar) ? contentHeight : Config.border.thickness;
        return (Config.bar.persistent || visibilities.bar) ? contentWidth : Config.border.thickness;
    }
    readonly property bool shouldBeVisible: !disabled && (Config.bar.persistent || visibilities.bar || isHovered)
    property bool isHovered

    function closeTray(): void {
        content.item?.closeTray();
    }

    function checkPopout(pos: real): void {
        content.item?.checkPopout(pos);
    }

    function handleWheel(pos: real, angleDelta: point): void {
        content.item?.handleWheel(pos, angleDelta);
    }

    visible: isTop ? height > Config.border.thickness : width > Config.border.thickness
    implicitWidth: isTop ? 0 : Config.border.thickness
    implicitHeight: isTop ? Config.border.thickness : 0

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitWidth: root.isTop ? root.implicitWidth : root.contentWidth
            root.implicitHeight: root.isTop ? root.contentHeight : root.implicitHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: root.isTop ? "implicitHeight" : "implicitWidth"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: root.isTop ? "implicitHeight" : "implicitWidth"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.fill: parent

        active: root.shouldBeVisible || root.visible

        sourceComponent: Bar {
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts
        }
    }
}
