pragma ComponentBehavior: Bound

import qs.components
import qs.services
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
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter
    spacing: Appearance.spacing.small

    MaterialIcon {
        text: "currency_bitcoin"
        color: root.colour
    }

    StyledText {
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
                    root.price = "$" + Math.round(usd).toLocaleString();
                } catch (e) {
                    root.price = "N/A";
                }
            }, err => {
                root.price = "N/A";
            });
        }
    }
}
