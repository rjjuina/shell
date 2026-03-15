pragma ComponentBehavior: Bound

import qs.components.containers
import qs.config
import Quickshell
import QtQuick

Scope {
    id: root

    required property ShellScreen screen
    required property Item bar

    // Bar exclusive zone
    ExclusionZone {
        anchors.left: Config.bar.position !== "top"
        anchors.top: Config.bar.position === "top"
        exclusiveZone: root.bar.exclusiveZone
    }

    // Border: top (only when bar is NOT on top, otherwise bar handles it)
    ExclusionZone {
        anchors.top: Config.bar.position !== "top"
    }

    // Border: left (only when bar is on top, otherwise bar handles it)
    ExclusionZone {
        anchors.left: Config.bar.position === "top"
    }

    ExclusionZone {
        anchors.right: true
    }

    ExclusionZone {
        anchors.bottom: true
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
