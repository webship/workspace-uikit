Feature: Accordions, tabs, slideshows, the lightbox and the navigation bar
  An accordion closes its open item while it opens another, a tab's content fades in, a slideshow
  slides for most of a second, the lightbox's picture slides in after the lightbox says it is open:
  the steps wait for the movement, not for a time.

  Scenario: Opening an accordion item closes the one that was open
    Given I am on "/accordion.html"
    When I expand the "Returns" panel
    Then the "Returns" panel should be expanded
    And the "Shipping" panel should be collapsed

  Scenario: Switching tabs shows each tab's content
    Given I am on "/switcher.html"
    When I switch to the "Security" tab
    Then the "Security" tab should be active
    And the "Profile" tab should not be active
    And the "Security" tab should show "Your password and the devices that are signed in."

  Scenario: The arrows of a slideshow move to the next slide
    Given I am on "/slideshow.html"
    When I go to the next slide of the "Gallery" slideshow
    Then the "Gallery" slideshow should show slide 2 of 3
    And the "Gallery" slideshow should show "The market on Saturday"

  Scenario: A picture opens in the lightbox and the arrows go through the gallery
    Given I am on "/lightbox.html"
    When I open the lightbox from the "The market on Saturday" picture
    Then the lightbox should show picture 2 of 4
    When I go to the next picture of the lightbox
    Then the lightbox should show "The old bridge"
    When I close the lightbox
    Then the lightbox should not be shown

  Scenario: A narrow window hides the links behind the toggle button
    When I set the viewport to the "xs" breakpoint
    And I go to "/navbar.html"
    Then the "Shop" navigation bar should show its toggle button
    When I expand the "Shop" navigation bar
    Then the "Shop" navigation bar should be expanded
    When I collapse the "Shop" navigation bar
    Then the "Shop" navigation bar should be collapsed
