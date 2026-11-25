/**
 * UIkit for Webship Workspace: a plugin for the components of UIkit, which any site may use.
 *
 * What the package carries is placed by the installer from the manifest: the builder in the sites
 * folders, its functions and argparse under core/scripts/plugins/uikit/, its AI items (ai/) in the
 * AI folders. The builder serves the components demo site of the step pack
 * (@webship-js/uikit-steps) in a container, so the pack and a person have a site with every
 * component on it. The pack itself goes into any other project with the core's
 * `cmd-tools-testing.sh <project> --add-steps uikit`. The dashboard needs nothing drawn for it:
 * the builder is in the Build list because it is a cmd-*-project.sh, the row menus are the core's,
 * the AI items are listed like any other. What register() adds is what the assistant is told.
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from the
 * dashboard's own files, so it can be installed from npm and removed without a trace.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';

/** The plugin's name, which its functions are named after. */
export const PLATFORM = 'uikit';

/** The commands the installer places in every sites folder. */
export const COMMANDS = ['cmd-uikit-project.sh'];

/** The agents the installer places in the AI Agents folder. */
export const AGENTS = ['uikit-ui-builder', 'uikit-tester'];

/** The skill the installer places in the AI Skills folder (a folder each, with its SKILL.md). */
export const SKILLS = ['uikit-scenarios'];

/** The slash command the installer places in the AI Commands folder. */
export const AI_COMMANDS = ['uikit-test'];

/** The prompts the installer places in the AI Prompts folder: whole launch commands for a new session. */
export const PROMPTS = ['uikit-build-and-test', 'uikit-scenarios-for-a-site'];

/** What the assistant is told about UIkit in this workspace. */
export function assistantContext(): string {
  return [
    'UIkit (a plugin, @webship.co/workspace-uikit): its builder serves the components demo site of the step pack',
    '@webship-js/uikit-steps in a container, with `bash cmd-uikit-project.sh <name> --install` from a sites folder',
    '(dev, test, sandboxes, demos): a page for every component (dialogs, side panels, drop-down menus, accordions, tabs and',
    'switchers, the navigation bar, alerts, notifications, tooltips, slideshows, sliders, the lightbox, a sticky menu, a list',
    'with a filter, form states ...) at https://<name>.ddev.site. It is static: there is no database and there are no accounts.',
    '`--runtime docker`, `podman` or `kubernetes` builds it on Docker Compose, Podman or a Kubernetes cluster instead of DDEV,',
    'at the address that runtime gives (the build prints it).',
    '`bash cmd-tools-testing.sh <name>` sets up webship-js with the step pack on such a site; on any other project that uses',
    'the components (a Drupal site with the theme UI Suite UIkit, a WordPress or Joomla site with a theme built on them),',
    '`bash cmd-tools-testing.sh <project> --add-steps uikit` adds the pack beside the platform\'s own.',
    `For building or checking a UI made of the components, hand over to the agent \`${AGENTS[0]}\`; for testing one, to \`${AGENTS[1]}\`.`,
    `The plugin also places the skill ${SKILLS.map((a) => `\`${a}\``).join(', ')} (the step pack's phrases, by component) in ai-skills/,`,
    `the command ${AI_COMMANDS.map((a) => `\`/${a} <site>\``).join(', ')} in ai-commands/ and the prompts ${PROMPTS.map((a) => `\`${a}\``).join(' and ')} in ai-prompts/.`,
    'Never run node, npm or npx on the host for a project.',
  ].join(' ');
}

export function register(api: PluginApi): void {
  api.addAssistantContext(assistantContext);
}
