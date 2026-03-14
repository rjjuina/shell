pragma Singleton

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    function transformSearch(search: string): string {
        const actionText = search.slice(Config.launcher.actionPrefix.length);
        // Only match the first word (action name), ignore parameters after space
        const spaceIndex = actionText.indexOf(' ');
        return spaceIndex !== -1 ? actionText.slice(0, spaceIndex) : actionText;
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.actions

    Variants {
        id: variants

        model: Config.launcher.actions.filter(a => (a.enabled ?? true) && (Config.launcher.enableDangerousActions || !(a.dangerous ?? false)))

        Action {}
    }

    component Action: QtObject {
        required property var modelData
        readonly property string name: modelData.name ?? qsTr("Unnamed")
        readonly property string desc: modelData.description ?? qsTr("No description")
        readonly property string icon: modelData.icon ?? "help_outline"
        readonly property list<string> command: modelData.command ?? []
        readonly property bool enabled: modelData.enabled ?? true
        readonly property bool dangerous: modelData.dangerous ?? false

        function onClicked(list: AppList): void {
            if (command.length === 0)
                return;

            if (command[0] === "autocomplete" && command.length > 1) {
                list.search.text = `${Config.launcher.actionPrefix}${command[1]} `;
            } else if (command[0] === "setMode" && command.length > 1) {
                list.visibilities.launcher = false;
                Colours.setMode(command[1]);
            } else {
                list.visibilities.launcher = false;
                // Extract parameter from search text (text after action name)
                const searchText = list.search.text.slice(Config.launcher.actionPrefix.length);
                const spaceIndex = searchText.indexOf(' ');
                const param = spaceIndex !== -1 ? searchText.slice(spaceIndex + 1).trim() : "";

                // Substitute %s in command with the parameter
                const processedCommand = command.map(arg =>
                    arg.includes('%s') ? arg.replace(/%s/g, param) : arg
                );

                Quickshell.execDetached(processedCommand);
            }
        }
    }
}
