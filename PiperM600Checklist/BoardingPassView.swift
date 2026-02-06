import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct BoardingPassBuilderView: View {
    @StateObject private var model = BoardingPassViewModel()
    @State private var showSettings = false
    @State private var showAddPassenger = false
    @State private var selectedPassenger: Passenger?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: isPadLayout ? 16 : 12) {
                    headerView
                    flightInfoSection
                    passengersSection
                }
                .padding(isPadLayout ? 18 : 14)
            }
        }
        .navigationTitle("Boarding Pass")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                BoardingPassSettingsView(
                    flightName: $model.flightName,
                    flightNumber: $model.flightNumber,
                    gate: $model.gate,
                    boardingGroup: $model.boardingGroup,
                    frequentFlyerPrefix: $model.frequentFlyerPrefix
                )
            }
        }
        .sheet(isPresented: $showAddPassenger) {
            NavigationStack {
                AddPassengerView { passenger in
                    model.addPassenger(passenger)
                }
            }
        }
        .sheet(item: $selectedPassenger) { passenger in
            NavigationStack {
                BoardingPassDetailView(
                    passenger: passenger,
                    model: model
                )
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("Create boarding passes for a single flight")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                .foregroundColor(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var flightInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flight Details")
                .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 16 : 14))
                .foregroundColor(AppTheme.text)

            VStack(spacing: 10) {
                labeledField(title: "Departure", text: $model.departure)
                labeledField(title: "Departure City", text: $model.departureCity)
                labeledField(title: "Destination", text: $model.destination)
                labeledField(title: "Destination City", text: $model.destinationCity)
                labeledField(title: "Date", text: $model.travelDate)
                labeledField(title: "Departure Time", text: $model.departureTime)
                labeledField(title: "Arrival Time", text: $model.arrivalTime)
            }
        }
        .cardStyle()
    }

    private var passengersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Passengers")
                    .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 16 : 14))
                    .foregroundColor(AppTheme.text)

                Spacer()

                Button {
                    showAddPassenger = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 12 : 11))
                        .foregroundColor(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if model.passengers.isEmpty {
                Text("No passengers yet.")
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                    .foregroundColor(AppTheme.muted)
            } else {
                VStack(spacing: 8) {
                    ForEach(model.passengers) { passenger in
                        HStack {
                            Button {
                                selectedPassenger = passenger
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(passenger.fullName)
                                        .font(.custom("Avenir Next Regular", size: isPadLayout ? 14 : 12))
                                        .foregroundColor(AppTheme.text)
                                    if !passenger.seat.isEmpty {
                                        Text("Seat \(passenger.seat)")
                                            .font(.custom("Avenir Next Regular", size: isPadLayout ? 11 : 10))
                                            .foregroundColor(AppTheme.muted)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                model.removePassenger(passenger)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(AppTheme.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)

                        if passenger.id != model.passengers.last?.id {
                            Divider()
                                .background(AppTheme.gridLine)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func labeledField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 10))
                .foregroundColor(AppTheme.muted)

            TextField(title, text: text)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundColor(AppTheme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.accentSoft, lineWidth: 1)
                        )
                )
        }
    }
}

private struct BoardingPassPreviewCard: View {
    let passenger: Passenger
    let flightName: String
    let flightNumber: String
    let departure: String
    let departureCity: String
    let destination: String
    let destinationCity: String
    let travelDate: String
    let boardingTime: String
    let departureTime: String
    let arrivalTime: String
    let gate: String
    let seat: String
    let boardingGroup: String
    let frequentFlyer: String
    @State private var barcodeImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image("Logo")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 78, height: 78)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flightName.isEmpty ? "Elite Air" : flightName)
                            .font(.custom("Avenir Next Demi Bold", size: 12))
                            .tracking(0.6)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("GATE / SEAT")
                        .font(.custom("Avenir Next Regular", size: 9))
                        .foregroundColor(Color.white.opacity(0.7))
                    Text("\(gate.isEmpty ? "-" : gate) / \(seat.isEmpty ? "--" : seat)")
                        .font(.custom("Avenir Next Demi Bold", size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(departureCity.isEmpty ? "DEPARTURE" : departureCity.uppercased())
                        .font(.custom("Avenir Next Regular", size: 10))
                        .foregroundColor(Color.white.opacity(0.7))
                    Text(departure.isEmpty ? "---" : departure.uppercased())
                        .font(.custom("Avenir Next Demi Bold", size: 34))
                }

                Spacer()

                Image(systemName: "airplane")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.9))

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(destinationCity.isEmpty ? "DESTINATION" : destinationCity.uppercased())
                        .font(.custom("Avenir Next Regular", size: 10))
                        .foregroundColor(Color.white.opacity(0.7))
                    Text(destination.isEmpty ? "---" : destination.uppercased())
                        .font(.custom("Avenir Next Demi Bold", size: 34))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            HStack {
                infoBlock(title: "FLIGHT", value: flightNumber.isEmpty ? "--" : flightNumber)
                Spacer()
                infoBlock(title: "DATE", value: travelDate.isEmpty ? "--" : travelDate)
                Spacer()
                infoBlock(title: "BOARDING", value: boardingTime.isEmpty ? "--" : boardingTime)
                Spacer()
                infoBlock(title: "DEPART / ARRIVE", value: "\(departureTime.isEmpty ? "--" : departureTime) / \(arrivalTime.isEmpty ? "--" : arrivalTime)")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PASSENGER")
                        .font(.custom("Avenir Next Regular", size: 9))
                        .foregroundColor(Color.white.opacity(0.7))
                    Text(passenger.fullName.uppercased())
                        .font(.custom("Avenir Next Demi Bold", size: 16))
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("FREQUENT FLYER")
                        .font(.custom("Avenir Next Regular", size: 9))
                        .foregroundColor(Color.white.opacity(0.7))
                    Text(frequentFlyer.isEmpty ? "--" : frequentFlyer.uppercased())
                        .font(.custom("Avenir Next Demi Bold", size: 16))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            HStack {
                Spacer()
                Text("FAST-TRACK")
                    .font(.custom("Avenir Next Demi Bold", size: 10))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.90, green: 0.28, blue: 0.33))
                    )
                Spacer()
            }
            .padding(.bottom, 10)

            HStack {
                Spacer()
                Group {
                    if let barcodeImage {
                        Image(uiImage: barcodeImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.bottom, 12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 160, height: 160)
                            .padding(.bottom, 12)
                    }
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .foregroundColor(.white)
        .onAppear {
            if barcodeImage == nil {
                barcodeImage = BarcodeGenerator.qr(from: barcodePayload)
            }
        }
        .onChange(of: barcodePayload) { _ in
            barcodeImage = BarcodeGenerator.qr(from: barcodePayload)
        }
    }

    private var barcodePayload: String {
        let components: [String] = [
            flightName,
            flightNumber,
            passenger.fullName,
            departure,
            destination,
            departureTime,
            seat,
            boardingGroup
        ]
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "|")
    }

    private func infoBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("Avenir Next Regular", size: 9))
                .foregroundColor(Color.white.opacity(0.7))
            Text(value)
                .font(.custom("Avenir Next Demi Bold", size: 14))
                .foregroundColor(.white)
        }
    }
}

private struct BoardingPassDetailView: View {
    let passenger: Passenger
    @ObservedObject var model: BoardingPassViewModel
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    BoardingPassPreviewCard(
                        passenger: passenger,
                        flightName: model.flightName,
                        flightNumber: model.flightNumber,
                        departure: model.departure,
                        departureCity: model.departureCity,
                        destination: model.destination,
                        destinationCity: model.destinationCity,
                        travelDate: model.travelDate,
                        boardingTime: model.computedBoardingTime,
                        departureTime: model.departureTime,
                        arrivalTime: model.arrivalTime,
                        gate: model.gate,
                        seat: passenger.seat,
                        boardingGroup: model.boardingGroup,
                        frequentFlyer: passenger.frequentFlyer
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.custom("Avenir Next Regular", size: 12))
                            .foregroundColor(AppTheme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(18)
            }
        }
        .navigationTitle(passenger.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard !isGenerating else { return }
                    isGenerating = true
                    errorMessage = nil
                    Task {
                        do {
                            let url = try await model.generatePassURL(for: passenger)
                            shareItems = [url]
                            showShareSheet = true
                        } catch {
                            errorMessage = "Unable to generate boarding pass."
                        }
                        isGenerating = false
                    }
                } label: {
                    if isGenerating {
                        ProgressView()
                            .tint(AppTheme.accent)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.accent)
                    }
                }
                .accessibilityLabel("Share Boarding Pass")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }
}

struct BoardingPassSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var flightName: String
    @Binding var flightNumber: String
    @Binding var gate: String
    @Binding var boardingGroup: String
    @Binding var frequentFlyerPrefix: String

    var body: some View {
        Form {
            Section("Flight") {
                TextField("Flight Name", text: $flightName)
                TextField("Flight Number", text: $flightNumber)
                TextField("Gate", text: $gate)
            }
            Section("Passenger Defaults") {
                TextField("Boarding Group", text: $boardingGroup)
                TextField("Frequent Flyer Prefix", text: $frequentFlyerPrefix)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct AddPassengerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case firstName
        case lastName
    }

    let onSave: (Passenger) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                labeledField(title: "First Name", text: $firstName, field: .firstName)
                labeledField(title: "Last Name", text: $lastName, field: .lastName)
            }
            .padding(16)
        }
        .navigationTitle("Add Passenger")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            focusedField = .firstName
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    let passenger = Passenger(firstName: firstName, lastName: lastName)
                    onSave(passenger)
                    dismiss()
                }
                .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
                          lastName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func labeledField(title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Avenir Next Regular", size: 12))
                .foregroundColor(AppTheme.muted)

            TextField(title, text: text)
                .focused($focusedField, equals: field)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
        }
    }
}

final class BoardingPassViewModel: ObservableObject {
    @Published var flightName: String = "Elite Air" { didSet { persist() } }
    @Published var departure: String = "LFPT" { didSet { persist() } }
    @Published var destination: String = "LBTA" { didSet { persist() } }
    @Published var departureCity: String = "Paris" { didSet { persist() } }
    @Published var destinationCity: String = "Istanbul" { didSet { persist() } }
    @Published var travelDate: String = "Feb 15 2026" { didSet { persist() } }
    @Published var departureTime: String = "9:30" { didSet { persist() } }
    @Published var arrivalTime: String = "13:00" { didSet { persist() } }
    @Published var flightNumber: String = "TCEZP 001" { didSet { persist() } }
    @Published var gate: String = "Pontoise FBO" { didSet { persist() } }
    @Published var boardingGroup: String = "Global Services" { didSet { persist() } }
    @Published var frequentFlyerPrefix: String = "EZ" { didSet { persist() } }
    @Published var passengers: [Passenger] = [] { didSet { persistIfNeeded() } }

    private let seatPool = ["A2", "B2", "A3", "B3"]
    private let frequentFlyerNumbers = ["01", "02", "03", "04"]
    private let storageKey = "boarding_pass_state_v1"
    private var isLoading = false

    init() {
        load()
    }

    var computedBoardingTime: String {
        guard let time = parseTime(departureTime) else { return "" }
        let adjusted = time.addingTimeInterval(-30 * 60)
        return formatTime(adjusted)
    }

    func addPassenger(_ passenger: Passenger) {
        var updated = passenger
        updated.seat = nextAvailableSeat()
        updated.frequentFlyer = nextAvailableFrequentFlyer()
        passengers.append(updated)
    }

    func removePassenger(_ passenger: Passenger) {
        passengers.removeAll { $0.id == passenger.id }
    }

    func generatePassURL(for passenger: Passenger) async throws -> URL {
        guard let serviceURL = URL(string: "https://pass-signing-service-670044709036.europe-west1.run.app/sign") else {
            throw PassSigningError.invalidURL
        }

        let payload = PassSigningPayload(
            flightName: flightName.isEmpty ? "Boarding Pass" : flightName,
            flightNumber: flightNumber,
            passengerName: passenger.fullName,
            departure: departure,
            departureCity: departureCity,
            destination: destination,
            destinationCity: destinationCity,
            travelDate: travelDate,
            boardingTime: computedBoardingTime,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            gate: gate,
            seat: passenger.seat,
            boardingGroup: boardingGroup,
            frequentFlyer: passenger.frequentFlyer
        )

        var request = URLRequest(url: serviceURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PassSigningError.badResponse
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("boarding-\(passenger.id.uuidString).pkpass")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func nextAvailableSeat() -> String {
        let assigned = Set(passengers.map { $0.seat })
        return seatPool.first { !assigned.contains($0) } ?? ""
    }

    private func nextAvailableFrequentFlyer() -> String {
        let assigned = Set(passengers.map { $0.frequentFlyer })
        for number in frequentFlyerNumbers {
            let candidate = frequentFlyerPrefix + number
            if !assigned.contains(candidate) {
                return candidate
            }
        }
        return ""
    }

    private func persistIfNeeded() {
        guard !isLoading else { return }
        persist()
    }

    private func persist() {
        let state = BoardingPassState(
            flightName: flightName,
            departure: departure,
            destination: destination,
            departureCity: departureCity,
            destinationCity: destinationCity,
            travelDate: travelDate,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            flightNumber: flightNumber,
            gate: gate,
            boardingGroup: boardingGroup,
            frequentFlyerPrefix: frequentFlyerPrefix,
            passengers: passengers
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        isLoading = true
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(BoardingPassState.self, from: data) else {
            isLoading = false
            return
        }
        let storedName = state.flightName.trimmingCharacters(in: .whitespacesAndNewlines)
        if storedName.isEmpty || storedName == "Boarding Pass Builder" {
            flightName = "Elite Air"
        } else {
            flightName = state.flightName
        }
        departure = state.departure
        destination = state.destination
        departureCity = state.departureCity
        destinationCity = state.destinationCity
        travelDate = state.travelDate
        departureTime = state.departureTime
        arrivalTime = state.arrivalTime
        flightNumber = state.flightNumber
        gate = state.gate
        boardingGroup = state.boardingGroup
        frequentFlyerPrefix = state.frequentFlyerPrefix
        passengers = state.passengers
        isLoading = false
    }

    private func parseTime(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = ["H:mm", "HH:mm"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
}

struct Passenger: Identifiable, Equatable, Codable {
    var id = UUID()
    let firstName: String
    let lastName: String
    var seat: String = ""
    var frequentFlyer: String = ""

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

private struct BoardingPassState: Codable {
    let flightName: String
    let departure: String
    let destination: String
    let departureCity: String
    let destinationCity: String
    let travelDate: String
    let departureTime: String
    let arrivalTime: String
    let flightNumber: String
    let gate: String
    let boardingGroup: String
    let frequentFlyerPrefix: String
    let passengers: [Passenger]
}

private struct PassSigningPayload: Codable {
    let flightName: String
    let flightNumber: String
    let passengerName: String
    let departure: String
    let departureCity: String
    let destination: String
    let destinationCity: String
    let travelDate: String
    let boardingTime: String
    let departureTime: String
    let arrivalTime: String
    let gate: String
    let seat: String
    let boardingGroup: String
    let frequentFlyer: String
}

private enum PassSigningError: Error {
    case invalidURL
    case badResponse
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum BarcodeGenerator {
    private static let context = CIContext()

    static func qr(from payload: String) -> UIImage? {
        let data = Data(payload.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 6.0, y: 6.0))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.card, AppTheme.cardHighlight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.bezelDark, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .inset(by: 1)
                            .stroke(AppTheme.bezelLight, lineWidth: 1)
                    )
            )
    }
}
