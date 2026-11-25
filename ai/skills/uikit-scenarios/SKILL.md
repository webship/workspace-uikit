---
name: uikit-scenarios
description: The phrases of the UIkit step pack (@webship-js/uikit-steps) by component, the traps found on real sites, and three example features that pass on the components demo site of the Webship Workspace. Use when writing or fixing webship-js scenarios for dialogs, side panels, drop-down menus and drops, accordions, tabs and switchers, the navigation bar, alerts, notifications, tooltips, slideshows, sliders, the lightbox, sticky menus, lists with a filter or form states on any site built on UIkit.
---

# uikit-scenarios

The step pack [`@webship-js/uikit-steps`](https://github.com/webship/uikit-steps) reads the
components of any site built on UIkit 3, in a container-based (DDEV by default) Webship Workspace or
anywhere else. Its steps name each component the way a person reads it and wait on the component's
own events and states. Read the installed definitions before you write a phrase:

```bash
grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/uikit-steps/tests/step-definitions/*.steps.js
```

A project gets the pack with `bash cmd-tools-testing.sh <site>` (a demo site of
`cmd-uikit-project.sh`) or `bash cmd-tools-testing.sh <site> --add-steps uikit` (any other site,
beside its platform's pack).

## The phrases, by component

| Component | Phrases |
| --- | --- |
| Dialog | `When I open the "Newsletter" dialog`, `When I open the "Newsletter" dialog with the "Subscribe to the newsletter" button`, `When I close the "..." dialog`, `When I press Escape in the "..." dialog`, `When I click outside the "..." dialog`, `When I press "Subscribe" in the "..." dialog`, `Then the "..." dialog should be shown`, `Then the "..." dialog should show "..."`, `Then no dialog should be shown` |
| Side panel | the same, with `side panel`: `When I open the "Menu" side panel` |
| Drop-down menu, drop | `When I open the "Account" drop-down menu`, `When I choose "Oldest first" from the "Sort by" drop-down menu`, `Then "Billing" should be disabled in the "Account" drop-down menu`, `When I hover over the "Share" button`, `Then the "..." drop-down menu should not be shown` |
| Accordion, toggled block | `When I expand the "Returns" panel`, `When I collapse the "..." panel`, `Then the "..." panel should be collapsed`, `Then the "..." panel should show "..."` |
| Navigation bar | `When I expand the navigation bar`, `When I collapse the "Shop" navigation bar`, `Then the "Shop" navigation bar should be collapsed`, `Then the navigation bar should show its toggle button` |
| Tabs, switcher | `When I switch to the "Security" tab`, `Then the "Profile" tab should not be active`, `Then the "Security" tab should show "..."` |
| Alert | `Then I should see a success alert "Your profile was updated."`, `When I dismiss the alert "..."`, `Then the alert "..." should be dismissible` |
| Notification | `Then I should see a success notification "The settings were saved."`, `Then the "..." notification should hide by itself`, `When I close the "..." notification` |
| Slideshow, slider | `When I go to the next slide of the "Gallery" slideshow`, `When I go to slide 3 of the "Gallery" slideshow`, `Then the "Gallery" slideshow should show slide 2 of 3`, `Then the "Products" slider should show "Pencil"`, `Then the "Highlights" slideshow should move to the next slide by itself` |
| Lightbox | `When I open the lightbox from the "The market on Saturday" picture`, `When I go to the next picture of the lightbox`, `Then the lightbox should show picture 3 of 4`, `Then the lightbox should show "The old bridge"`, `When I close the lightbox` |
| Tooltip | `When I hover over the "Save the draft" button`, `Then the "..." tooltip should be shown`, `Then no tooltip should be shown` |
| Form states | `Then the "Email" field should be shown as invalid`, `Then the "Email" field should show the message "..."`, `Then 3 fields should be shown as invalid` |
| Menus, pagination, breadcrumbs, badges | `Then "Overview" should be active in the menu`, `Then the current page of the pagination should be "2"`, `Then the "Previous" link of the pagination should be disabled`, `Then the breadcrumb should read "Home > Products > Notebooks"`, `Then the "Messages" button should show the badge "5"` |
| Sticky menu, filter | `Then the "Section menu" should stick to the top of the window`, `When I filter the "Colours" list by "Red"`, `Then the "Colours" filtered list should show "Notebook"`, `Then the filtered list should show 5 items` |
| Loading | `Then I should see a loading spinner`, `When I wait for the loading spinner to disappear`, `Then the "Upload" progress bar should reach 100%` |
| The page | `Then the page should use the components script at version "3"`, `When I wait for the transitions to finish` |

webship-js's own steps do the rest: `I press "..."`, `I click the "..." button`, `I fill in "..." with
"..."`, `I press the key "ArrowDown"`, `I set the viewport to the "xs" breakpoint`, `I scroll down
800`, `the page should have no serious accessibility violations`.

## Traps found on real sites

- **An event is not the end of the movement.** A side panel that reveals under the page sends
  `shown` while the page still slides aside; the lightbox sends `shown` before its picture has slid
  in; a menu of a navigation bar with a dropbar grows on after its `shown`. The pack waits for the
  movement itself: never add a `wait` after its steps.
- **A menu that opens under the pointer closes on a click.** With `mode: hover`, a click after the
  hover closes the menu again. Open it with `When I open the "..." drop-down menu` or `When I hover
  over the "..." button`, not with a click of webship-js's own.
- **A navigation bar's side panel covers its own toggle.** On a narrow screen the toggle opens the
  links in a side panel whose overlay lies over the toggle: `When I collapse the navigation bar`
  closes the panel with its close button, as a person does.
- **A page swapped in with htmx.** The theme UI Suite UIkit boosts its links: a link swaps the next
  page in without loading it, and the components found before are gone. The steps wait for the swap
  and for the new components; a step of your own that keeps an element across a link must find it
  again.
- **A short notification can be gone before the next step.** webship-js's own steps let the page
  settle after a click, longer while a timer of the page is pending: a notification that hides in
  less than about two seconds can be gone before `should be shown` looks. Assert that it hides by
  itself instead.
- **Two tab bars that drive each other.** The default `connect` of a tab bar or a switcher takes
  every switcher among the siblings that follow it: two bars in one block switch both contents.
- **The theme's own markup.** On a Drupal site with UI Suite UIkit, the site's messages are alerts
  with a close button, a field with an error carries `uk-form-danger` and `aria-invalid`, the pager
  is a pagination named "Pagination", and there are no local tasks and no breadcrumb by default.

## Examples

Three features that pass on the components demo site (`bash cmd-uikit-project.sh <site>
--install`), copied into `tests/features/` of the project:

- `examples/dialogs-and-menus.feature`: a dialog, one set to stay open, a side panel, a menu choice, the items of a menu.
- `examples/panels-tabs-and-slides.feature`: an accordion, tabs, a slideshow, the lightbox, the navigation bar.
- `examples/forms-and-feedback.feature`: form states, an alert, a notification, a spinner and a progress bar.

## The book

For any automated functional testing in this work (a Gherkin feature, a step definition, choosing a
step, a test run and its failures), read the book *Automated Functional Testing Recipes* first.

- **Where.** Use the first that exists: `.claude/automated-functional-testing-recipes/` in the project,
  `~/.claude/automated-functional-testing-recipes/` (installed by webship/webship-js-ai-agent,
  webship/webship-js-skills or webship/ai-agents), or
  https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
- **How.** Its `README.md` first, then the chapter that matches the task (one file per chapter,
  named by its subject), not the single complete file.
- **Which wins.** The installed webship-js package and the step pack are the source of truth for
  step phrasing. When they differ from the book, follow them and say so.
- **For UIkit.** Start with `ch08-modal-dialog-testing.md` (dialogs, drawers, notifications,
  tooltips and popovers), `ch07-waiting-dynamic-content.md` (why a wait names its signal, never a
  time), `ch13-responsive-mobile-testing.md` (the navigation bar on a narrow screen) and
  `ch21-when-tests-go-bad.md` (flaky, brittle and slow scenarios).
