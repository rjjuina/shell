# Top Bar Position & BTC Price Widget Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add configurable bar position (left or top) and a BTC price widget to caelestia-shell.

**Architecture:** Add a `position` config property (`"left"` | `"top"`) that conditionally switches layout direction, anchoring, sizing, and interaction axes throughout the bar and drawer modules. The BTC price component uses the existing `Requests.get()` API (same pattern as Weather service) to poll CoinGecko every 60s.

**Tech Stack:** QML (Qt Quick), Quickshell framework, C++ Requests singleton for HTTP

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `config/BarConfig.qml` | Modify | Add `position` property and `showBtcPrice` status toggle |
| `modules/bar/Bar.qml` | Modify | Switch ColumnLayout ↔ RowLayout based on position; add BtcPrice delegate |
| `modules/bar/BarWrapper.qml` | Modify | Switch width ↔ height animation axis based on position |
| `modules/bar/components/BtcPrice.qml` | Create | BTC price display component using Requests.get() |
| `modules/bar/components/Clock.qml` | Modify | Adapt text layout for horizontal mode |
| `modules/bar/components/workspaces/Workspaces.qml` | Modify | Switch Column ↔ Row layout based on position |
| `modules/bar/components/workspaces/Workspace.qml` | Modify | Swap height ↔ width sizing for horizontal mode |
| `modules/bar/components/StatusIcons.qml` | Modify | Switch Column ↔ Row layout based on position |
| `modules/bar/components/ActiveWindow.qml` | Modify | Adjust rotation and sizing for horizontal mode |
| `modules/drawers/Drawers.qml` | Modify | Switch bar anchoring from left-edge to top-edge |
| `modules/drawers/Exclusions.qml` | Modify | Switch exclusive zone from left to top |
| `modules/drawers/Interactions.qml` | Modify | Swap x/y axes for bar hover/drag detection |
| `modules/drawers/Panels.qml` | Modify | Switch leftMargin to topMargin |
| `modules/drawers/Backgrounds.qml` | Modify | Adjust background leftMargin to topMargin |
| `modules/drawers/Border.qml` | Modify | Adjust border mask leftMargin to topMargin |

---

## Chunk 1: Config & BTC Price Component

### Task 1: Add config properties

**Files:**
- Modify: `config/BarConfig.qml`

- [ ] **Step 1: Add `position` property and `showBtcPrice` toggle**

In `config/BarConfig.qml`, add at line 3 (after `persistent`):

```qml
property string position: "left" // "left" or "top"
```

In the `Status` component, add after `showLockStatus`:

```qml
property bool showBtcPrice: false
```

In the `Sizes` component, add after `kbLayoutWidth`:

```qml
property int innerHeight: 40
```

- [ ] **Step 2: Commit**

```bash
git add config/BarConfig.qml
git commit -m "feat(config): add bar position and btcPrice config properties"
```

### Task 2: Create BtcPrice component

**Files:**
- Create: `modules/bar/components/BtcPrice.qml`

- [ ] **Step 1: Create the BtcPrice component**

Create `modules/bar/components/BtcPrice.qml`:

```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Caelestia
import Quickshell
import QtQuick

Column {
    id: root

    property color colour: Colours.palette.m3tertiary
    property string price: "..."
    readonly property bool isTop: Config.bar.position === "top"

    spacing: Appearance.spacing.small

    MaterialIcon {
        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
        text: "currency_bitcoin"
        color: root.colour
    }

    StyledText {
        anchors.horizontalCenter: isTop ? undefined : parent.horizontalCenter
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
```

- [ ] **Step 2: Register BtcPrice in Bar.qml delegate chooser**

In `modules/bar/Bar.qml`, add a new `DelegateChoice` block after the `clock` choice (around line 155):

```qml
DelegateChoice {
    roleValue: "btcPrice"
    delegate: WrappedLoader {
        sourceComponent: BtcPrice {}
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/bar/components/BtcPrice.qml modules/bar/Bar.qml
git commit -m "feat(bar): add BTC price widget component"
```

---

## Chunk 2: Bar Layout Direction (Bar.qml & BarWrapper.qml)

### Task 3: Make Bar.qml support both orientations

**Files:**
- Modify: `modules/bar/Bar.qml`

The core change: the root element is currently `ColumnLayout`. We cannot dynamically switch between ColumnLayout and RowLayout at runtime in QML. Instead, we use a `GridLayout` with `columns`/`rows` set conditionally.

- [ ] **Step 1: Replace ColumnLayout with GridLayout**

Replace the root `ColumnLayout` (line 12) with:

```qml
GridLayout {
    id: root

    required property ShellScreen screen
    required property PersistentProperties visibilities
    required property BarPopouts.Wrapper popouts
    readonly property int vPadding: Appearance.padding.large
    readonly property bool isTop: Config.bar.position === "top"

    columns: isTop ? -1 : 1
    rows: isTop ? 1 : -1
    flow: isTop ? GridLayout.LeftToRight : GridLayout.TopToBottom
```

Add `import QtQuick.Layouts` if not already present (it is).

- [ ] **Step 2: Update WrappedLoader margins and alignment**

In the `WrappedLoader` component at the bottom of Bar.qml, change:

```qml
Layout.alignment: isTop ? Qt.AlignVCenter : Qt.AlignHCenter

Layout.topMargin: !isTop && findFirstEnabled() === this ? root.vPadding : 0
Layout.bottomMargin: !isTop && findLastEnabled() === this ? root.vPadding : 0
Layout.leftMargin: isTop && findFirstEnabled() === this ? root.vPadding : 0
Layout.rightMargin: isTop && findLastEnabled() === this ? root.vPadding : 0
```

Where `isTop` references `root.isTop` — add a binding:

```qml
readonly property bool isTop: root.isTop
```

- [ ] **Step 3: Update checkPopout and handleWheel for orientation**

In `checkPopout`, the `childAt` call uses `width / 2, y` which assumes vertical layout. For horizontal, it should be `x, height / 2`. Update:

```qml
function checkPopout(pos: real): void {
    const ch = isTop
        ? (childAt(pos, height / 2) as WrappedLoader)
        : (childAt(width / 2, pos) as WrappedLoader);
```

Similarly update `handleWheel`:

```qml
function handleWheel(pos: real, angleDelta: point): void {
    const ch = isTop
        ? (childAt(pos, height / 2) as WrappedLoader)
        : (childAt(width / 2, pos) as WrappedLoader);
```

And the scroll region check (line 88) — for top bar, use `x < screen.width / 2` instead of `y < screen.height / 2`:

```qml
} else if ((isTop ? pos < screen.width / 2 : pos < screen.height / 2) && Config.bar.scrollActions.volume) {
```

- [ ] **Step 4: Update spacer fill direction**

The spacer delegate (line 117) uses `Layout.fillHeight`. For horizontal, it should fill width:

```qml
DelegateChoice {
    roleValue: "spacer"
    delegate: WrappedLoader {
        Layout.fillHeight: enabled && !root.isTop
        Layout.fillWidth: enabled && root.isTop
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add modules/bar/Bar.qml
git commit -m "feat(bar): support both vertical and horizontal layout directions"
```

### Task 4: Make BarWrapper.qml support both orientations

**Files:**
- Modify: `modules/bar/BarWrapper.qml`

- [ ] **Step 1: Add orientation-aware sizing**

Add `isTop` property and update size calculations:

```qml
readonly property bool isTop: Config.bar.position === "top"
readonly property int contentWidth: isTop ? 0 : Config.bar.sizes.innerWidth + padding * 2
readonly property int contentHeight: isTop ? Config.bar.sizes.innerHeight + padding * 2 : 0
readonly property int exclusiveZone: {
    if (disabled)
        return Config.border.thickness;
    if (isTop) {
        return (Config.bar.persistent || visibilities.bar) ? contentHeight : Config.border.thickness;
    } else {
        return (Config.bar.persistent || visibilities.bar) ? contentWidth : Config.border.thickness;
    }
}
readonly property bool shouldBeVisible: !disabled && (Config.bar.persistent || visibilities.bar || isHovered)
```

Replace the existing `contentWidth`, `exclusiveZone`, `shouldBeVisible` properties.

- [ ] **Step 2: Update visibility and implicit size logic**

Replace the `visible` and `implicitWidth` lines:

```qml
visible: isTop ? height > Config.border.thickness : width > Config.border.thickness
implicitWidth: isTop ? 0 : Config.border.thickness
implicitHeight: isTop ? Config.border.thickness : 0
```

- [ ] **Step 3: Update state and transitions for both axes**

Replace the `states` block:

```qml
states: State {
    name: "visible"
    when: root.shouldBeVisible

    PropertyChanges {
        root.implicitWidth: root.isTop ? root.implicitWidth : root.contentWidth
        root.implicitHeight: root.isTop ? root.contentHeight : root.implicitHeight
    }
}
```

Replace the `transitions` block — animate both width and height but only the active axis matters:

```qml
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
```

- [ ] **Step 4: Update inner Loader anchoring**

Replace the Loader anchors:

```qml
Loader {
    id: content

    anchors.top: parent.top
    anchors.bottom: isTop ? parent.bottom : parent.bottom
    anchors.left: isTop ? parent.left : undefined
    anchors.right: isTop ? parent.right : parent.right

    active: root.shouldBeVisible || root.visible

    sourceComponent: Bar {
        width: isTop ? parent.width : root.contentWidth
        height: isTop ? root.contentHeight : parent.height
        screen: root.screen
        visibilities: root.visibilities
        popouts: root.popouts
    }
}
```

- [ ] **Step 5: Commit**

```bash
git add modules/bar/BarWrapper.qml
git commit -m "feat(bar): make BarWrapper support top/left orientation"
```

---

## Chunk 3: Drawer Module Orientation Support

### Task 5: Update Drawers.qml bar anchoring

**Files:**
- Modify: `modules/drawers/Drawers.qml`

- [ ] **Step 1: Add isTop helper and update bar anchoring**

In the `Scope` block, add:

```qml
readonly property bool isTop: Config.bar.position === "top"
```

Update the BarWrapper instance (line 164-177). Change anchors from top+bottom (vertical) to left+right (horizontal) when in top mode:

```qml
BarWrapper {
    id: bar

    anchors.top: parent.top
    anchors.bottom: scope.isTop ? undefined : parent.bottom
    anchors.left: scope.isTop ? parent.left : undefined
    anchors.right: scope.isTop ? parent.right : undefined

    screen: scope.modelData
    visibilities: visibilities
    popouts: panels.popouts

    disabled: scope.barDisabled

    Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
}
```

- [ ] **Step 2: Update mask region**

The mask region (line 59-67) uses `bar.implicitWidth` for the x offset. In top mode, use `bar.implicitHeight` for the y offset:

```qml
mask: Region {
    x: scope.isTop ? win.dragMaskPadding : bar.implicitWidth + win.dragMaskPadding
    y: scope.isTop ? bar.implicitHeight + win.dragMaskPadding : Config.border.thickness + win.dragMaskPadding
    width: win.width - (scope.isTop ? 0 : bar.implicitWidth) - Config.border.thickness - win.dragMaskPadding * 2
    height: win.height - (scope.isTop ? bar.implicitHeight : 0) - Config.border.thickness * 2 - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    regions: regions.instances
}
```

Update the region Variants (line 74-88):

```qml
Region {
    required property Item modelData

    x: modelData.x + (scope.isTop ? 0 : bar.implicitWidth)
    y: modelData.y + (scope.isTop ? bar.implicitHeight : Config.border.thickness)
    width: modelData.width
    height: modelData.height
    intersection: Intersection.Subtract
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/drawers/Drawers.qml
git commit -m "feat(drawers): support top bar positioning in Drawers"
```

### Task 6: Update Panels.qml margins

**Files:**
- Modify: `modules/drawers/Panels.qml`

- [ ] **Step 1: Switch leftMargin to topMargin based on position**

Replace the anchors block (lines 31-33):

```qml
anchors.fill: parent
anchors.margins: Config.border.thickness
anchors.leftMargin: Config.bar.position === "top" ? Config.border.thickness : bar.implicitWidth
anchors.topMargin: Config.bar.position === "top" ? bar.implicitHeight : Config.border.thickness
```

- [ ] **Step 2: Commit**

```bash
git add modules/drawers/Panels.qml
git commit -m "feat(panels): adjust margins for top bar position"
```

### Task 7: Update Exclusions.qml

**Files:**
- Modify: `modules/drawers/Exclusions.qml`

- [ ] **Step 1: Switch exclusive zone from left to top**

Replace the first `ExclusionZone` (bar zone, lines 14-16):

```qml
ExclusionZone {
    anchors.left: Config.bar.position !== "top"
    anchors.top: Config.bar.position === "top"
    exclusiveZone: root.bar.exclusiveZone
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/drawers/Exclusions.qml
git commit -m "feat(exclusions): switch bar exclusive zone for top position"
```

### Task 8: Update Interactions.qml

**Files:**
- Modify: `modules/drawers/Interactions.qml`

- [ ] **Step 1: Add isTop property**

Add at the top of the component properties:

```qml
readonly property bool isTop: Config.bar.position === "top"
```

- [ ] **Step 2: Update bar hover/drag detection**

The bar detection currently checks `x < bar.implicitWidth` (line 91, 95, 202, 48). For top mode, check `y < bar.implicitHeight`:

In `onWheel` (line 47-50):

```qml
function onWheel(event: WheelEvent): void {
    if (isTop ? event.y < bar.implicitHeight : event.x < bar.implicitWidth) {
        bar.handleWheel(isTop ? event.x : event.y, event.angleDelta);
    }
}
```

In `onPositionChanged` (line 91):

```qml
if (!visibilities.bar && Config.bar.showOnHover && (isTop ? y < bar.implicitHeight : x < bar.implicitWidth))
    bar.isHovered = true;
```

Line 95 (drag show/hide):

```qml
if (pressed && (isTop ? dragStart.y < bar.implicitHeight : dragStart.x < bar.implicitWidth)) {
    if (isTop) {
        if (dragY > Config.bar.dragThreshold)
            visibilities.bar = true;
        else if (dragY < -Config.bar.dragThreshold)
            visibilities.bar = false;
    } else {
        if (dragX > Config.bar.dragThreshold)
            visibilities.bar = true;
        else if (dragX < -Config.bar.dragThreshold)
            visibilities.bar = false;
    }
}
```

Line 202-207 (popout hover):

```qml
if (isTop ? y < bar.implicitHeight : x < bar.implicitWidth) {
    bar.checkPopout(isTop ? x : y);
} else if ((!popouts.currentName.startsWith("traymenu") || (popouts.current?.depth ?? 0) <= 1) && !inLeftPanel(panels.popouts, x, y)) {
    popouts.hasCurrent = false;
    bar.closeTray();
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/drawers/Interactions.qml
git commit -m "feat(interactions): swap axes for top bar hover and drag"
```

### Task 9: Update Backgrounds.qml and Border.qml

**Files:**
- Modify: `modules/drawers/Backgrounds.qml`
- Modify: `modules/drawers/Border.qml`

- [ ] **Step 1: Update Backgrounds.qml**

Replace the anchors (lines 20-23):

```qml
anchors.fill: parent
anchors.margins: Config.border.thickness
anchors.leftMargin: Config.bar.position === "top" ? Config.border.thickness : bar.implicitWidth
anchors.topMargin: Config.bar.position === "top" ? bar.implicitHeight : Config.border.thickness
```

- [ ] **Step 2: Update Border.qml**

Replace the border mask anchors (line 39-40):

```qml
anchors.leftMargin: Config.bar.position === "top" ? Config.border.thickness : root.bar.implicitWidth
anchors.topMargin: Config.bar.position === "top" ? root.bar.implicitHeight : Config.border.thickness
```

Wait — looking at Border.qml again, line 38-41 shows the mask rectangle uses `anchors.margins` (all sides) plus `anchors.leftMargin` override. For top mode we need to override `topMargin` instead:

```qml
Rectangle {
    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: Config.bar.position === "top" ? Config.border.thickness : root.bar.implicitWidth
    anchors.topMargin: Config.bar.position === "top" ? root.bar.implicitHeight : Config.border.thickness
    radius: Config.border.rounding
}
```

- [ ] **Step 3: Commit**

```bash
git add modules/drawers/Backgrounds.qml modules/drawers/Border.qml
git commit -m "feat(drawers): adjust backgrounds and border for top bar"
```

---

## Chunk 4: Component Orientation Adaptation

### Task 10: Update Clock.qml for horizontal mode

**Files:**
- Modify: `modules/bar/components/Clock.qml`

- [ ] **Step 1: Adapt clock layout for top bar**

In top mode, display time as `hh:mm` horizontally instead of stacked vertically. Replace the StyledText `text` binding:

```qml
StyledText {
    id: text

    anchors.horizontalCenter: parent.horizontalCenter

    horizontalAlignment: StyledText.AlignHCenter
    text: {
        if (Config.bar.position === "top")
            return Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "hh:mm");
        return Time.format(Config.services.useTwelveHourClock ? "hh\nmm\nA" : "hh\nmm");
    }
    font.pointSize: Appearance.font.size.smaller
    font.family: Appearance.font.family.mono
    color: root.colour
}
```

Also change the Column to a Row/Column switch. Simplest: wrap in a loader or use `flow` with `Grid`. But actually, `Column` with the text containing `\n` vs `:` handles the visual difference already. The Column container itself is fine for both — the icon and text just stack differently. For top bar, switch to Row:

Replace the root element:

```qml
Grid {
    id: root

    property color colour: Colours.palette.m3tertiary
    readonly property bool isTop: Config.bar.position === "top"

    columns: isTop ? -1 : 1
    rows: isTop ? 1 : -1
    flow: isTop ? Grid.LeftToRight : Grid.TopToBottom
    spacing: Appearance.spacing.small
```

- [ ] **Step 2: Commit**

```bash
git add modules/bar/components/Clock.qml
git commit -m "feat(clock): adapt layout for horizontal bar mode"
```

### Task 11: Update Workspaces for horizontal mode

**Files:**
- Modify: `modules/bar/components/workspaces/Workspaces.qml`
- Modify: `modules/bar/components/workspaces/Workspace.qml`

- [ ] **Step 1: Update Workspaces.qml layout**

Replace the inner `ColumnLayout` (line 60) with a direction-aware layout:

```qml
GridLayout {
    id: layout

    anchors.centerIn: parent
    columns: Config.bar.position === "top" ? -1 : 1
    rows: Config.bar.position === "top" ? 1 : -1
    flow: Config.bar.position === "top" ? GridLayout.LeftToRight : GridLayout.TopToBottom
    spacing: Math.floor(Appearance.spacing.small / 2)
```

Update the sizing — `implicitWidth` and `implicitHeight` should swap:

```qml
implicitWidth: Config.bar.position === "top" ? layout.implicitWidth + Appearance.padding.small * 2 : Config.bar.sizes.innerWidth
implicitHeight: Config.bar.position === "top" ? Config.bar.sizes.innerHeight : layout.implicitHeight + Appearance.padding.small * 2
```

Wait, `innerHeight` is the new config we added. Actually `innerHeight` defaults to the same as `innerWidth` (40). Let me use `Config.bar.sizes.innerHeight`.

Update MouseArea click handler — `childAt` axis should swap:

```qml
MouseArea {
    anchors.fill: layout
    onClicked: event => {
        const child = Config.bar.position === "top"
            ? layout.childAt(event.x, event.y)
            : layout.childAt(event.x, event.y);
        const ws = child.ws;
        if (Hypr.activeWsId !== ws)
            Hypr.dispatch(`workspace ${ws}`);
        else
            Hypr.dispatch("togglespecialworkspace special");
    }
}
```

Actually the `childAt` works the same way regardless — it takes x,y coordinates. No change needed there.

- [ ] **Step 2: Update Workspace.qml sizing**

In Workspace.qml, swap height ↔ width references for top mode. The key lines are:

Line 19 (`size` property) — in top mode, use `implicitWidth` instead of `implicitHeight`:

```qml
readonly property int size: Config.bar.position === "top"
    ? implicitWidth + (hasWindows ? Appearance.padding.small : 0)
    : implicitHeight + (hasWindows ? Appearance.padding.small : 0)
```

Line 25 layout preference:

```qml
Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
Layout.preferredHeight: Config.bar.position === "top" ? -1 : size
Layout.preferredWidth: Config.bar.position === "top" ? size : -1
```

Line 34 indicator height:

```qml
Layout.preferredHeight: Config.bar.position === "top" ? Config.bar.sizes.innerHeight - Appearance.padding.small * 2 : Config.bar.sizes.innerWidth - Appearance.padding.small * 2
```

- [ ] **Step 3: Commit**

```bash
git add modules/bar/components/workspaces/Workspaces.qml modules/bar/components/workspaces/Workspace.qml
git commit -m "feat(workspaces): adapt layout for horizontal bar mode"
```

### Task 12: Update StatusIcons.qml for horizontal mode

**Files:**
- Modify: `modules/bar/components/StatusIcons.qml`

- [ ] **Step 1: Switch ColumnLayout to GridLayout**

Replace the inner `ColumnLayout` (line 26):

```qml
GridLayout {
    id: iconColumn

    anchors.left: isTop ? undefined : parent.left
    anchors.right: isTop ? undefined : parent.right
    anchors.top: isTop ? parent.top : undefined
    anchors.bottom: isTop ? parent.bottom : parent.bottom
    anchors.bottomMargin: isTop ? 0 : Appearance.padding.normal
    anchors.rightMargin: isTop ? Appearance.padding.normal : 0

    columns: isTop ? -1 : 1
    rows: isTop ? 1 : -1
    flow: isTop ? GridLayout.LeftToRight : GridLayout.TopToBottom
    spacing: Appearance.spacing.smaller / 2
```

Add `isTop` property to root:

```qml
readonly property bool isTop: Config.bar.position === "top"
```

Update implicit sizing:

```qml
implicitWidth: isTop ? iconColumn.implicitWidth + Appearance.padding.normal * 2 - ... : Config.bar.sizes.innerWidth
implicitHeight: isTop ? Config.bar.sizes.innerHeight : iconColumn.implicitHeight + Appearance.padding.normal * 2 - ...
```

This is getting complex. Simpler approach — just adjust the sizing based on `isTop`:

```qml
implicitWidth: isTop
    ? iconColumn.implicitWidth + Appearance.padding.normal * 2
    : Config.bar.sizes.innerWidth
implicitHeight: isTop
    ? Config.bar.sizes.innerHeight
    : iconColumn.implicitHeight + Appearance.padding.normal * 2 - (Config.bar.status.showLockStatus && !Hypr.capsLock && !Hypr.numLock ? iconColumn.spacing : 0)
```

- [ ] **Step 2: Commit**

```bash
git add modules/bar/components/StatusIcons.qml
git commit -m "feat(statusIcons): adapt layout for horizontal bar mode"
```

### Task 13: Update ActiveWindow.qml for horizontal mode

**Files:**
- Modify: `modules/bar/components/ActiveWindow.qml`

- [ ] **Step 1: Adapt text rotation and sizing**

In top mode, the title text should be horizontal (no rotation). Update the `Title` component's transform:

```qml
transform: Config.bar.position === "top" ? [] : [
    Translate {
        x: Config.bar.activeWindow.inverted ? -implicitWidth + text.implicitHeight : 0
    },
    Rotation {
        angle: Config.bar.activeWindow.inverted ? 270 : 90
        origin.x: text.implicitHeight / 2
        origin.y: text.implicitHeight / 2
    }
]
```

In top mode, update the implicit size calculation:

```qml
implicitWidth: Config.bar.position === "top"
    ? icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin
    : Math.max(icon.implicitWidth, current.implicitHeight)
implicitHeight: Config.bar.position === "top"
    ? Math.max(icon.implicitHeight, current.implicitHeight)
    : icon.implicitHeight + current.implicitWidth + current.anchors.topMargin
```

Update `maxHeight` → `maxSize` to work for both:

```qml
readonly property int maxSize: {
    const otherModules = bar.children.filter(c => c.id && c.item !== this && c.id !== "spacer");
    const otherSize = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimWidth ?? curr.item.nonAnimHeight ?? (Config.bar.position === "top" ? curr.width : curr.height)), 0);
    const dimension = Config.bar.position === "top" ? bar.width : bar.height;
    return dimension - otherSize - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
}
```

And update `elideWidth` in TextMetrics:

```qml
elideWidth: root.maxSize - (Config.bar.position === "top" ? icon.width : icon.height)
```

- [ ] **Step 2: Commit**

```bash
git add modules/bar/components/ActiveWindow.qml
git commit -m "feat(activeWindow): adapt layout for horizontal bar mode"
```

---

## Chunk 5: User Config & Testing

### Task 14: Update user shell.json config

**Files:**
- Modify: `/home/loki/code/dotfiles/stow/caelestia/.config/caelestia/shell.json`

- [ ] **Step 1: Add position and btcPrice config**

Add to the `bar` section:

```json
"position": "top",
```

Add `btcPrice` entry to entries array (after `clock`):

```json
{ "id": "btcPrice", "enabled": true }
```

Add to `bar.status`:

```json
"showBtcPrice": true
```

- [ ] **Step 2: Commit in dotfiles repo**

```bash
cd ~/code/dotfiles
git add stow/caelestia/.config/caelestia/shell.json
git commit -m "feat(caelestia): enable top bar position and btc price widget"
```

### Task 15: Manual smoke test

- [ ] **Step 1: Test with position "left" (default)**

Ensure `shell.json` has `"position": "left"` and restart caelestia-shell. Verify:
- Bar appears on left side as before
- All components render correctly
- Popouts work
- Hover/drag interactions work
- BTC price shows (if enabled)

- [ ] **Step 2: Test with position "top"**

Set `"position": "top"` in `shell.json` and restart. Verify:
- Bar appears at top of screen horizontally
- Workspaces display in a row
- Clock shows `hh:mm` format
- Status icons in a row
- BTC price shows
- Panels (dashboard, launcher, etc.) don't overlap with bar
- Exclusive zone reserves top space correctly

- [ ] **Step 3: Final commit with any fixes**

```bash
cd /tmp/caelestia-shell-fork
git add -A
git commit -m "fix: polish top bar orientation and btc price widget"
```
