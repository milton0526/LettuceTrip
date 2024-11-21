# Lettuce Trip
An app let you explore the world and plan your journey together with friends in real-time.
> Lettuce Trip. ***Let us trip!***

<img src="https://github.com/milton0526/LettuceTrip/blob/main/CoverImages/Discover.png">
<img src="https://github.com/milton0526/LettuceTrip/blob/main/CoverImages/Editing.png">

## Description
The purpose of this project is to address the inconvenience in planning travel itineraries, where travelers often find themselves using multiple software simultaneously, such as maps, web browser, and communication application.   
By integrating all these functionalities to simplify the process and achieve a one-stop solution for travel management.

## Key Features
- Social Sharing
- Explore travel-related locations on the map
- Collaborative editing
- Real-time chat
- Widget

## Requirements
1. Xcode version 14.0 or above
2. Supported device only iPhone
3. iOS version 16.0 or above
4. Supported languages: English and Chinese(Traditional)

Once you successfully run the project, you have to sign in with apple to continue.
The project will not collect personal data except for the user's name and email address. Also you can delete account in anytime.

## Usage
For more detail about how to use this app, please watch the video(4mins).
- Link: https://drive.google.com/file/d/12I6GaCSehw7YaclzPBqK-60szy3455-w/view?usp=share_link

## Architecture
- This project is using MVVM architecture to separate business logic from view controller.
- Use "Combine" framework to process API response data, also pass data between view model and view controller.
- Apple MapKit
- SwiftUI for building widget

## Folder Structure
- "Core": The main folder of this project, contains all view controllers and view models in it.
- "Model": Files are share for view models and API response.
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
