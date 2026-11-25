Feature: A components demo site on Docker Compose, Podman and Kubernetes
  The builder builds on DDEV by default, and with --runtime on Docker Compose, Podman or a Kubernetes cluster. A demo
  site built there has the row a DDEV site has: its state, its own address and the runtime's menu, and it serves the
  same pages.

  # Each scenario drives a real demo site of that runtime, built with cmd-uikit-project.sh --runtime: the first running
  # one the workspace holds. Without one it is skipped, with the reason. In the plugin's CI the Docker Compose site is
  # the one the manifest's featuresSite builds.

  @needs-runtime-docker @needs-platform-uikit
  Scenario: A demo site built on Docker Compose runs at its own address, with the DOCKER menu
    Given I am on the folder of the "docker" site
     Then the row of the "docker" site should show "Running"
      And the row of the "docker" site should link to the address of its runtime
      And the address of the "docker" site should answer
      And the row of the "docker" site should carry the "DOCKER" menu and no DDEV menu

  @needs-runtime-docker @needs-platform-uikit
  Scenario: The demo site on Docker Compose serves its pages
    Given I am on the folder of the "docker" site
     When I open "/" on the "docker" site
     Then I should see "Every component of the framework on a page of its own."
     When I open "/modal.html" on the "docker" site
     Then I should see "Subscribe to the newsletter"

  @needs-runtime-podman @needs-platform-uikit
  Scenario: A demo site built on Podman runs at its own address, with the PODMAN menu
    Given I am on the folder of the "podman" site
     Then the row of the "podman" site should show "Running"
      And the row of the "podman" site should link to the address of its runtime
      And the address of the "podman" site should answer
      And the row of the "podman" site should carry the "PODMAN" menu and no DDEV menu

  @needs-runtime-podman @needs-platform-uikit
  Scenario: The demo site on Podman serves its pages
    Given I am on the folder of the "podman" site
     When I open "/" on the "podman" site
     Then I should see "Every component of the framework on a page of its own."
     When I open "/modal.html" on the "podman" site
     Then I should see "Subscribe to the newsletter"

  @needs-runtime-kubernetes @needs-platform-uikit
  Scenario: A demo site built on Kubernetes runs at the address of its node, with the K8S menu
    Given I am on the folder of the "kubernetes" site
     Then the row of the "kubernetes" site should show "Running"
      And the row of the "kubernetes" site should link to the address of its runtime
      And the address of the "kubernetes" site should answer
      And the row of the "kubernetes" site should carry the "K8S" menu and no DDEV menu

  @needs-runtime-kubernetes @needs-platform-uikit
  Scenario: The demo site on Kubernetes serves its pages
    Given I am on the folder of the "kubernetes" site
     When I open "/" on the "kubernetes" site
     Then I should see "Every component of the framework on a page of its own."
     When I open "/modal.html" on the "kubernetes" site
     Then I should see "Subscribe to the newsletter"
