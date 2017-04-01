Feature: Shopping cart
    As a user
    I want to have my cart
    So that I can choose products

    Scenario: Adding product to cart
        Given I am on the main page
        Then I should see product categories
        When I click on the "Mac" category
        Then I should see "iMac"
        When I click on the "Add to cart"
        Then I should see "Success: You have added iMac to your shopping cart!"
        And I should see "1 item(s) - $122.00"



