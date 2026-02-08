import SwiftUI
import CoreLocation

struct WeatherTestView: View {
    @StateObject private var model = WeatherTestViewModel()
    @StateObject private var locationManager = WeatherLocationManager()
    @State private var icao = ""
    @State private var hasAutoPopulated = false
    @State private var isSwitchingStation = false
    @FocusState private var isICAOFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            InstrumentBackground()
                .ignoresSafeArea()

            VStack(spacing: isPadLayout ? 16 : 12) {
                headerView
                inputRow
                actionRow
                locationStatusRow
                nearbyStationsSection

                if let errorMessage = model.errorMessage {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(errorMessage)
                            .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                            .foregroundColor(AppTheme.accent)
                        if let details = model.debugDetails {
                            Text(details)
                                .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 10))
                                .foregroundColor(AppTheme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView {
                    VStack(spacing: isPadLayout ? 14 : 10) {
                        weatherSection(title: "METAR", text: model.metarDecoded)
                        weatherSection(title: "TAF", text: model.tafRaw)
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding(isPadLayout ? 18 : 14)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationManager.requestLocation()
        }
        .onReceive(locationManager.$location) { location in
            guard let location, !hasAutoPopulated else { return }
            hasAutoPopulated = true
            Task { @MainActor in
                if let selection = await model.nearestStationSelection(
                    for: location.coordinate,
                    radiusNM: 20
                ) {
                    icao = selection.selectedICAO
                    await model.fetch(for: selection.selectedICAO)
                } else {
                    locationManager.statusMessage = "No nearby TAF/METAR station found."
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            BrandLogoView()
                .frame(maxWidth: isPadLayout ? 140 : 110)
                .padding(.bottom, 4)

            Text("Decoded METAR + TAF")
                .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 18 : 15))
                .foregroundColor(AppTheme.text)

            Text("Enter an ICAO airport identifier")
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                .foregroundColor(AppTheme.muted)
        }
    }

    private var inputRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "airplane")
                .foregroundColor(AppTheme.muted)

            TextField("ICAO (e.g. LTBA)", text: $icao)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .foregroundColor(AppTheme.text)
                .focused($isICAOFocused)
                .onSubmit {
                    fetchWeather()
                }

            if !icao.isEmpty {
                Button {
                    icao = ""
                    model.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                )
        )
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                fetchWeather()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "cloud.sun")
                    Text(model.isLoading ? "Loading..." : "Fetch")
                        .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 13 : 11))
                }
                .foregroundColor(AppTheme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.accentSoft)
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isLoading)

            if let lastUpdated = model.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .abbreviated, time: .shortened))")
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 10))
                    .foregroundColor(AppTheme.muted)
            }

            Spacer()
        }
    }

    private var locationStatusRow: some View {
        Group {
            if let status = locationManager.statusMessage {
                Text(status)
                    .font(.custom("Avenir Next Regular", size: isPadLayout ? 12 : 10))
                    .foregroundColor(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var nearbyStationsSection: some View {
        let others = model.nearbyStations.filter { $0.icao != icao }
        return Group {
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Airports within 20 NM")
                        .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 14 : 12))
                        .foregroundColor(AppTheme.text)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(others) { station in
                                Button {
                                    guard !isSwitchingStation else { return }
                                    isSwitchingStation = true
                                    icao = station.icao
                                    Task {
                                        await model.fetch(for: station.icao)
                                        isSwitchingStation = false
                                    }
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(station.icao)
                                            .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 12 : 11))
                                        if let name = station.commonName {
                                            Text(name)
                                                .font(.custom("Avenir Next Regular", size: isPadLayout ? 10 : 9))
                                                .foregroundColor(AppTheme.muted)
                                                .lineLimit(1)
                                        }
                                        Text(String(format: "%.0f NM", station.distanceNM))
                                            .font(.custom("Avenir Next Regular", size: isPadLayout ? 11 : 10))
                                    }
                                    .foregroundColor(AppTheme.text)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.cardHighlight)
                                            .overlay(
                                                Capsule()
                                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func weatherSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Avenir Next Demi Bold", size: isPadLayout ? 15 : 13))
                .foregroundColor(AppTheme.text)

            Text(text.isEmpty ? "No data yet." : text)
                .font(.custom("Avenir Next Regular", size: isPadLayout ? 13 : 11))
                .foregroundColor(text.isEmpty ? AppTheme.muted : AppTheme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.card, AppTheme.cardHighlight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.bezelDark, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .inset(by: 1)
                        .stroke(AppTheme.bezelLight, lineWidth: 1)
                )
        )
    }

    private func fetchWeather() {
        let cleaned = icao
            .uppercased()
            .filter { $0.isLetter }
        icao = cleaned
        Task {
            await model.fetch(for: cleaned)
        }
    }
}

@MainActor
final class WeatherTestViewModel: ObservableObject {
    @Published var metarDecoded: String = ""
    @Published var tafRaw: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var debugDetails: String?
    @Published var lastUpdated: Date?
    @Published var nearbyStations: [NearbyStation] = []

    func fetch(for icao: String) async {
        let trimmed = icao.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 4 else {
            errorMessage = "Enter a 4-letter ICAO identifier."
            return
        }

        isLoading = true
        errorMessage = nil
        debugDetails = nil

        do {
            async let metarJsonText = fetchJSON(endpoint: "metar", icao: trimmed, decoder: decodeMetar)
            async let tafRawText = fetchText(endpoint: "taf", icao: trimmed, format: "raw")
            let (metarJsonResult, tafRawResult) = try await (metarJsonText, tafRawText)
            metarDecoded = metarJsonResult.cleanedWeatherText
            tafRaw = tafRawResult.cleanedWeatherText
            lastUpdated = Date()
        } catch {
            errorMessage = "Unable to load weather data."
            debugDetails = error.localizedDescription
        }

        isLoading = false
    }

    func nearestStationSelection(
        for coordinate: CLLocationCoordinate2D,
        radiusNM: Double
    ) async -> StationSelection? {
        do {
            if let selection = try await stationsNear(
                endpoint: "metar",
                coordinate: coordinate,
                radiusNM: radiusNM
            ) {
                nearbyStations = selection.nearby
                return selection
            }
            return nil
        } catch {
            return nil
        }
    }

    func clear() {
        metarDecoded = ""
        tafRaw = ""
        errorMessage = nil
        debugDetails = nil
        lastUpdated = nil
        nearbyStations = []
    }

    private func fetchText(endpoint: String, icao: String, format: String) async throws -> String {
        let base = "https://aviationweather.gov/api/data"
        let urlString = "\(base)/\(endpoint)?ids=\(icao)&format=\(format)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("M600Tools/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(decoding: data, as: UTF8.self)
            throw WeatherFetchError.http(statusCode: http.statusCode, body: body)
        }

        return String(decoding: data, as: UTF8.self)
    }

    private func fetchJSON(
        endpoint: String,
        icao: String,
        decoder: ([String: Any]) -> String
    ) async throws -> String {
        let base = "https://aviationweather.gov/api/data"
        let urlString = "\(base)/\(endpoint)?ids=\(icao)&format=json"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("M600Tools/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(decoding: data, as: UTF8.self)
            throw WeatherFetchError.http(statusCode: http.statusCode, body: body)
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        if let array = object as? [[String: Any]], let first = array.first {
            let decoded = decoder(first)
            return decoded.cleanedWeatherText
        }
        if let dict = object as? [String: Any] {
            let decoded = decoder(dict)
            return decoded.cleanedWeatherText
        }
        return "No decoded data available."
    }

    private func stationsNear(
        endpoint: String,
        coordinate: CLLocationCoordinate2D,
        radiusNM: Double
    ) async throws -> StationSelection? {
        let deltas: [Double] = [radiusNM / 60.0, max(radiusNM / 30.0, radiusNM / 60.0)]
        for delta in deltas {
            let minLat = coordinate.latitude - delta
            let maxLat = coordinate.latitude + delta
            let minLon = coordinate.longitude - delta
            let maxLon = coordinate.longitude + delta
            let urlString = "https://aviationweather.gov/api/data/\(endpoint)?bbox=\(minLat),\(minLon),\(maxLat),\(maxLon)&format=json"
            guard let url = URL(string: urlString) else { continue }

            var request = URLRequest(url: url)
            request.setValue("M600Tools/1.0", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { continue }
            if http.statusCode == 204 { continue }
            guard (200...299).contains(http.statusCode) else {
                let body = String(decoding: data, as: UTF8.self)
                throw WeatherFetchError.http(statusCode: http.statusCode, body: body)
            }

            let object = try JSONSerialization.jsonObject(with: data, options: [])
            guard let array = object as? [[String: Any]], !array.isEmpty else {
                continue
            }

            let stations: [NearbyStation] = array
                .compactMap { entry -> NearbyStation? in
                    guard let id = stringValue(from: entry, keys: ["stationId", "icaoId", "station"]) else {
                        return nil
                    }
                    guard let lat = numberValue(from: entry, keys: ["lat", "latitude"]),
                          let lon = numberValue(from: entry, keys: ["lon", "longitude"]) else {
                        return nil
                    }
                    let distanceMeters = coordinate.distance(
                        to: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    )
                    let distanceNM = distanceMeters / 1852.0
                    if distanceNM > radiusNM {
                        return nil
                    }
                    let commonName = commonStationName(from: entry, icao: id)
                    return NearbyStation(icao: id, commonName: commonName, distanceNM: distanceNM)
                }
                .sorted { $0.distanceNM < $1.distanceNM }

            if let first = stations.first {
                return StationSelection(selectedICAO: first.icao, nearby: stations)
            }
        }
        return nil
    }
}

private extension String {
    var cleanedWeatherText: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No data returned." : trimmed
    }
}

private enum WeatherFetchError: LocalizedError {
    case http(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case let .http(statusCode, body):
            let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedBody.isEmpty {
                return "HTTP \(statusCode) with empty response."
            }
            let compact = trimmedBody.count > 200 ? String(trimmedBody.prefix(200)) + "…" : trimmedBody
            return "HTTP \(statusCode): \(compact)"
        }
    }
}

private func decodeMetar(_ dict: [String: Any]) -> String {
    var lines: [String] = []

    if let station = stringValue(from: dict, keys: ["stationId", "icaoId", "station"]) {
        lines.append("Station: \(station)")
    }
    if let time = stringValue(from: dict, keys: ["obsTime", "observation_time"]) {
        lines.append("Time: \(time)")
    }

    if let wind = formatWind(from: dict) {
        lines.append("Wind: \(wind)")
    }

    if let visibility = stringValue(from: dict, keys: ["visib", "visibility"]) {
        lines.append("Visibility: \(visibility)")
    }

    if let wx = stringValue(from: dict, keys: ["wxString", "weather", "presentWeather"]) {
        lines.append("Weather: \(wx)")
    }

    if let temp = numberValue(from: dict, keys: ["temp", "temperature", "tempC"]),
       let dew = numberValue(from: dict, keys: ["dewp", "dewpoint", "dewpointC"]) {
        lines.append("Temp/Dew: \(formatNumber(temp)) / \(formatNumber(dew)) C")
    } else if let temp = numberValue(from: dict, keys: ["temp", "temperature", "tempC"]) {
        lines.append("Temp: \(formatNumber(temp)) C")
    }

    if let altim = numberValue(from: dict, keys: ["altim", "altimeter", "altimInHg"]) {
        lines.append("Altimeter: \(formatNumber(altim)) inHg")
    }

    if let clouds = formatClouds(from: dict) {
        lines.append("Clouds: \(clouds)")
    }

    if lines.isEmpty {
        return "No decoded data available."
    }
    return lines.joined(separator: "\n")
}

private func stringValue(from dict: [String: Any], keys: [String]) -> String? {
    for key in keys {
        if let value = dict[key] {
            if let string = value as? String, !string.isEmpty {
                return string
            } else if let number = value as? NSNumber {
                return number.stringValue
            }
        }
    }
    return nil
}

private func commonStationName(from dict: [String: Any], icao: String) -> String? {
    let candidates = [
        "stationName",
        "name",
        "site",
        "location",
        "siteName",
        "airportName",
        "facilityName"
    ]
    guard let raw = stringValue(from: dict, keys: candidates) else {
        return nil
    }
    let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return nil }
    if cleaned.caseInsensitiveCompare(icao) == .orderedSame {
        return nil
    }
    return cleaned
}

private func numberValue(from dict: [String: Any], keys: [String]) -> Double? {
    for key in keys {
        if let value = dict[key] {
            if let number = value as? NSNumber {
                return number.doubleValue
            } else if let string = value as? String, let parsed = Double(string) {
                return parsed
            }
        }
    }
    return nil
}

private func formatWind(from dict: [String: Any]) -> String? {
    let dir = numberValue(from: dict, keys: ["wdir", "windDir", "windDirDegrees"])
    let spd = numberValue(from: dict, keys: ["wspd", "windSpeed", "windSpeedKt"])
    let gst = numberValue(from: dict, keys: ["wgst", "windGust", "windGustKt"])

    if dir == nil && spd == nil {
        return nil
    }

    var parts: [String] = []
    if let dir {
        parts.append(String(format: "%03.0f", dir))
    }
    if let spd {
        parts.append("\(formatNumber(spd)) kt")
    }
    if let gst {
        parts.append("G \(formatNumber(gst))")
    }

    return parts.joined(separator: " ")
}

private func formatClouds(from dict: [String: Any]) -> String? {
    guard let clouds = dict["clouds"] as? [[String: Any]] else {
        return nil
    }
    let formatted = clouds.compactMap { cloud -> String? in
        let cover = stringValue(from: cloud, keys: ["cover", "coverage", "code"])
        let base = numberValue(from: cloud, keys: ["base", "baseFt", "base_feet_agl"])
        if let cover, let base {
            return "\(cover) \(formatNumber(base))"
        }
        if let cover {
            return cover
        }
        return nil
    }
    return formatted.isEmpty ? nil : formatted.joined(separator: ", ")
}

private func formatNumber(_ value: Double) -> String {
    let rounded = (value * 10).rounded() / 10
    if abs(rounded.rounded() - rounded) < 0.001 {
        return String(format: "%.0f", rounded)
    }
    return String(format: "%.1f", rounded)
}

final class WeatherLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var statusMessage: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        DispatchQueue.main.async {
            self.statusMessage = "Locating nearest airport..."
        }
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .denied, .restricted:
                self.statusMessage = "Location permission denied. Enter ICAO manually."
            case .authorizedAlways, .authorizedWhenInUse:
                self.statusMessage = "Locating nearest airport..."
            case .notDetermined:
                break
            @unknown default:
                self.statusMessage = "Location unavailable."
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.location = latest
            self.statusMessage = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.statusMessage = "Location unavailable. Enter ICAO manually."
        }
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: latitude, longitude: longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}

struct NearbyStation: Identifiable, Equatable {
    let id = UUID()
    let icao: String
    let commonName: String?
    let distanceNM: Double
}

struct StationSelection {
    let selectedICAO: String
    let nearby: [NearbyStation]
}
