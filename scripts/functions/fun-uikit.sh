#!/usr/bin/env bash

# UIkit for the Webship Workspace: serve the components demo site of the UIkit step pack in a
# container, and wire the step pack into the testing setup of such a site.
#
# Placed by `plugins.sh --install uikit` in core/scripts/plugins/uikit/functions/, where bootstrap
# sources it after the core's own functions. Everything runs in the project's container (DDEV by
# default), never on the host: the demo site is a folder of static pages (site/, taken from the
# demo-site/ folder of the step pack's repository), served by the container's web server. There is
# no database.
#
# The runtimes: a demo site is built on DDEV, or with --runtime on Docker Compose, Podman or a
# Kubernetes cluster. The commands are the same on each: `ddev <verb>` is DDEV itself on a DDEV
# project, and on another runtime the core's layer (fun-runtime.sh) gives the verb its meaning
# there, with its php stack: Apache serves site/, and there is no database. What differs is in
# three places, each behind uikit_runtime: the address (uikit_url), the mark of a project of this
# builder (a file on DDEV, the claim of the x-webship block elsewhere), and how a project is known
# (uikit_is_project).
#
# The demo site is static: it has no accounts. The components are not a platform and the container
# tool has no project type for them, so a project of this builder is recognised by its mark
# (.ddev/config.uikit.yaml on DDEV, `platform: uikit` in compose.yaml elsewhere), and four names are
# the ones the core's tools look for:
#   set_uikit_users          an empty list: there are no accounts  (cmd-tools-add-users.sh <project> uikit)
#   add_uikit_users          says so, and adds nothing             (the same tool)
#   cancel_uikit_users       says so, and removes nothing          (cmd-tools-cancel-users.sh <project> uikit)
#   testing_configure_uikit  the step pack in the testing stack    (cmd-tools-testing.sh <project>)
#
# Any other project whose theme is built on the components gets the step pack from the core:
#   cmd-tools-testing.sh <project> --add-steps uikit

# The step pack a demo site is tested with, and the release line it is required at.
readonly UIKIT_STEPS_PACKAGE='@webship-js/uikit-steps';
readonly UIKIT_STEPS_VERSION='^2.0.0';

# Where the demo site lives in the web container.
readonly UIKIT_SITE='/var/www/html/site';

# The runtimes a demo site is built on. Lando and Docksal are runtimes of the workspace too, not
# proven for this builder yet: it says so and stops, rather than build there by accident.
readonly UIKIT_RUNTIMES='ddev docker podman kubernetes';

# A static site has no accounts: the list is empty.
function set_uikit_users() {
  users=();
}

# The runtime of the project in this folder, or of a new build (--runtime, else the workspace's
# setting, else DDEV). A core without the runtime layer has DDEV only.
function uikit_runtime() {
  if declare -f runtime_of > /dev/null ; then runtime_of ; else echo 'ddev' ; fi
}

# The address of the site in this folder: https://<name>.ddev.site on DDEV, http://127.0.0.1:<port>
# on Docker Compose and Podman, the node's address and a port on Kubernetes. Asked after `ddev config`.
function uikit_url() {
  if declare -f rt_url > /dev/null ; then rt_url ; else echo "https://${PROJECT_NAME}.ddev.site" ; fi
}

# Is this folder a project of the UIkit builder? On DDEV the builder leaves .ddev/config.uikit.yaml
# in it; on another runtime it claims the project (`platform: uikit` in the x-webship block).
function uikit_is_project() {
  local project_path="$1";
  if declare -f rt_is_platform > /dev/null ; then rt_is_platform "${project_path}" uikit ; return $? ; fi
  [ -f "${project_path}/.ddev/config.uikit.yaml" ] ;
}

# What the container tool is told about the site: the web server serves the pages of site/ as they
# are. The file also marks the project as one of this builder.
function uikit_write_ddev_config() {
  local project_path="$1" source="$2" ref="$3";
  mkdir -p "${project_path}/.ddev" || return 1 ;
  cat > "${project_path}/.ddev/config.uikit.yaml" <<YAMLEOF
# The components demo site of the UIkit step pack. Written by the UIkit builder of the workspace;
# build again rather than editing by hand.
# source: ${source}${ref:+ (${ref})}
# The web server serves the static pages of site/: there is no database.
YAMLEOF
}

# Wait until the web server answers with the demo site's home page.
function uikit_wait() {
  local attempt ;
  for attempt in $(seq 1 30) ; do
    if ddev exec "curl -fsS -o /dev/null http://127.0.0.1/index.html" > /dev/null 2>&1 ; then
      return 0 ;
    fi
    sleep 2 ;
  done
  echo "The web server of the project does not answer with the demo site." ;
  return 1 ;
}

# Build a demo site from nothing: the container, the pages of the step pack, and with --install the
# site started and checked.
function uikit_build() {
  trim_project_name ;
  local base_url runtime ;
  runtime="$(uikit_runtime)" ;
  if [ "${RUNTIME:-_none_}" != '_none_' ] && [ "${RUNTIME}" != "${runtime}" ] ; then
    echo "--runtime ${RUNTIME} needs a Webship Workspace with the container runtimes (webship/workspace#694): update the workspace, or build on DDEV." ;
    exit 1 ;
  fi
  case " ${UIKIT_RUNTIMES} " in
    *" ${runtime} "*) ;;
    *) echo "The demo site builds on ddev, docker, podman or kubernetes, not on ${runtime} yet: build with --runtime ddev (or docker, podman, kubernetes)." ; exit 1 ;;
  esac
  local source="${SOURCE:-${site_source}}" ;
  local ref="${REF:-${site_source_ref:-}}" ;
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}" ;
  local docroot="site" ;

  cd ${WORKSPACE_ROOT}/${doc_name} || exit 1 ;

  drop_database ;
  rm -rf "${PROJECT_NAME:?}" ;
  mkdir -p "${PROJECT_NAME}/site" ;
  cd "${project_path}" || exit 1 ;

  # A web server and no database: the site is static pages, served as they are.
  ddev config --project-type=php --docroot="${docroot}" --project-name=${PROJECT_NAME} \
    --omit-containers=db --nodejs-version=$(ddev_nodejs_version) || exit 1 ;
  # The mark of a project of this builder: DDEV's own file on DDEV, the claim of the x-webship block on
  # another runtime (what rt_is_platform reads on each).
  if [ "${runtime}" = 'ddev' ] ; then
    uikit_write_ddev_config "${project_path}" "${source}" "${ref}" || exit 1 ;
  else
    { declare -f rt_claim > /dev/null && rt_claim uikit ; } \
      || { echo "The project could not be marked as a demo site of the UIkit builder (rt_claim, webship/workspace#694)." ; exit 1 ; } ;
  fi
  ddev_up start -y || exit 1 ;
  # The address is the runtime's to say, once the project is configured: never a written ddev.site.
  base_url="$(uikit_url)" ;

  echo "Getting the demo site: ${source}${ref:+ at ${ref}}" ;
  ddev exec "rm -rf /tmp/components-demo && git clone --quiet --depth 1 ${ref:+--branch '${ref}'} '${source}' /tmp/components-demo" \
    || { echo "The demo site could not be cloned from ${source}${ref:+ at ${ref}}." ; exit 1 ; } ;
  ddev exec "test -f /tmp/components-demo/demo-site/index.html && cp -a /tmp/components-demo/demo-site/. ${UIKIT_SITE}/ && rm -rf /tmp/components-demo" \
    || { echo "${source} has no demo-site/ folder with an index.html." ; exit 1 ; } ;
  if [ ! -f "${project_path}/${docroot}/index.html" ] ; then
    echo "The demo site has no home page (${docroot}/index.html)." ;
    exit 1 ;
  fi
  # The demo site's own DDEV project (demo-site/.ddev, for a person who starts it by hand) is not this
  # project's: it goes, so that nothing in site/ names another project.
  rm -rf "${project_path:?}/${docroot:?}/.ddev" ;

  [ "${ADD_USERS}" == 'yes' ] && echo "--add-users: the demo site is static and has no accounts; nothing is added." ;

  if [ "${INSTALL}" == 'yes' ] ; then
    uikit_wait || exit 1 ;
    echo "${doc_name} ${PROJECT_NAME} is served: the components demo site, $(find "${project_path}/${docroot}" -maxdepth 1 -name '*.html' | wc -l) pages.";
    echo "Go to ${base_url}";
  else
    ddev stop ;
    echo "${doc_name} ${PROJECT_NAME} is ready: the components demo site.";
    if [ "${runtime}" = 'ddev' ] ; then
      echo "Serve it with: cd ${PROJECT_NAME} && ddev start   (or build with --install)";
    else
      echo "Serve it with Start in its row of the dashboard (or build with --install)";
    fi
  fi

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# A static site has no accounts: there is nothing to add, and nothing to remove.
function add_uikit_users() {
  echo "The components demo site is static: it has no accounts, so there are none to add." ;
}

function cancel_uikit_users() {
  echo "The components demo site is static: it has no accounts, so there are none to remove." ;
}

# The step pack in the testing stack of a demo site. The core's testing_configure calls this in the
# project folder once webship-js is scaffolded and before the dependencies are installed; for a
# project that is not a demo site of this builder it changes nothing (any other project gets the
# pack with the core's --add-steps).
#
# It adds the pack to package.json, lists its step definitions in cucumber.js after webship-js's
# own, and writes a first feature when the project has none of its own. There is no users
# registry: the site has no accounts. Every part is skipped when it is already there, so a second
# run adds what the first missed and never resets a suite. The suite is the project's (its
# package.json, cucumber.js and tests/ are next to site/, not in it).
function testing_configure_uikit() {
  local project_path="$1";
  uikit_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  UIkit: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  echo "Adding the UIkit step pack (${UIKIT_STEPS_PACKAGE} ${UIKIT_STEPS_VERSION}).";

  python3 - "${project_path}" "${UIKIT_STEPS_PACKAGE}" "${UIKIT_STEPS_VERSION}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version = sys.argv[1:4]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=2) + '\n')
    print('  package.json: %s %s' % (pack, version))

# cucumber.js: the pack's step definitions after webship-js's own.
cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/*.js'," % pack
    core = re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if core:
        src = src[:core.end()] + '\n' + core.group(1) + line + src[core.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

if src != before:
    open(cucumber_file, 'w').write(src)
PYEOF

  # A first feature, when the project has none for the site yet: the components script, a dialog, an
  # accordion, a menu and the navigation bar on a narrow screen.
  local feature="${WORKSPACE_SCRIPTS}/plugins/uikit/site.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/site.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/site.feature" \
      && echo "  tests/features/site.feature: a first feature for the site" ;
  fi
}
