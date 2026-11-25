Feature: The components demo site answers and its components work
  As the owner of the demo site
  I want its pages to load the components script and its components to open and close
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.

  @critical
  Scenario: The home page is served with the components script
    Given I am on the homepage
    Then the response status code should be 200
    And the page should use the components script
    And I should see "Every component of the framework on a page of its own."

  @critical
  Scenario: A dialog opens and closes
    Given I am on "/modal.html"
    When I open the "Newsletter" dialog
    Then the "Newsletter" dialog should show "Get the news of the month in your mailbox"
    When I close the "Newsletter" dialog
    Then no dialog should be shown

  Scenario: Opening an accordion item closes the one that was open
    Given I am on "/accordion.html"
    When I expand the "Returns" panel
    Then the "Returns" panel should be expanded
    And the "Shipping" panel should be collapsed

  Scenario: A choice from a drop-down menu changes the page
    Given I am on "/dropdown.html"
    When I choose "Oldest first" from the "Sort by" drop-down menu
    Then the "Sort by" drop-down menu should not be shown
    And I should see "Sorted by: oldest first."

  Scenario: A narrow window hides the links behind the toggle button
    When I set the viewport to the "xs" breakpoint
    And I go to "/navbar.html"
    Then the navigation bar should be collapsed
    When I expand the navigation bar
    Then the navigation bar should be expanded
    When I collapse the navigation bar
    Then the navigation bar should be collapsed
