# @webship.co/workspace-uikit

UIkit for the [Webship Workspace](https://github.com/webship/workspace) dashboard: a builder that
serves the components demo site of the [UIkit step pack](https://github.com/webship/uikit-steps) in a
container (a page for every component, with the markup of UIkit's own test pages), the step pack
wired into the testing setup of such a site, and its AI items — two agents, a skill, a command and two
prompts for testing and building UIs made of the components — each listed in the workspace folder of
its kind.

The components are not a platform: any site may use them, whatever its CMS. So the plugin gives a site
with every component on it, and the step pack goes into any other project with the core's own command:
`bash cmd-tools-testing.sh <project> --add-steps uikit`, beside the platform's pack of a Drupal site
with the theme UI Suite UIkit, or of a WordPress or Joomla site whose theme is built on the components
(Webship Workspace 1.0.35 or newer, which lists the pack among its step packs).

The workspace is container-based (DDEV by default): a demo site is a row like any other, so the row
menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it; what does not
apply to a static site is listed under
[What is different from a platform](#what-is-different-from-a-platform). The builder builds on DDEV by
default, and with `--runtime` on Docker Compose, Podman or a Kubernetes cluster: see
[Runtimes](#runtimes).

The plugin is made from the Bootstrap plugin,
[`@webship.co/workspace-bootstrap`](https://github.com/webship/workspace-bootstrap), which serves its
own step pack's demo site the same way.

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require uikit --with-needs     # npm install into the dashboard
bash core/scripts/plugins.sh --activate uikit --with-needs    # plugins.uikit in settings.yml
bash core/scripts/plugins.sh --install uikit                  # the builder, functions, args, AI items
bash core/scripts/plugins.sh --configure uikit                # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an AI item you edited stays.

Everything the plugin carries lands in the folder it belongs to, when that folder is an active
workspace folder:

| What | Lands in |
| --- | --- |
| `cmd-uikit-project.sh` | every active sites folder: `dev/`, `test/`, `sandboxes/`, `demos/` |
| The agents `uikit-ui-builder`, `uikit-tester` | `ai-agents/` |
| The skill `uikit-scenarios` | `ai-skills/` |
| The command `/uikit-test` | `ai-commands/` |
| The prompts `uikit-build-and-test`, `uikit-scenarios-for-a-site` | `ai-prompts/` |

There they are listed like any other item of the folder, and installed into Claude Code from there.

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder, for the builder: `dev`, `test`, `sandboxes`, `demos` (`dev` is the one added when none is there). The folder also carries `cmd-tools-testing.sh` and the Users tools this plugin's hooks answer to.
- `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`: the AI folders its agents, its skill, its command and its prompts are placed in.

`--require` says so, `--activate` and `--install` stop until the workspace has them, and `--with-needs` adds what is missing first:

```bash
bash core/scripts/plugins.sh --activate uikit --with-needs   # dev and the four AI folders are required, activated and installed first
bash core/scripts/plugins.sh --install uikit
```

Everything the builder runs for a site runs in the site's own container, through the container tool
the workspace already needs; the plugin asks for no command of its own on the machine.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-uikit-project.sh` | The builder, in the Build list as **UIkit (components demo site)**, installed into every sites folder |
| `scripts/functions/fun-uikit.sh` | The bash functions behind it, sourced by bootstrap once installed; the names the core's tools look for (`set_uikit_users`, `add_uikit_users`, `cancel_uikit_users`, `testing_configure_uikit`) |
| `scripts/args/arg-uikit.sh` | Its argparse; the Build form draws the builder's flags from it |
| `testing/site.feature` | The first feature a demo site gets when testing is set up |
| `ai/agents/uikit-ui-builder.md` | The agent that builds and checks UIs made of the components, with the demo site as its reference |
| `ai/agents/uikit-tester.md` | The agent that writes and runs scenarios with the step pack, on a demo site or on any other site |
| `ai/skills/uikit-scenarios/` | The skill: the step pack's phrases by component, the traps found on real sites, three example features |
| `ai/commands/uikit-test.md` | The slash command `/uikit-test <site>`: add the pack when missing, match every step, run, report |
| `ai/prompts/uikit-build-and-test.md`, `uikit-scenarios-for-a-site.md` | Two prompts: whole launch commands for a new session |
| `src/index.ts` | `register(api)`: what the assistant is told about the components here |
| `features/uikit.feature` | Scenarios for the dashboard's own browser suite |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## What is different from a platform

| | WordPress (a platform) | UIkit |
| --- | --- | --- |
| What is built | A WordPress site | The components demo site: the `demo-site/` folder of the step pack's repository |
| Project | `--project-type=wordpress` | `--project-type=php --docroot=site`, no database: the web server serves static pages (on Docker Compose, Podman and Kubernetes the core's php stack: Apache, and no database service) |
| Recognised by | The project type | On DDEV a file the builder writes, `.ddev/config.uikit.yaml` (it also records where the pages came from); on another runtime its claim, `platform: uikit` in the `x-webship` block of `compose.yaml` |
| Getting the code | `wp core download` | `git clone` of the step pack's repository, in the web container |
| Accounts | WP-CLI | None: a static site. `--add-users` is taken and adds nothing |
| Testing | The WordPress pack | The UIkit pack; any other site gets it with `--add-steps uikit` |

## The commands

Run it from a sites folder. `--help` is safe.

### Serve the demo site

```bash
cd ~/workspace/dev
bash cmd-uikit-project.sh uksite --install                     # the pages of the step pack's 2.0.x branch
bash cmd-uikit-project.sh uksite --install --ref 2.0.0         # a tag (or another branch) of the step pack
bash cmd-uikit-project.sh uksite --install --runtime docker    # on Docker Compose instead of DDEV
```

| Flag | What it does |
| --- | --- |
| `--install` | Start the site and check that it answers at its address (`https://<name>.ddev.site` on DDEV) |
| `--runtime ddev\|docker\|podman\|kubernetes` | The container runtime to build on (default: DDEV, or `container.runtime` of `settings.yml`); see [Runtimes](#runtimes) |
| `--source <git url>` | The repository the demo site is taken from (default: the step pack's) |
| `--ref <branch or tag>` | A branch or a tag of that repository (default `2.0.x`) |
| `--add-users` | Taken so that every builder accepts the same flags; a static site has no accounts |
| `--launch` | Open the site in a browser when it is ready |

The builder deletes a project of the same name first, then makes a container with a web server and
no database, takes the demo site's pages from the step pack's repository and, with `--install`,
starts it and checks that it answers: about half a minute on DDEV, a few seconds on Docker Compose
once the stack's image is built.

### Test a site

On a demo site:

```bash
bash cmd-tools-testing.sh uksite                                  # webship-js, the step pack, a first feature
bash cmd-tools-testing.sh uksite --run --path tests/features/site.feature
```

The testing setup adds `@webship-js/uikit-steps` to the project, lists its step definitions in
`cucumber.js`, and writes `tests/features/site.feature` (the components script, a dialog, an
accordion, a menu, the navigation bar on a narrow screen). It changes nothing in a project that is
not a demo site.

On any other site whose theme is built on the components (Webship Workspace 1.0.35 or newer, which
lists the pack among its step packs):

```bash
bash cmd-tools-testing.sh mysite                      # webship-js and the platform's own pack
bash cmd-tools-testing.sh mysite --add-steps uikit    # the component steps, beside it
bash cmd-tools-testing.sh mysite --run
```

The component steps share no phrase with a platform's pack, so the core puts them in the same
profile; `--remove-steps uikit` takes out exactly what `--add-steps` put in. A theme that swaps its
pages in with htmx (UI Suite UIkit does) needs nothing more: the steps wait for the swap.

### Runtimes

The commands are the same on every runtime: the builder speaks DDEV's verbs, and on another runtime
the core's layer (Webship Workspace 1.0.32 or later, webship/workspace#694) gives each verb its meaning
there. The demo site gets the core's php stack, Apache serving `site/`, with no database service. On
Kubernetes that needs core 1.0.35 or newer (webship/workspace#884): before it, a project without a
database waited for one there (webship/workspace#883).

| Runtime | The address of the site | Proven with this builder |
| --- | --- | --- |
| DDEV (the default) | `https://<name>.ddev.site` | Built in 23 s, the pages answer |
| Docker Compose (`--runtime docker`) | `http://127.0.0.1:<port>`, a free port kept in `compose.yaml` | Built in 4 s (the stack's image already built), the pages answer; the testing setup and a run: the first feature (5 scenarios) and, with the skill's three examples, 20 scenarios and 98 steps; the plugin's features on the dashboard |
| Podman (`--runtime podman`) | `http://127.0.0.1:<port>` | Built in 85 s with the stack's image, the pages answer, the files are the host user's; the plugin's features on the dashboard |
| Kubernetes (`--runtime kubernetes`) | `http://<node address>:<NodePort>` | On kind (Kubernetes 1.37.0) with core 1.0.35 or newer (webship/workspace#884): built in 13 s, the pages answer; the plugin's features on the dashboard |

A project of the builder is known by DDEV's file on DDEV and by its claim on another runtime, so the
testing setup, the Users tools (which say there are no accounts) and the dashboard's row work the same
on each. Lando and Docksal are
runtimes of the workspace too, not proven with this builder yet: it says so and stops, before
anything is made.

### Users

A static site has no accounts. `cmd-tools-add-users.sh <name> uikit` and
`cmd-tools-cancel-users.sh <name> uikit` say so and change nothing.

## The AI items

| Item | Kind | What it is for |
| --- | --- | --- |
| `uikit-ui-builder` | agent | Builds and checks UIs made of the components: names a person and the steps can read, the options that matter on real sites, the components a page sets up with its script, the demo site as a reference |
| `uikit-tester` | agent | Writes and runs scenarios with the step pack on any site: explores in the browser first, never sleeps, never names a library or platform in a step |
| `uikit-scenarios` | skill | The step pack's phrases by component, the traps found on real sites, three example features that pass on the demo site |
| `/uikit-test <site>` | command | Adds the pack when missing, matches every step, runs, reports |
| `uikit-build-and-test` | prompt | Serves a demo site and proves it with its first feature |
| `uikit-scenarios-for-a-site` | prompt | Writes and runs the component scenarios of one site of the workspace |

Every item says the workspace is container-based (DDEV by default), and the agents and the skill
send the reader to the book *Automated Functional Testing Recipes* first.

## Develop it

```bash
npm install
npm test        # builds, then the unit tests: the manifest, the scripts, the AI items, the needs
npm run lint    # the TypeScript compiler, no output
```

CI runs the same on Node.js 24 and 26, checks that every shell script parses, and runs the plugin's
webship-js features against a dashboard with the plugin installed (the reusable workflow
`webship/workspace/.github/workflows/plugin-browser-suite.yml`). Before the features it builds the
site the manifest names (`featuresSite`: `cmd-uikit-project.sh ci-uikit --install --runtime docker`),
so the scenarios of `features/uikit-runtimes.feature` tagged `@needs-runtime-docker` drive a real demo
site on Docker Compose; the Podman and Kubernetes ones run where such a site is. `tests/fixtures/step-definitions.txt`
holds the step definitions of the step pack at the version the testing hook pins and of webship-js,
read from their packages: every phrase an AI item shows must match one of them.
