Trello iOS Assisted Onboarding
==============================

This project is a simple iOS App that hosts the Trello iOS Assisted Onboarding screens. The code was written using
an MVVM architecture with RxSwift in a declarative/stateless style.

This code was open-sourced to provide a bigger example of production code that 

1. Uses Reactive Programming in more complex ways.
2. Is extensively unit tested.
3. Takes advantage of iOS accessibility features and works at all dynamic type sizes and supports voice-over and iOS 13 voice control.
4. Adapts to different size-classes.

How to build
------------

The project uses carthage to install dependencies and Swift 5 (Xcode 10.2.1)

1. Clone this repo
2. In the root folder, type `carthage update`
3. Open `TrelloAssistedOnboarding.xcodeproj` in Xcode 10.2.1 or later and build/test/run

Usage
-----

This app shows a Trello board with a guidance overlay. If you tap the green button on any overlay, it will give focus to the text field it is describing and once you complete editing, you will be moved to the next step in the process.

![Onboarding screenshot](README-images/tao-iphone.png "Onboarding screenshot")

Once you learn about something, you are allowed to interact with it any time later in the process.  The assisted onboarding will progress through the board name, list names, and card names -- finally it will let you create the board.  In this sample code, the last green button does nothing (in Trello, it would create the board and take you to it)

Basic Architecture
------------------

The main two classes to look at are `OnboardingViewController` and `OnboardingViewModel`.  Together they implement Model-View-ViewModel using a Reactive style. 