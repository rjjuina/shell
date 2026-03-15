pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.utils
import qs.config
import QtQuick

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary
    readonly property bool isTop: Config.bar.position === "top"

    readonly property int maxSize: {
        const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
        const otherSize = otherModules.reduce((acc, curr) => {
            if (isTop)
                return acc + (curr.item?.nonAnimWidth ?? curr.width);
            return acc + (curr.item?.nonAnimHeight ?? curr.height);
        }, 0);
        const dimension = isTop ? bar.width : bar.height;
        return dimension - otherSize - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    property Title current: text1

    clip: true
    implicitWidth: isTop
        ? icon.implicitWidth + current.implicitWidth + Appearance.spacing.small
        : Math.max(icon.implicitWidth, current.implicitHeight)
    implicitHeight: isTop
        ? Math.max(icon.implicitHeight, current.implicitHeight)
        : icon.implicitHeight + current.implicitWidth + current.anchors.topMargin

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    TextMetrics {
        id: metrics

        text: Hypr.activeToplevel?.title ?? qsTr("Desktop")
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        elide: Qt.ElideRight
        elideWidth: root.maxSize - (isTop ? icon.width + Appearance.spacing.small : icon.height)

        onTextChanged: {
            const next = root.current === text1 ? text2 : text1;
            next.text = elidedText;
            root.current = next;
        }
        onElideWidthChanged: root.current.text = elidedText
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

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: isTop ? undefined : icon.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined
        anchors.left: isTop ? icon.right : undefined
        anchors.top: isTop ? undefined : icon.bottom
        anchors.topMargin: isTop ? 0 : Appearance.spacing.small
        anchors.leftMargin: isTop ? Appearance.spacing.small : 0

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: root.current === this ? 1 : 0

        transform: [
            Translate {
                x: isTop ? 0 : (Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0)
            },
            Rotation {
                angle: isTop ? 0 : (Config.bar.activeWindow.inverted ? 270 : 90)
                origin.x: isTop ? 0 : text.implicitHeight / 2
                origin.y: isTop ? 0 : text.implicitHeight / 2
            }
        ]

        width: isTop ? implicitWidth : implicitHeight
        height: isTop ? implicitHeight : implicitWidth

        Behavior on opacity {
            Anim {}
        }
    }
}
