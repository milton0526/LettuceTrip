# Lettuce Trip
An app let you explore the world and plan your journey together with friends in real-time.
> Lettuce Trip. ***Let us trip!***

## Description
The purpose of this project is to address the inconvenience in planning travel itineraries, where travelers often find themselves using multiple software simultaneously, such as maps, web browser, and communication application.   
By integrating all these functionalities to simplify the process and achieve a one-stop solution for travel management.

## Key Features
- Social Sharing
- Explore travel-related locations on the map
- Collaborative editing
- Real-time chat
- Widget

## Gettinng Started
1. Clone this repo
2. Make sure xcode version 14.0 or above
3. Supported device only iphone
4. Supported lauguage: Engilsh and Chinese(Tranditional)
5. Choose ios 16.0 or above to run the simulator

Once you successfully run the project, you have to sign in with apple to contiunte.
The project will not collect personal data except for the user's name and email address. Also you can delete account in anytime.

## Usage
For more detail about how to use this app, please watch the video(3mins).

## Architecture
- This project is using MVVM architecture to separate business logic from view controller.
- Use "Combine" framworks to make API call, also pass data between view controller and view model.
- Apple MapKit
- SwiftUI for building widget

## Folder Structure
- "Core": The main folder of this project, contains all view controllers and view models in it.
- "Model": Files are share for view models and API resoponse.
- "Manager": Utilities for whole project that can reuse such as authentication, location, and Firebase related functions.
- "Helper" & "Extensions": Files that help to reduce writing redundant code.

## Dependencies
Swift Package Manager is used as dependencies manager. List of dependencies:
- TinyContraints
- Cosmos
- Firebase
- IQKeyboardManagerSwift
- JGProgressHUD
- UnsplashPhotoPicker
- SDWebImage

## API
- Firebase: https://firebase.google.com/docs/build?authuser=0
- Google Place: https://developers.google.com/maps/documentation/places/web-service/overview
- Unsplash: https://unsplash.com/developers
