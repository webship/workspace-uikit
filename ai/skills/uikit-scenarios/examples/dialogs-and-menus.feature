Feature: Dialogs, side panels and drop-down menus
  A dialog and a side panel move for about a third of a second when they open and when they close,
  and a menu closes in the ways it was made to: the steps wait for each.

  Scenario: A dialog opens with its button and closes with Escape
    Given I am on "/modal.html"
    When I open the "Newsletter" dialog
    Then the "Newsletter" dialog should be shown
    And the "Newsletter" dialog should show "Get the news of the month in your mailbox"
    When I press Escape in the "Newsletter" dialog
    Then no dialog should be shown

  Scenario: A dialog set to stay open refuses a click outside, and its own button closes it
    Given I am on "/modal.html"
    When I open the "Upload in progress" dialog
    And I click outside the "Upload in progress" dialog
    Then the "Upload in progress" dialog should be shown
    When I press "Done" in the "Upload in progress" dialog
    Then the "Upload in progress" dialog should not be shown

  Scenario: A side panel slides in and goes with its close button
    Given I am on "/offcanvas.html"
    When I open the "Menu" side panel
    Then the "Menu" side panel should show "Customers"
    When I close the "Menu" side panel
    Then no side panel should be shown

  Scenario: A choice from a menu closes it and changes the page
    Given I am on "/dropdown.html"
    When I choose "Oldest first" from the "Sort by" drop-down menu
    Then the "Sort by" drop-down menu should not be shown
    And I should see "Sorted by: oldest first."

  Scenario: The items of a menu, active and disabled
    Given I am on "/dropdown.html"
    When I open the "Account" drop-down menu
    Then "Profile" should be active in the "Account" drop-down menu
    And "Billing" should be disabled in the "Account" drop-down menu
    When I close the "Account" drop-down menu
    Then no drop-down menu should be shown
