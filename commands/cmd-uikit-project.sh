#!/usr/bin/env bash

# workspace-name: UIkit (components demo site)

# Installed by the UIkit plugin (plugins.sh --install uikit); __WORKSPACE__ is the workspace it was installed into.
#
# Serve the components demo site of the UIkit step pack in a container: a page for every
# component, with the markup of UIkit's own test pages. With --install the site is started and
# checked. A static site: it has no database and no accounts. The workspace is container-based
# (DDEV by default, at https://<name>.ddev.site); --runtime docker, podman or kubernetes builds it on
# Docker Compose, Podman or a Kubernetes cluster instead, at the address that runtime gives.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Where the demo site comes from: the step pack's repository and its branch.
site_source="https://github.com/webship/uikit-steps.git";
site_source_ref="2.0.x";

# Distribution.
distribution_name="uikit";
distribution_title="UIkit";
distribution_webroot="site";

ARGPARSE_DESCRIPTION="Build a ${distribution_title} project in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/uikit/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/uikit/args/arg-uikit.sh || exit 1 ;

shift $#;

uikit_build ;
