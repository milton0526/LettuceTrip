//
//  TripWidgetView.swift
//  TripWidgetView
//
//  Created by Milton Liu on 2023/7/18.
//

import WidgetKit
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseCore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TripEntry {
        TripEntry(date: Date(), trip: .mockData)
    }

    func getSnapshot(in context: Context, completion: @escaping (TripEntry) -> Void) {
        let entry = TripEntry(date: Date(), trip: .mockData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TripEntry>) -> Void) {

        fetchUserTrip { allTrip in
            let upcoming = allTrip
                .filter({ $0.endDate > .now })
                .sorted(by: { $0.startDate < $1.startDate })
                .first

            let entry = TripEntry(date: .now, trip: upcoming)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    func fetchUserTrip(completion: @escaping ([UpcomingTripModel]) -> Void) {
        guard let user = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("trips")
        var userTrips: [UpcomingTripModel] = []

        ref.whereField("members", arrayContains: user)
            .getDocuments { snapshot, error in
                guard error == nil else { return }

                snapshot?.documents.forEach { doc in
                    if let doc = try? doc.data(as: UpcomingTripModel.self) {
                        userTrips.append(doc)
                    }
                }
                completion(userTrips)
            }
    }
}

struct TripEntry: TimelineEntry {
    let date: Date
    var trip: UpcomingTripModel?
}

struct TripWidgetViewEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            if let trip = entry.trip {
                VStack {
                    Spacer()
                    Spacer()
                    Text(trip.tripName)
                        .font(.title3)
                        .bold()
                    Spacer()
                    HStack {
                        Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                        Text("~")
                        Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    .font(.headline)
                    Spacer()
                }
            } else {
                Text("No upcoming trip")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.teal.gradient)
    }
}

struct TripWidgetView: Widget {
    let kind: String = "TripWidgetView"

    init() {
        FirebaseApp.configure()
        try? Auth.auth().useUserAccessGroup("C5NNGG4J5Q.com.miltonliu.LettuceTrip")
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TripWidgetViewEntryView(entry: entry)
        }
        .configurationDisplayName("Upcoming trip")
        .description("This widget show your next trip!")
        .supportedFamilies([.systemSmall])
    }
}

struct TripWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        TripWidgetViewEntryView(entry: TripEntry(date: Date(), trip: .mockData))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

struct UpcomingTripModel: Decodable, Identifiable {
    var id: String?
    var tripName: String
    var image: String?
    var startDate: Date
    var endDate: Date

    static let mockData = UpcomingTripModel(
        id: "2ErxM7vE8s5v3F4qVDox",
        tripName: "大阪畢業旅行",
        image: "https://firebasestorage.googleapis.com:443/v0/b/lettucetrip.appspot.com/o/trips%2F2ErxM7vE8s5v3F4qVDox.jpg?alt=media&token=ba36c43d-45eb-4923-a35d-0ba7e98ba473",
        startDate: .now,
        endDate: .now.addingTimeInterval(60000))
}
