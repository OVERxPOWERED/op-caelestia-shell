# Refactoring Plan: Control Center Panes

## Overview

After analyzing the last 30 commits, I've identified significant code duplication and opportunities for modularization in the control center panels. This plan focuses on extracting common patterns into reusable components.

## Key Refactoring Opportunities

### 1. Details Component Consolidation

**Files affected:** `modules/controlcenter/network/Details.qml`, `modules/controlcenter/ethernet/EthernetDetails.qml`

**Issue:** Both files share identical structure:

- Header with icon and title
- Connection status section
- Properties section
- Connection information section (IP, subnet, gateway, DNS)

**Solution:** Create `components/ConnectionDetails.qml` that accepts:

- Device/network object
- Icon name
- Title property path
- Details source (wirelessDeviceDetails vs ethernetDeviceDetails)

**Impact:** Reduces ~200 lines of duplication.

### 2. ToggleButton Component Extraction

**Files affected:** `modules/controlcenter/network/NetworkList.qml`, `modules/controlcenter/ethernet/EthernetList.qml`

**Issue:** Both files define identical `ToggleButton` component (lines 228-301 in NetworkList, 170-243 in EthernetList).

**Solution:** Move to `components/controls/ToggleButton.qml` and import in both files.

**Impact:** Eliminates ~70 lines of duplication.

### 3. Switch/SpinBox Row Components

**Files affected:** `modules/controlcenter/appearance/AppearancePane.qml`, `modules/controlcenter/taskbar/TaskbarPane.qml`

**Issue:** Repeated patterns for:

- Switch rows (label + StyledSwitch)
- SpinBox rows (label + CustomSpinBox)
- Same layout, spacing, and styling

**Solution:** Create:

- `components/controls/SwitchRow.qml` - label + switch with config save callback
- `components/controls/SpinBoxRow.qml` - label + spinbox with config save callback

**Impact:** Reduces ~30-40 lines per row instance (20+ instances total).

### 4. Font List Delegate Consolidation

**Files affected:** `modules/controlcenter/appearance/AppearancePane.qml`

**Issue:** Three nearly identical font list implementations (Material, Mono, Sans) with only the property binding differing.

**Solution:** Create `components/FontList.qml` that accepts:

- Current font property
- Save callback function
- Title text

**Impact:** Reduces ~150 lines of duplication.

### 5. List Item Selection Pattern

**Files affected:** Multiple list delegates across panes

**Issue:** Repeated pattern for selected item highlighting:

- Color with alpha based on selection
- Border width/color based on selection
- StateLayer click handler

**Solution:** Create `components/SelectableListItem.qml` wrapper that handles selection styling.

**Impact:** Reduces ~10-15 lines per list delegate.

## Implementation Order

1. **ConnectionDetails consolidation** (medium impact)
2. **FontList consolidation** (low-medium impact)
3. **SelectableListItem pattern** (nice-to-have, lower priority)

## Files to Create

- `components/controls/SelectableListItem.qml`
- `components/ConnectionDetails.qml`
- `components/FontList.qml`

## Completed Items

- ✅ `components/controls/CollapsibleSection.qml` - DONE
- ✅ `components/controls/SwitchRow.qml` - DONE
- ✅ `components/controls/SpinBoxRow.qml` - DONE
- ✅ `components/controls/ToggleButton.qml` - DONE

## Estimated Impact

- **Lines removed:** ~400-500 lines of duplicated code (from remaining items)
- **Maintainability:** Significantly improved - changes to common patterns only need to be made once
- **Readability:** Panes become more declarative and easier to understand
- **Testability:** Reusable components can be tested independently

## Completed Refactoring

- **Lines removed so far:** ~1300+ lines of duplicated code
- **Components created:** CollapsibleSection, SwitchRow, SpinBoxRow, ToggleButton