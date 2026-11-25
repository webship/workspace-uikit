Write and run the webship-js scenarios of the components of one site of the workspace.

The launch command below is for Claude Code, the default; the text between the triple quotes can be given to another AI CLI as it is.

```
claude --permission-mode bypassPermissions """
Write webship-js scenarios for the components of the site <site> (its <page> page) and run them
# ~/workspace/<dev|test|sandboxes|demos> · https://<site>.ddev.site · container-based (DDEV by default)
# components: dialogs, side panels, drop-down menus, accordions, tabs and switchers, the navigation bar, alerts, notifications, tooltips, slideshows, sliders, the lightbox, sticky menus, lists with a filter, form states
# nothing on the host: no node, npm or npx outside the site's container
# before writing: the book Automated Functional Testing Recipes (its README.md, then ch08-modal-dialog-testing.md and ch07-waiting-dynamic-content.md), from .claude/automated-functional-testing-recipes/ in the project, ~/.claude/automated-functional-testing-recipes/ or https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes

1. bash cmd-tools-testing.sh <site>
   then, unless its cucumber.js already names @webship-js/uikit-steps:
   bash cmd-tools-testing.sh <site> --add-steps uikit
2. Open https://<site>.ddev.site<page> in the Playwright MCP browser, in a tab of your own, and open and close every
   component by hand once: note the name a person reads for each (a dialog's title, a side panel's heading, a menu's
   button, an accordion item's title).
3. Write tests/features/components.feature from the installed phrases only
   (grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/uikit-steps/tests/step-definitions/*.steps.js):
   no fixed wait, no library or platform name in a step, no account created.
4. bash cmd-tools-testing.sh <site> --dry-run --path tests/features/components.feature
5. bash cmd-tools-testing.sh <site> --run --path tests/features/components.feature

If a command fails, show the line that failed and stop. A failing scenario is a result: say what the page did.
When the feature is green: how many scenarios and steps passed, and which components the page has that no scenario covers yet.
"""
```
