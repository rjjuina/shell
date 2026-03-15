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
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    spacing: Appearance.spacing.small

    Loader {
        active: Config.bar.clock.showIcon
        visible: active

        sourceComponent: MaterialIcon {
            text: "calendar_month"
            color: root.colour
        }
    }

    StyledText {
        id: text

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
