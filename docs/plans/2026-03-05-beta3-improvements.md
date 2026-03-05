# Beta 3 Improvements

This document outlines the implementation plan for the Beta 3 phase of the SoloOKRs app.

## 📍 Phase 1: Refining Objective State Flow and User Experience

1. **UI/UX Segue Control (Icon-only Segmented Control):**
   - The top of the Objective list changes to an Icon-only Segmented Control.
   - Default view: Shows only category status icons. Selected state shows category name and color.
   - Transition: Status switch triggers on click, with a sliding transition animation.
   - _Colors:_
     - Draft: `Color(red: 0.00, green: 0.48, blue: 1.00)`
     - Active: `Color(red: 0.20, green: 0.80, blue: 0.20)`
     - Achieved: `Color(red: 1.00, green: 0.58, blue: 0.00)`
     - Archived: `Color(red: 0.69, green: 0.32, blue: 0.87)`
2. **Seamless Achieved State Transitions:**
   - Only `active` objectives can transition to `achieved`.
   - To become `achieved`, an Objective **must have a review history** AND **all tasks across all its Key Results must be completed**. Otherwise, it can only transition to `archived`.

3. **Context Menu Contextual Action:**
   - Add "Mark as Achieved" to the right-click menu on the Objective list.
   - The action respects the constraints above (button is grayed out/disabled if unsatisfied).

4. **Objective List Swipe Actions:**
   - **Swipe Left:** "Analyze with AI" (Available across all statuses).
   - **Swipe Right:**
     - _Draft status:_ Edit, Active, Archived.
     - _Active status:_ Edit, New Review, Review History, Achieved, Archived.
     - _Achieved status:_ None.
     - _Archived status:_ Unarchived.
5. **Visual Enhancements:**
   - Add a `border-bottom` to separate each Objective in the list.
   - Relocate the completion progress percentage to display before the Objective title as a `circular-progress-bar`.
   - Remove the magnifying glass icon from objectives in the `draft` state.

6. **Toolbar Redesign:**
   - Change "Add Objective" to an Icon-only Toolbar Button (plus icon), placed on the left side of the toggle sidebar button.
   - Change "Add Key Result" to an Icon-only Toolbar Button (add new list icon), placed on the top-left of the KR toolbar.
   - Change "Add Task" to an Icon-only Toolbar Button (add new section icon), placed on the top-left of the Task toolbar.
   - The delete data function on the top toolbar of the Task list is moved to the Settings -> Subscription tab page.
   - The AI, MCP, SYNC statuses on the top toolbar of the Task list now use independent Icon-only Toolbar Buttons. Clicking each opens the corresponding Settings page.

## 📍 Phase 2: AI functions changed to real-time Streaming Response

Migrate the AI prompt-handling mechanics from batch-block execution to real-time Streaming Response for the following triggers:

1. **Analyze OKR**.
2. **Suggest Key Results**.
3. **Suggest Tasks**.
4. **Evaluate Key Result**.

> **Note:** The UI must provide a "Stop Generation" button to interrupt the streaming process.
