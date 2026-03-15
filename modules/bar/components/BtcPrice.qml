pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Caelestia
import Quickshell
import QtQuick

Grid {
    id: root

    property color colour: Colours.palette.m3tertiary
    property string price: "..."
    readonly property bool isTop: Config.bar.position === "top"

    columns: isTop ? -1 : 1
    rows: isTop ? 1 : -1
    flow: isTop ? Grid.LeftToRight : Grid.TopToBottom
    spacing: Appearance.spacing.small

    MaterialIcon {
        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined
        text: "currency_bitcoin"
        color: root.colour
    }

    StyledText {
        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        anchors.verticalCenter: isTop ? parent.verticalCenter : undefined
        horizontalAlignment: StyledText.AlignHCenter
        text: root.price
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        color: root.colour
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            Requests.get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd", text => {
                try {
                    const json = JSON.parse(text);
                    const usd = json.bitcoin.usd;
                    if (usd >= 1000)
                        root.price = Math.round(usd / 1000) + "k";
                    else
                        root.price = "$" + Math.round(usd);
                } catch (e) {
                    root.price = "N/A";
                }
            }, err => {
                root.price = "N/A";
            });
        }
    }
}
