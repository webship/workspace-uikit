Feature: Form states, alerts, notifications and loading
  What a page tells a person: the state of each field after a form is sent, an alert, a
  notification that hides by itself, a spinner while a list loads, a bar that fills.

  Scenario: A form sent empty shows its invalid fields with their messages
    Given I am on "/form.html"
    When I press "Sign up"
    Then 3 fields should be shown as invalid
    And the "Email" field should show the message "Type an address like name@example.com."

  Scenario: A dismissible alert goes away with its close button
    Given I am on "/alert.html"
    Then the alert "Your profile was updated." should be dismissible
    When I dismiss the alert "Your profile was updated."
    Then I should not see the alert "Your profile was updated."

  Scenario: A notification appears and hides by itself
    Given I am on "/notification.html"
    When I press "Save the settings"
    Then I should see a success notification "The settings were saved."
    And the "The settings were saved." notification should hide by itself

  Scenario: A spinner turns while a list loads, and a bar fills during an upload
    Given I am on "/loading.html"
    When I press "Load the orders"
    And I wait for the loading spinner to disappear
    Then I should see "Order 1001: shipped"
    When I press "Start the upload"
    Then the "Upload" progress bar should reach 100%
