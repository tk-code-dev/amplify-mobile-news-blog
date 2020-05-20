//
//  AppDelegate.swift
//  amplify-lib-ios-demo
//
//  Created by Stormacq, Sebastien on 18/05/2020.
//  Copyright © 2020 Stormacq, Sebastien. All rights reserved.
//

import UIKit

import Amplify
import AmplifyPlugins
import AWSPredictionsPlugin

class UserData: ObservableObject {
    @Published var translatedText = ""
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    public let data = UserData()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: AmplifyModels()))
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSPredictionsPlugin())
            
            try Amplify.configure()
            print("Amplify initialized")
            
            // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
            _ = Amplify.Hub.listen(to: .auth) { (payload) in
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    print("==HUB== User signed In, update UI")
                case HubPayload.EventName.Auth.signedOut:
                    print("==HUB== User signed Out, update UI")
                case HubPayload.EventName.Auth.sessionExpired:
                    print("==HUB== Session expired, show sign in aui")
                default:
                    print("==HUB== \(payload)")
                    break
                }
            }
            
        } catch {
            print("Failed to configure Amplify \(error)")
        }
        
        return true
    }
    
    // MARK: Amplify Auth
    
    func signIn() {
        print("SignIn")
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!) { (result) in
            switch(result) {
                case .success(let result):
                    print(result)
                    
                    // fetch user details
                    _ = Amplify.Auth.fetchUserAttributes() { (result) in
                        switch result {
                        case .success(let session):
                            print(session)
                        case .failure(let error):
                            print(error)
                        }
                    }
                
                case .failure(let error):
                    print("Can not signin \(error)")
            }
        }
    }
    
    func signOut() {
        print("SignOut")
        _ = Amplify.Auth.signOut() { (result) in
            print(result)
            switch(result) {
            case .success():
                print("Signout succeded")
            case .failure(let error):
                print("Signout failed with \(error)")
            }
        }

    }
    
    // MARK: Amplify DataStore

    func query() {
        Amplify.DataStore.query(Note.self) {
            switch $0 {
                case .success(let result):
                    // result will be of type [Note]
                    for note in result {
                        print("Notes: \(note)")
                    }
                case .failure(let error):
                    print("Error listing notes - \(error.localizedDescription)")
            }
        }
    }
    
    func create() {
        let date = Date()
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        let dateString = df.string(from: date)

        let note = Note(content: "--\(dateString)-- content")
        Amplify.DataStore.save(note) {
            switch $0 {
            case .success:
                print("Added note")
            case .failure(let error):
                print("Error adding note - \(error.localizedDescription)")
            }
        }
    }

    // MARK: Amplify Predictions
    
    func translate(text: String) {
        _ = Amplify.Predictions.convert(textToTranslate: text, language: LanguageType.english, targetLanguage: LanguageType.french) {
            switch $0 {
            case .success(let result):
                // update UI on main thread 
                DispatchQueue.main.async() {
                    self.data.translatedText = result.text
                }
            case .failure(let error):
                print("Error adding note - \(error.localizedDescription)")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

