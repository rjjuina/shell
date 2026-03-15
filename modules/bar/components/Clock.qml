pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

Grid {
    id: root

    property color colour: Colours.palette.m3tertiary
    readonly property bool isTop: Config.bar.position === "top"

    columns: isTop ? -1 : 1
    rows: isTop ? 1 : -1
    flow: isTop ? Grid.LeftToRight : Grid.TopToBottom
    spacing: Appearance.spacing.small

    Loader {
        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined

        active: Config.bar.clock.showIcon
        visible: active

        sourceComponent: MaterialIcon {
            text: "calendar_month"
            color: root.colour
        }
    }

    StyledText {
        id: text

        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined

        horizontalAlignment: StyledText.AlignHCenter
        text: {
            if (isTop)
                return Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "hh:mm");
            return Time.format(Config.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm");
        }
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        color: root.colour
    }
}
