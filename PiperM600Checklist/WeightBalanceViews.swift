import SwiftUI
import Charts

// WeightBalanceMenuView removed in favor of opening input directly from the root menu.

private enum WBEnvelopeConfig {
    static let p1x = "wb_env_p1x"
    static let p1y = "wb_env_p1y"
    static let p2x = "wb_env_p2x"
    static let p2y = "wb_env_p2y"
    static let p3x = "wb_env_p3x"
    static let p3y = "wb_env_p3y"
    static let p4x = "wb_env_p4x"
    static let p4y = "wb_env_p4y"
    static let p5x = "wb_env_p5x"
    static let p5y = "wb_env_p5y"
    static let p6x = "wb_env_p6x"
    static let p6y = "wb_env_p6y"
    static let p7x = "wb_env_p7x"
    static let p7y = "wb_env_p7y"
    static let q1x = "wb_env_q1x"
    static let q1y = "wb_env_q1y"
    static let q2x = "wb_env_q2x"
    static let q2y = "wb_env_q2y"
    static let q3x = "wb_env_q3x"
    static let q3y = "wb_env_q3y"
    static let mzfw = "wb_env_mzfw"
    static let mlw = "wb_env_mlw"
    static let schemaVersionKey = "wb_env_schema_version"
    static let schemaVersion = 1

    static let defaultP1x = 137.00
    static let defaultP1y = 3500.0
    static let defaultP2x = 137.00
    static let defaultP2y = 3925.0
    static let defaultP3x = 141.15
    static let defaultP3y = 5800.0
    static let defaultP4x = 144.00
    static let defaultP4y = 6000.0
    static let defaultP5x = 146.00
    static let defaultP5y = 6000.0
    static let defaultP6x = 146.00
    static let defaultP6y = 4500.0
    static let defaultP7x = 140.00
    static let defaultP7y = 3500.0
    static let defaultQ1x = 141.26
    static let defaultQ1y = 5850.0
    static let defaultQ2x = 144.00
    static let defaultQ2y = 6050.0
    static let defaultQ3x = 146.00
    static let defaultQ3y = 6050.0
    static let defaultMZFW = 4850.0
    static let defaultMLW = 5800.0

    static let pointMeaning: [(String, String)] = [
        ("P1", "Lower forward corner of the flight envelope."),
        ("P2", "Start of forward CG limit rise."),
        ("P3", "Left start of upper operating region and MLW line."),
        ("P4", "Middle point on the top edge."),
        ("P5", "Right upper corner of the flight envelope."),
        ("P6", "Right lower transition point."),
        ("P7", "Lower aft corner before closing to P1."),
        ("Q1", "MRW chain transition from P3."),
        ("Q2", "MRW chain upper middle point."),
        ("Q3", "MRW chain upper right point connecting to P5.")
    ]
}

private enum WBArmConfig {
    static let pilotArm = "wb_arm_pilot"
    static let copilotArm = "wb_arm_copilot"
    static let passenger1Arm = "wb_arm_passenger1"
    static let passenger2Arm = "wb_arm_passenger2"
    static let passenger3Arm = "wb_arm_passenger3"
    static let passenger4Arm = "wb_arm_passenger4"
    static let seatConfiguration = "wb_arm_seat_configuration"
    static let fuelArmMethod = "wb_arm_fuel_arm_method"
    static let singleFuelArm = "wb_arm_single_fuel_arm"
    static let cargoArm = "wb_arm_cargo"
    static let aftOilStowageArm = "wb_arm_aft_oil_stowage"
    static let fuelDensityLbsPerGallon = "wb_arm_fuel_density_lbs_per_gal"
    static let fuelMinLookupGallons = "wb_arm_fuel_min_lookup_gallons"
    static let fuelMaxLookupGallons = "wb_arm_fuel_max_lookup_gallons"
    static let litersPerGallon = "wb_arm_liters_per_gallon"
    static let schemaVersionKey = "wb_arm_schema_version"
    static let schemaVersion = 1

    static let defaultPilotArm = 135.50
    static let defaultCopilotArm = 136.70
    static let defaultPassenger1Arm = 218.75
    static let defaultPassenger2Arm = 218.75
    static let defaultPassenger3Arm = 177.00
    static let defaultPassenger4Arm = 177.00
    static let defaultSeatConfiguration = WBSeatConfiguration.six.rawValue
    static let defaultFuelArmMethod = WBFuelArmMethod.lookupTable.rawValue
    static let defaultSingleFuelArm = 146.0
    static let defaultCargoArm = 248.23
    static let defaultAftOilStowageArm = 286.50
    static let defaultFuelDensityLbsPerGallon = 6.7
    static let defaultFuelMinLookupGallons = 5
    static let defaultFuelMaxLookupGallons = 260
    static let defaultLitersPerGallon = 3.78541
}

private enum WBSeatConfiguration: Int, CaseIterable, Identifiable {
    case four = 4
    case six = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .four: return "4 Seats"
        case .six: return "6 Seats"
        }
    }
}

private enum WBFuelArmMethod: String, CaseIterable, Identifiable {
    case lookupTable
    case singleArm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lookupTable: return "Lookup Table"
        case .singleArm: return "Single Arm"
        }
    }
}

private struct WBEnvelopeGeometry {
    let p1: CGPoint
    let p2: CGPoint
    let p3: CGPoint
    let p4: CGPoint
    let p5: CGPoint
    let p6: CGPoint
    let p7: CGPoint
    let q1: CGPoint
    let q2: CGPoint
    let q3: CGPoint
    let mzfw: Double
    let mlw: Double

    var flightEnvelope: [CGPoint] { [p1, p2, p3, p4, p5, p6, p7] }
    var closedFlightEnvelope: [CGPoint] { flightEnvelope + [p1] }
    var mrwChain: [CGPoint] { [p3, q1, q2, q3, p5] }

    func intersections(atY y: Double) -> [Double] {
        var xs: [Double] = []
        for i in 0..<flightEnvelope.count {
            let a = flightEnvelope[i]
            let b = flightEnvelope[(i + 1) % flightEnvelope.count]
            let y1 = a.y
            let y2 = b.y
            if abs(y2 - y1) < 0.000001 { continue }
            let ymin = min(y1, y2)
            let ymax = max(y1, y2)
            if y < ymin || y >= ymax { continue }
            let t = (CGFloat(y) - y1) / (y2 - y1)
            xs.append(Double(a.x + t * (b.x - a.x)))
        }
        return xs.sorted()
    }

    var mzfwSegment: (Double, Double)? {
        let xs = intersections(atY: mzfw)
        guard xs.count >= 2 else { return nil }
        return (xs[0], xs[xs.count - 1])
    }

    var mlwSegment: (Double, Double)? {
        let xs = intersections(atY: mlw)
        guard xs.count >= 2 else { return nil }
        let right = xs[xs.count - 1]
        let left = Double(p3.x)
        return left <= right ? (left, right) : (right, left)
    }

    var xDomain: ClosedRange<Double> {
        let values = (closedFlightEnvelope + mrwChain).map { Double($0.x) }
        let minX = values.min() ?? 137
        let maxX = values.max() ?? 146
        let span = max(maxX - minX, 1.0)
        let padding = max(0.8, span * 0.12)
        let lower = floor((minX - padding) * 2) / 2
        let upper = ceil((maxX + padding) * 2) / 2
        return lower...upper
    }

    var yDomain: ClosedRange<Double> {
        let values = (closedFlightEnvelope + mrwChain).map { Double($0.y) } + [mzfw, mlw]
        let minY = values.min() ?? 3500
        let maxY = values.max() ?? 6200
        let span = max(maxY - minY, 400.0)
        let padding = max(300.0, span * 0.14)
        let lower = floor((minY - padding) / 100.0) * 100.0
        let upper = ceil((maxY + padding) / 100.0) * 100.0
        return lower...upper
    }

    static func defaults() -> WBEnvelopeGeometry {
        WBEnvelopeGeometry(
            p1: CGPoint(x: WBEnvelopeConfig.defaultP1x, y: WBEnvelopeConfig.defaultP1y),
            p2: CGPoint(x: WBEnvelopeConfig.defaultP2x, y: WBEnvelopeConfig.defaultP2y),
            p3: CGPoint(x: WBEnvelopeConfig.defaultP3x, y: WBEnvelopeConfig.defaultP3y),
            p4: CGPoint(x: WBEnvelopeConfig.defaultP4x, y: WBEnvelopeConfig.defaultP4y),
            p5: CGPoint(x: WBEnvelopeConfig.defaultP5x, y: WBEnvelopeConfig.defaultP5y),
            p6: CGPoint(x: WBEnvelopeConfig.defaultP6x, y: WBEnvelopeConfig.defaultP6y),
            p7: CGPoint(x: WBEnvelopeConfig.defaultP7x, y: WBEnvelopeConfig.defaultP7y),
            q1: CGPoint(x: WBEnvelopeConfig.defaultQ1x, y: WBEnvelopeConfig.defaultQ1y),
            q2: CGPoint(x: WBEnvelopeConfig.defaultQ2x, y: WBEnvelopeConfig.defaultQ2y),
            q3: CGPoint(x: WBEnvelopeConfig.defaultQ3x, y: WBEnvelopeConfig.defaultQ3y),
            mzfw: WBEnvelopeConfig.defaultMZFW,
            mlw: WBEnvelopeConfig.defaultMLW
        )
    }
}

private func consecutiveSegments(_ points: [CGPoint]) -> [(CGPoint, CGPoint)] {
    guard points.count > 1 else { return [] }
    return Array(zip(points.dropLast(), points.dropFirst()))
}

private func applyWBEnvelopeDefaults(_ defaults: UserDefaults = .standard) {
    defaults.set(WBEnvelopeConfig.defaultP1x, forKey: WBEnvelopeConfig.p1x)
    defaults.set(WBEnvelopeConfig.defaultP1y, forKey: WBEnvelopeConfig.p1y)
    defaults.set(WBEnvelopeConfig.defaultP2x, forKey: WBEnvelopeConfig.p2x)
    defaults.set(WBEnvelopeConfig.defaultP2y, forKey: WBEnvelopeConfig.p2y)
    defaults.set(WBEnvelopeConfig.defaultP3x, forKey: WBEnvelopeConfig.p3x)
    defaults.set(WBEnvelopeConfig.defaultP3y, forKey: WBEnvelopeConfig.p3y)
    defaults.set(WBEnvelopeConfig.defaultP4x, forKey: WBEnvelopeConfig.p4x)
    defaults.set(WBEnvelopeConfig.defaultP4y, forKey: WBEnvelopeConfig.p4y)
    defaults.set(WBEnvelopeConfig.defaultP5x, forKey: WBEnvelopeConfig.p5x)
    defaults.set(WBEnvelopeConfig.defaultP5y, forKey: WBEnvelopeConfig.p5y)
    defaults.set(WBEnvelopeConfig.defaultP6x, forKey: WBEnvelopeConfig.p6x)
    defaults.set(WBEnvelopeConfig.defaultP6y, forKey: WBEnvelopeConfig.p6y)
    defaults.set(WBEnvelopeConfig.defaultP7x, forKey: WBEnvelopeConfig.p7x)
    defaults.set(WBEnvelopeConfig.defaultP7y, forKey: WBEnvelopeConfig.p7y)
    defaults.set(WBEnvelopeConfig.defaultQ1x, forKey: WBEnvelopeConfig.q1x)
    defaults.set(WBEnvelopeConfig.defaultQ1y, forKey: WBEnvelopeConfig.q1y)
    defaults.set(WBEnvelopeConfig.defaultQ2x, forKey: WBEnvelopeConfig.q2x)
    defaults.set(WBEnvelopeConfig.defaultQ2y, forKey: WBEnvelopeConfig.q2y)
    defaults.set(WBEnvelopeConfig.defaultQ3x, forKey: WBEnvelopeConfig.q3x)
    defaults.set(WBEnvelopeConfig.defaultQ3y, forKey: WBEnvelopeConfig.q3y)
    defaults.set(WBEnvelopeConfig.defaultMZFW, forKey: WBEnvelopeConfig.mzfw)
    defaults.set(WBEnvelopeConfig.defaultMLW, forKey: WBEnvelopeConfig.mlw)
}

private func migrateWBEnvelopeIfNeeded(_ defaults: UserDefaults = .standard) {
    let currentVersion = defaults.integer(forKey: WBEnvelopeConfig.schemaVersionKey)
    guard currentVersion < WBEnvelopeConfig.schemaVersion else { return }
    applyWBEnvelopeDefaults(defaults)
    defaults.set(WBEnvelopeConfig.schemaVersion, forKey: WBEnvelopeConfig.schemaVersionKey)
}

private func applyWBArmDefaults(_ defaults: UserDefaults = .standard) {
    defaults.set(WBArmConfig.defaultPilotArm, forKey: WBArmConfig.pilotArm)
    defaults.set(WBArmConfig.defaultCopilotArm, forKey: WBArmConfig.copilotArm)
    defaults.set(WBArmConfig.defaultPassenger1Arm, forKey: WBArmConfig.passenger1Arm)
    defaults.set(WBArmConfig.defaultPassenger2Arm, forKey: WBArmConfig.passenger2Arm)
    defaults.set(WBArmConfig.defaultPassenger3Arm, forKey: WBArmConfig.passenger3Arm)
    defaults.set(WBArmConfig.defaultPassenger4Arm, forKey: WBArmConfig.passenger4Arm)
    defaults.set(WBArmConfig.defaultSeatConfiguration, forKey: WBArmConfig.seatConfiguration)
    defaults.set(WBArmConfig.defaultFuelArmMethod, forKey: WBArmConfig.fuelArmMethod)
    defaults.set(WBArmConfig.defaultSingleFuelArm, forKey: WBArmConfig.singleFuelArm)
    defaults.set(WBArmConfig.defaultCargoArm, forKey: WBArmConfig.cargoArm)
    defaults.set(WBArmConfig.defaultAftOilStowageArm, forKey: WBArmConfig.aftOilStowageArm)
    defaults.set(WBArmConfig.defaultFuelDensityLbsPerGallon, forKey: WBArmConfig.fuelDensityLbsPerGallon)
    defaults.set(WBArmConfig.defaultFuelMinLookupGallons, forKey: WBArmConfig.fuelMinLookupGallons)
    defaults.set(WBArmConfig.defaultFuelMaxLookupGallons, forKey: WBArmConfig.fuelMaxLookupGallons)
    defaults.set(WBArmConfig.defaultLitersPerGallon, forKey: WBArmConfig.litersPerGallon)
    WBFuelArmStore.applyDefaults(defaults)
}

private func migrateWBArmDataIfNeeded(_ defaults: UserDefaults = .standard) {
    let currentVersion = defaults.integer(forKey: WBArmConfig.schemaVersionKey)
    guard currentVersion < WBArmConfig.schemaVersion else { return }
    applyWBArmDefaults(defaults)
    defaults.set(WBArmConfig.schemaVersion, forKey: WBArmConfig.schemaVersionKey)
}

private struct ResetAcknowledgmentBanner: View {
    var body: some View {
        Text("Data have been reset")
            .font(.custom("Avenir Next Demi Bold", size: 13))
            .foregroundColor(AppTheme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentSoft, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

private enum WBEditablePoint: String, CaseIterable, Identifiable {
    case p1, p2, p3, p4, p5, p6, p7, q1, q2, q3

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

private enum WBUnlockDestination {
    case armDataModification
}

struct WBInitialSetupView: View {
    @AppStorage("basicEmptyWeight") private var basicEmptyWeight: String = "3766.930"
    @AppStorage("emptyCG") private var emptyCG: String = "138.119"
    @AppStorage("wbDefaultsApplied") private var wbDefaultsApplied: Bool = false
    @AppStorage(WBEnvelopeConfig.p1x) private var p1x = WBEnvelopeConfig.defaultP1x
    @AppStorage(WBEnvelopeConfig.p1y) private var p1y = WBEnvelopeConfig.defaultP1y
    @AppStorage(WBEnvelopeConfig.p2x) private var p2x = WBEnvelopeConfig.defaultP2x
    @AppStorage(WBEnvelopeConfig.p2y) private var p2y = WBEnvelopeConfig.defaultP2y
    @AppStorage(WBEnvelopeConfig.p3x) private var p3x = WBEnvelopeConfig.defaultP3x
    @AppStorage(WBEnvelopeConfig.p3y) private var p3y = WBEnvelopeConfig.defaultP3y
    @AppStorage(WBEnvelopeConfig.p4x) private var p4x = WBEnvelopeConfig.defaultP4x
    @AppStorage(WBEnvelopeConfig.p4y) private var p4y = WBEnvelopeConfig.defaultP4y
    @AppStorage(WBEnvelopeConfig.p5x) private var p5x = WBEnvelopeConfig.defaultP5x
    @AppStorage(WBEnvelopeConfig.p5y) private var p5y = WBEnvelopeConfig.defaultP5y
    @AppStorage(WBEnvelopeConfig.p6x) private var p6x = WBEnvelopeConfig.defaultP6x
    @AppStorage(WBEnvelopeConfig.p6y) private var p6y = WBEnvelopeConfig.defaultP6y
    @AppStorage(WBEnvelopeConfig.p7x) private var p7x = WBEnvelopeConfig.defaultP7x
    @AppStorage(WBEnvelopeConfig.p7y) private var p7y = WBEnvelopeConfig.defaultP7y
    @AppStorage(WBEnvelopeConfig.q1x) private var q1x = WBEnvelopeConfig.defaultQ1x
    @AppStorage(WBEnvelopeConfig.q1y) private var q1y = WBEnvelopeConfig.defaultQ1y
    @AppStorage(WBEnvelopeConfig.q2x) private var q2x = WBEnvelopeConfig.defaultQ2x
    @AppStorage(WBEnvelopeConfig.q2y) private var q2y = WBEnvelopeConfig.defaultQ2y
    @AppStorage(WBEnvelopeConfig.q3x) private var q3x = WBEnvelopeConfig.defaultQ3x
    @AppStorage(WBEnvelopeConfig.q3y) private var q3y = WBEnvelopeConfig.defaultQ3y
    @AppStorage(WBEnvelopeConfig.mzfw) private var mzfw = WBEnvelopeConfig.defaultMZFW
    @AppStorage(WBEnvelopeConfig.mlw) private var mlw = WBEnvelopeConfig.defaultMLW
    @AppStorage("editPasscode") private var editPasscode: String = ""
    @State private var editingPoint: WBEditablePoint?
    @State private var editingPopupAnchor: CGPoint?
    @State private var editingCG = ""
    @State private var editingWeight = ""
    @State private var editPointError: String?
    @State private var mzfwText = ""
    @State private var mlwText = ""
    @State private var setupUnlocked = false
    @State private var showUnlockPopup = false
    @State private var unlockInput = ""
    @State private var newPasscodeInput = ""
    @State private var unlockError: String?
    @State private var unlockDestination: WBUnlockDestination?
    @State private var goToArmDataModification = false
    @State private var showResetAcknowledgment = false

    private var isEditingLocked: Bool {
        !setupUnlocked
    }

    var body: some View {
        List {
            Section {
                lockableField {
                    InstrumentCompactTextField(
                    title: "Basic Empty Weight (lbs)",
                    text: $basicEmptyWeight,
                    keyboard: .decimalPad,
                    isEnabled: true
                )
                }

                lockableField {
                    InstrumentCompactTextField(
                    title: "Empty CG (inches aft of datum)",
                    text: $emptyCG,
                    keyboard: .decimalPad,
                    isEnabled: true
                )
                }

                lockableField {
                    InstrumentCompactTextField(
                    title: "Maximum Zero Fuel Weight (lbs)",
                    text: $mzfwText,
                    keyboard: .decimalPad,
                    isEnabled: true
                )
                }
                .onChange(of: mzfwText) { newValue in
                    if let parsed = parseLimitValue(newValue) {
                        mzfw = parsed
                    }
                }

                lockableField {
                    InstrumentCompactTextField(
                    title: "Maximum Landing Weight (lbs)",
                    text: $mlwText,
                    keyboard: .decimalPad,
                    isEnabled: true
                )
                }
                .onChange(of: mlwText) { newValue in
                    if let parsed = parseLimitValue(newValue) {
                        mlw = parsed
                    }
                }

                Button {
                    if isEditingLocked {
                        presentUnlockPrompt(afterUnlock: .armDataModification)
                    } else {
                        goToArmDataModification = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(AppTheme.backgroundTop.opacity(0.72))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Arm Data Modification")
                                .font(.custom("Avenir Next Demi Bold", size: 14))
                                .foregroundColor(AppTheme.text)
                            Text("Tap to edit arm constants and fuel arm data.")
                                .font(.custom("Avenir Next Regular", size: 11))
                                .foregroundColor(AppTheme.muted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.muted)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Section {
                initialEnvelopePreview
            } header: {
                Text("Live Envelope Preview")
            } footer: {
                Text("Tap any point label (P1...Q3) to edit CG and Weight. Labels are offset to stay readable.")
            }

            Section {
                Button(role: .destructive) {
                    if isEditingLocked {
                        presentUnlockPrompt()
                    } else {
                        resetEnvelopeDefaults()
                    }
                } label: {
                    Text("Reset Defaults")
                }
            } footer: {
                Text("Restores all Initial Setup defaults, including envelope points, arm constants, and fuel lookup values.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Initial Aircraft Setup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            migrateWBEnvelopeIfNeeded()
            migrateWBArmDataIfNeeded()
            applyDefaultsIfNeeded()
            syncLimitTextFields()
        }
        .navigationDestination(isPresented: $goToArmDataModification) {
            WBArmDataModificationView()
        }
        .onChange(of: mzfw) { newValue in
            let formatted = formatLimitValue(newValue)
            if mzfwText != formatted {
                mzfwText = formatted
            }
        }
        .onChange(of: mlw) { newValue in
            let formatted = formatLimitValue(newValue)
            if mlwText != formatted {
                mlwText = formatted
            }
        }
        .overlay {
            ZStack(alignment: .top) {
                if showResetAcknowledgment {
                    ResetAcknowledgmentBanner()
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showUnlockPopup {
                    unlockOverlay
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showResetAcknowledgment)
    }

    private func applyDefaultsIfNeeded() {
        if !wbDefaultsApplied || basicEmptyWeight.isEmpty || emptyCG.isEmpty {
            basicEmptyWeight = "3766.930"
            emptyCG = "138.119"
            wbDefaultsApplied = true
        }
    }

    private func resetEnvelopeDefaults() {
        basicEmptyWeight = "3766.930"
        emptyCG = "138.119"
        wbDefaultsApplied = true

        p1x = WBEnvelopeConfig.defaultP1x; p1y = WBEnvelopeConfig.defaultP1y
        p2x = WBEnvelopeConfig.defaultP2x; p2y = WBEnvelopeConfig.defaultP2y
        p3x = WBEnvelopeConfig.defaultP3x; p3y = WBEnvelopeConfig.defaultP3y
        p4x = WBEnvelopeConfig.defaultP4x; p4y = WBEnvelopeConfig.defaultP4y
        p5x = WBEnvelopeConfig.defaultP5x; p5y = WBEnvelopeConfig.defaultP5y
        p6x = WBEnvelopeConfig.defaultP6x; p6y = WBEnvelopeConfig.defaultP6y
        p7x = WBEnvelopeConfig.defaultP7x; p7y = WBEnvelopeConfig.defaultP7y
        q1x = WBEnvelopeConfig.defaultQ1x; q1y = WBEnvelopeConfig.defaultQ1y
        q2x = WBEnvelopeConfig.defaultQ2x; q2y = WBEnvelopeConfig.defaultQ2y
        q3x = WBEnvelopeConfig.defaultQ3x; q3y = WBEnvelopeConfig.defaultQ3y
        mzfw = WBEnvelopeConfig.defaultMZFW
        mlw = WBEnvelopeConfig.defaultMLW
        applyWBArmDefaults()
        syncLimitTextFields()
        showResetAcknowledgmentBanner()
    }

    private func parseLimitValue(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private func formatLimitValue(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func syncLimitTextFields() {
        mzfwText = formatLimitValue(mzfw)
        mlwText = formatLimitValue(mlw)
    }

    private func showResetAcknowledgmentBanner() {
        showResetAcknowledgment = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showResetAcknowledgment = false
        }
    }

    private var initialPreviewGeometry: WBEnvelopeGeometry {
        WBEnvelopeGeometry(
            p1: CGPoint(x: p1x, y: p1y),
            p2: CGPoint(x: p2x, y: p2y),
            p3: CGPoint(x: p3x, y: p3y),
            p4: CGPoint(x: p4x, y: p4y),
            p5: CGPoint(x: p5x, y: p5y),
            p6: CGPoint(x: p6x, y: p6y),
            p7: CGPoint(x: p7x, y: p7y),
            q1: CGPoint(x: q1x, y: q1y),
            q2: CGPoint(x: q2x, y: q2y),
            q3: CGPoint(x: q3x, y: q3y),
            mzfw: mzfw,
            mlw: mlw
        )
    }

    private var initialEnvelopePreview: some View {
        let envelopeColor = Color(red: 0.48, green: 0.80, blue: 1.00)
        return Chart {
            ForEach(Array(consecutiveSegments(initialPreviewGeometry.closedFlightEnvelope).enumerated()), id: \.offset) { index, segment in
                let points = [segment.0, segment.1]
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("CG", Double(point.x)),
                        y: .value("Weight", Double(point.y)),
                        series: .value("Edge", "init-edge-\(index)")
                    )
                    .foregroundStyle(envelopeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }

            ForEach(Array(consecutiveSegments(initialPreviewGeometry.mrwChain).enumerated()), id: \.offset) { index, segment in
                let points = [segment.0, segment.1]
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("CG", Double(point.x)),
                        y: .value("Weight", Double(point.y)),
                        series: .value("MRW", "init-mrw-\(index)")
                    )
                    .foregroundStyle(envelopeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 5]))
                }
            }

            if let segment = initialPreviewGeometry.mzfwSegment {
                ForEach([segment.0, segment.1], id: \.self) { x in
                    LineMark(
                        x: .value("CG", x),
                        y: .value("Weight", mzfw),
                        series: .value("Limit", "init-mzfw")
                    )
                    .foregroundStyle(Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }

            if let segment = initialPreviewGeometry.mlwSegment {
                ForEach([segment.0, segment.1], id: \.self) { x in
                    LineMark(
                        x: .value("CG", x),
                        y: .value("Weight", mlw),
                        series: .value("Limit", "init-mlw")
                    )
                    .foregroundStyle(Color.white)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }

        }
        .chartXScale(domain: initialPreviewGeometry.xDomain)
        .chartYScale(domain: initialPreviewGeometry.yDomain)
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.18))
                AxisTick()
                    .foregroundStyle(Color.white.opacity(0.45))
                AxisValueLabel()
                    .font(.custom("Avenir Next Regular", size: 10))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.18))
                AxisTick()
                    .foregroundStyle(Color.white.opacity(0.45))
                AxisValueLabel()
                    .font(.custom("Avenir Next Regular", size: 10))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                let plotFrame = geo[proxy.plotAreaFrame]
                ZStack(alignment: .topLeading) {
                    if editingPoint != nil {
                        Rectangle()
                            .fill(Color.black.opacity(0.001))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismissPointEditing()
                            }
                    }

                    ForEach(initialPreviewPointLabels, id: \.id) { item in
                        if
                            let xPos = proxy.position(forX: Double(item.point.x)),
                            let yPos = proxy.position(forY: Double(item.point.y))
                        {
                            let anchorX = plotFrame.minX + xPos
                            let anchorY = plotFrame.minY + yPos
                            let offset = previewLabelOffset(for: item.id)
                            let labelAnchor = CGPoint(x: anchorX + offset.width, y: anchorY + offset.height)
                            let isActive = editingPoint == item.id

                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 5, height: 5)
                                .position(x: anchorX, y: anchorY)

                            Button {
                                if isEditingLocked {
                                    presentUnlockPrompt()
                                } else {
                                    beginEditing(item.id, anchor: labelAnchor)
                                }
                            } label: {
                                Text(item.id.label)
                                    .font(.custom("Avenir Next Demi Bold", size: 10))
                                    .foregroundColor(AppTheme.text)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(AppTheme.card.opacity(0.95))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(isActive ? AppTheme.accent : AppTheme.accentSoft, lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .position(x: labelAnchor.x, y: labelAnchor.y)
                        }
                    }

                    if let point = editingPoint, let anchor = editingPopupAnchor {
                        pointEditorPopup(for: point)
                            .frame(width: pointEditorPopupSize.width)
                            .position(popupPosition(for: anchor, in: geo.size))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .frame(height: 220)
        .padding(.vertical, 6)
    }

    private var initialPreviewPointLabels: [(id: WBEditablePoint, point: CGPoint)] {
        [
            (.p1, initialPreviewGeometry.p1),
            (.p2, initialPreviewGeometry.p2),
            (.p3, initialPreviewGeometry.p3),
            (.p4, initialPreviewGeometry.p4),
            (.p5, initialPreviewGeometry.p5),
            (.p6, initialPreviewGeometry.p6),
            (.p7, initialPreviewGeometry.p7),
            (.q1, initialPreviewGeometry.q1),
            (.q2, initialPreviewGeometry.q2),
            (.q3, initialPreviewGeometry.q3)
        ]
    }

    private func previewLabelOffset(for point: WBEditablePoint) -> CGSize {
        switch point {
        case .p1: return CGSize(width: -18, height: 14)
        case .p2: return CGSize(width: -22, height: -2)
        case .p3: return CGSize(width: -20, height: 12)
        case .p4: return CGSize(width: -2, height: 12)
        case .p5: return CGSize(width: 16, height: 10)
        case .p6: return CGSize(width: 20, height: 0)
        case .p7: return CGSize(width: 2, height: 14)
        case .q1: return CGSize(width: -8, height: -20)
        case .q2: return CGSize(width: 0, height: -22)
        case .q3: return CGSize(width: 12, height: -22)
        }
    }

    private var pointEditorPopupSize: CGSize {
        CGSize(width: 220, height: 185)
    }

    private func popupPosition(for anchor: CGPoint, in size: CGSize) -> CGPoint {
        let halfWidth = pointEditorPopupSize.width / 2
        let halfHeight = pointEditorPopupSize.height / 2
        let edgePadding: CGFloat = 12
        let preferred = CGPoint(x: anchor.x + 78, y: anchor.y - 58)
        let x = min(max(preferred.x, halfWidth + edgePadding), size.width - halfWidth - edgePadding)
        let y = min(max(preferred.y, halfHeight + edgePadding), size.height - halfHeight - edgePadding)
        return CGPoint(x: x, y: y)
    }

    @ViewBuilder
    private func pointEditorPopup(for point: WBEditablePoint) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Edit \(point.label)")
                    .font(.custom("Avenir Next Demi Bold", size: 14))
                    .foregroundColor(AppTheme.text)
                Spacer()
                Button {
                    dismissPointEditing()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.muted)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(AppTheme.cardHighlight)
                        )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Text("CG")
                    .font(.custom("Avenir Next Demi Bold", size: 12))
                    .foregroundColor(AppTheme.muted)
                    .frame(width: 32, alignment: .leading)
                TextField("CG", text: $editingCG)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.backgroundTop.opacity(0.72))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .foregroundColor(AppTheme.text)
            }

            HStack(spacing: 8) {
                Text("W")
                    .font(.custom("Avenir Next Demi Bold", size: 12))
                    .foregroundColor(AppTheme.muted)
                    .frame(width: 32, alignment: .leading)
                TextField("Weight", text: $editingWeight)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.backgroundTop.opacity(0.72))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .foregroundColor(AppTheme.text)
            }

            if let editPointError {
                Text(editPointError)
                    .font(.custom("Avenir Next Regular", size: 11))
                    .foregroundColor(.red)
            }

            HStack(spacing: 8) {
                Button("Cancel") {
                    dismissPointEditing()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.cardHighlight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.accentSoft, lineWidth: 1)
                        )
                )
                .foregroundColor(AppTheme.text)
                .font(.custom("Avenir Next Demi Bold", size: 12))

                Button("Save") {
                    saveEditedPoint(point)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(AppTheme.accent)
                .foregroundColor(.black)
                .cornerRadius(8)
                .font(.custom("Avenir Next Demi Bold", size: 12))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.bezelLight, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 9, x: 0, y: 6)
    }

    private func beginEditing(_ point: WBEditablePoint, anchor: CGPoint) {
        let values = valuesForPoint(point)
        editingCG = String(format: "%.2f", values.cg)
        editingWeight = String(format: "%.0f", values.weight)
        editPointError = nil
        editingPoint = point
        editingPopupAnchor = anchor
    }

    private func dismissPointEditing() {
        editingPoint = nil
        editingPopupAnchor = nil
        editPointError = nil
    }

    private func presentUnlockPrompt(afterUnlock destination: WBUnlockDestination? = nil) {
        unlockDestination = destination
        unlockInput = ""
        newPasscodeInput = ""
        unlockError = nil
        showUnlockPopup = true
    }

    private func completeUnlockSuccess() {
        setupUnlocked = true
        showUnlockPopup = false
        unlockError = nil
        if unlockDestination == .armDataModification {
            goToArmDataModification = true
        }
        unlockDestination = nil
    }

    private func handleUnlockSubmit() {
        if editPasscode.isEmpty {
            let trimmed = newPasscodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                unlockError = "Enter a new passcode."
                return
            }
            editPasscode = trimmed
            completeUnlockSuccess()
            return
        }

        if unlockInput == editPasscode {
            completeUnlockSuccess()
        } else {
            unlockError = "Incorrect passcode."
        }
    }

    @ViewBuilder
    private func lockableField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            content()
                .disabled(isEditingLocked)
            if isEditingLocked {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        presentUnlockPrompt()
                    }
            }
        }
    }

    private var unlockOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    showUnlockPopup = false
                    unlockError = nil
                    unlockDestination = nil
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Are you sure?")
                    .font(.custom("Avenir Next Demi Bold", size: 16))
                    .foregroundColor(AppTheme.text)

                if editPasscode.isEmpty {
                    Text("No passcode is set. Enter a new passcode to unlock setup editing.")
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(AppTheme.muted)

                    SecureField("New Passcode", text: $newPasscodeInput)
                        .textContentType(.newPassword)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.backgroundTop.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                } else {
                    Text("Enter passcode to unlock setup editing.")
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(AppTheme.muted)

                    SecureField("Passcode", text: $unlockInput)
                        .textContentType(.password)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppTheme.backgroundTop.opacity(0.75))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                }

                if let unlockError {
                    Text(unlockError)
                        .font(.custom("Avenir Next Regular", size: 12))
                        .foregroundColor(.red)
                }

                HStack(spacing: 10) {
                    Button("Cancel") {
                        showUnlockPopup = false
                        unlockError = nil
                        unlockDestination = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.cardHighlight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.accentSoft, lineWidth: 1)
                            )
                    )
                    .foregroundColor(AppTheme.text)

                    Button(editPasscode.isEmpty ? "Set & Unlock" : "Unlock") {
                        handleUnlockSubmit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.bezelLight, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 12, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private func valuesForPoint(_ point: WBEditablePoint) -> (cg: Double, weight: Double) {
        switch point {
        case .p1: return (p1x, p1y)
        case .p2: return (p2x, p2y)
        case .p3: return (p3x, p3y)
        case .p4: return (p4x, p4y)
        case .p5: return (p5x, p5y)
        case .p6: return (p6x, p6y)
        case .p7: return (p7x, p7y)
        case .q1: return (q1x, q1y)
        case .q2: return (q2x, q2y)
        case .q3: return (q3x, q3y)
        }
    }

    private func saveEditedPoint(_ point: WBEditablePoint) {
        guard
            let cg = Double(editingCG.trimmingCharacters(in: .whitespacesAndNewlines)),
            let weight = Double(editingWeight.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            editPointError = "Enter valid numeric values."
            return
        }

        switch point {
        case .p1: p1x = cg; p1y = weight
        case .p2: p2x = cg; p2y = weight
        case .p3: p3x = cg; p3y = weight
        case .p4: p4x = cg; p4y = weight
        case .p5: p5x = cg; p5y = weight
        case .p6: p6x = cg; p6y = weight
        case .p7: p7x = cg; p7y = weight
        case .q1: q1x = cg; q1y = weight
        case .q2: q2x = cg; q2y = weight
        case .q3: q3x = cg; q3y = weight
        }

        dismissPointEditing()
    }
}

private struct WBArmNumericRow: View {
    let title: String
    @Binding var value: Double
    let decimals: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.custom("Avenir Next Regular", size: 14))
                .foregroundColor(AppTheme.text)
            Spacer()
            TextField("", value: $value, format: .number.precision(.fractionLength(decimals)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: 120)
            Text("in")
                .font(.custom("Avenir Next Regular", size: 13))
                .foregroundColor(AppTheme.muted)
        }
        .padding(.vertical, 2)
    }
}

struct WBArmDataModificationView: View {
    @AppStorage(WBArmConfig.pilotArm) private var pilotArm = WBArmConfig.defaultPilotArm
    @AppStorage(WBArmConfig.copilotArm) private var copilotArm = WBArmConfig.defaultCopilotArm
    @AppStorage(WBArmConfig.passenger1Arm) private var passenger1Arm = WBArmConfig.defaultPassenger1Arm
    @AppStorage(WBArmConfig.passenger2Arm) private var passenger2Arm = WBArmConfig.defaultPassenger2Arm
    @AppStorage(WBArmConfig.passenger3Arm) private var passenger3Arm = WBArmConfig.defaultPassenger3Arm
    @AppStorage(WBArmConfig.passenger4Arm) private var passenger4Arm = WBArmConfig.defaultPassenger4Arm
    @AppStorage(WBArmConfig.seatConfiguration) private var seatConfigurationRaw = WBArmConfig.defaultSeatConfiguration
    @AppStorage(WBArmConfig.fuelArmMethod) private var fuelArmMethodRaw = WBArmConfig.defaultFuelArmMethod
    @AppStorage(WBArmConfig.singleFuelArm) private var singleFuelArm = WBArmConfig.defaultSingleFuelArm
    @AppStorage(WBArmConfig.cargoArm) private var cargoArm = WBArmConfig.defaultCargoArm
    @AppStorage(WBArmConfig.aftOilStowageArm) private var aftOilStowageArm = WBArmConfig.defaultAftOilStowageArm
    @State private var fuelArmValues: [Int: Double] = [:]

    private var lookupGallons: [Int] { WBFuelArmStore.allGallons }
    private var seatConfiguration: WBSeatConfiguration {
        WBSeatConfiguration(rawValue: seatConfigurationRaw) ?? .six
    }
    private var seatConfigurationBinding: Binding<WBSeatConfiguration> {
        Binding(
            get: { seatConfiguration },
            set: { seatConfigurationRaw = $0.rawValue }
        )
    }
    private var fuelArmMethod: WBFuelArmMethod {
        WBFuelArmMethod(rawValue: fuelArmMethodRaw) ?? .lookupTable
    }
    private var fuelArmMethodBinding: Binding<WBFuelArmMethod> {
        Binding(
            get: { fuelArmMethod },
            set: { fuelArmMethodRaw = $0.rawValue }
        )
    }

    var body: some View {
        List {
            Section {
                Picker("Seat Configuration", selection: seatConfigurationBinding) {
                    ForEach(WBSeatConfiguration.allCases.sorted(by: { $0.rawValue > $1.rawValue })) { configuration in
                        Text(configuration.title).tag(configuration)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Seat Configuration")
            } footer: {
                Text("Default is 6 seats. In 4-seat mode, front passenger entries are hidden and excluded from Weight & Balance calculations.")
            }

            Section {
                WBArmNumericRow(title: "Pilot Arm", value: $pilotArm, decimals: 2)
                WBArmNumericRow(title: "Copilot Arm", value: $copilotArm, decimals: 2)
                if seatConfiguration == .six {
                    WBArmNumericRow(title: "Front Passenger Left Arm", value: $passenger3Arm, decimals: 2)
                    WBArmNumericRow(title: "Front Passenger Right Arm", value: $passenger4Arm, decimals: 2)
                }
                WBArmNumericRow(title: "Rear Passenger Left Arm", value: $passenger1Arm, decimals: 2)
                WBArmNumericRow(title: "Rear Passenger Right Arm", value: $passenger2Arm, decimals: 2)
                WBArmNumericRow(title: "Cargo Arm", value: $cargoArm, decimals: 2)
                WBArmNumericRow(title: "Aft Oil Stowage Arm", value: $aftOilStowageArm, decimals: 2)
            } header: {
                Text("Arm Constants")
            }

            Section {
                Picker("Fuel Arm Method", selection: fuelArmMethodBinding) {
                    ForEach(WBFuelArmMethod.allCases) { method in
                        Text(method.title).tag(method)
                    }
                }
                .pickerStyle(.segmented)

                if fuelArmMethod == .singleArm {
                    WBArmNumericRow(title: "Fuel Arm", value: $singleFuelArm, decimals: 1)
                }
            } header: {
                Text("Fuel Arm Method")
            } footer: {
                Text("Choose lookup table interpolation or a fixed single fuel arm.")
            }

            if fuelArmMethod == .lookupTable {
                Section {
                    ForEach(lookupGallons, id: \.self) { gallon in
                        HStack(spacing: 10) {
                            Text("\(gallon)")
                                .font(.custom("Avenir Next Demi Bold", size: 13))
                                .foregroundColor(AppTheme.text)
                                .frame(width: 42, alignment: .leading)
                            Text("gal")
                                .font(.custom("Avenir Next Regular", size: 12))
                                .foregroundColor(AppTheme.muted)
                            Spacer()
                            TextField("Arm", value: fuelArmBinding(for: gallon), format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppTheme.text)
                                .frame(maxWidth: 120)
                            Text("in")
                                .font(.custom("Avenir Next Regular", size: 12))
                                .foregroundColor(AppTheme.muted)
                        }
                    }
                } header: {
                    Text("Fuel Arm Lookup Table")
                } footer: {
                    Text("These values are used for fuel-moment interpolation by gallon.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Arm Data Modification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            migrateWBArmDataIfNeeded()
            loadFuelArmValues()
        }
    }

    private func loadFuelArmValues() {
        var values: [Int: Double] = [:]
        for gallon in lookupGallons {
            values[gallon] = WBFuelArmStore.value(for: gallon)
        }
        fuelArmValues = values
    }

    private func fuelArmBinding(for gallon: Int) -> Binding<Double> {
        Binding(
            get: { fuelArmValues[gallon] ?? WBFuelArmStore.value(for: gallon) },
            set: { newValue in
                fuelArmValues[gallon] = newValue
                WBFuelArmStore.set(newValue, for: gallon)
            }
        )
    }
}

struct WBEnvelopeSetupView: View {
    @AppStorage(WBEnvelopeConfig.p1x) private var p1x = WBEnvelopeConfig.defaultP1x
    @AppStorage(WBEnvelopeConfig.p1y) private var p1y = WBEnvelopeConfig.defaultP1y
    @AppStorage(WBEnvelopeConfig.p2x) private var p2x = WBEnvelopeConfig.defaultP2x
    @AppStorage(WBEnvelopeConfig.p2y) private var p2y = WBEnvelopeConfig.defaultP2y
    @AppStorage(WBEnvelopeConfig.p3x) private var p3x = WBEnvelopeConfig.defaultP3x
    @AppStorage(WBEnvelopeConfig.p3y) private var p3y = WBEnvelopeConfig.defaultP3y
    @AppStorage(WBEnvelopeConfig.p4x) private var p4x = WBEnvelopeConfig.defaultP4x
    @AppStorage(WBEnvelopeConfig.p4y) private var p4y = WBEnvelopeConfig.defaultP4y
    @AppStorage(WBEnvelopeConfig.p5x) private var p5x = WBEnvelopeConfig.defaultP5x
    @AppStorage(WBEnvelopeConfig.p5y) private var p5y = WBEnvelopeConfig.defaultP5y
    @AppStorage(WBEnvelopeConfig.p6x) private var p6x = WBEnvelopeConfig.defaultP6x
    @AppStorage(WBEnvelopeConfig.p6y) private var p6y = WBEnvelopeConfig.defaultP6y
    @AppStorage(WBEnvelopeConfig.p7x) private var p7x = WBEnvelopeConfig.defaultP7x
    @AppStorage(WBEnvelopeConfig.p7y) private var p7y = WBEnvelopeConfig.defaultP7y
    @AppStorage(WBEnvelopeConfig.q1x) private var q1x = WBEnvelopeConfig.defaultQ1x
    @AppStorage(WBEnvelopeConfig.q1y) private var q1y = WBEnvelopeConfig.defaultQ1y
    @AppStorage(WBEnvelopeConfig.q2x) private var q2x = WBEnvelopeConfig.defaultQ2x
    @AppStorage(WBEnvelopeConfig.q2y) private var q2y = WBEnvelopeConfig.defaultQ2y
    @AppStorage(WBEnvelopeConfig.q3x) private var q3x = WBEnvelopeConfig.defaultQ3x
    @AppStorage(WBEnvelopeConfig.q3y) private var q3y = WBEnvelopeConfig.defaultQ3y
    @AppStorage(WBEnvelopeConfig.mzfw) private var mzfw = WBEnvelopeConfig.defaultMZFW
    @AppStorage(WBEnvelopeConfig.mlw) private var mlw = WBEnvelopeConfig.defaultMLW
    @State private var showResetAcknowledgment = false

    var body: some View {
        List {
            Section {
                EnvelopeCoordinateRow(title: "P1", subtitle: "Lower forward corner", xValue: $p1x, yValue: $p1y)
                EnvelopeCoordinateRow(title: "P2", subtitle: "Forward limit rise starts", xValue: $p2x, yValue: $p2y)
                EnvelopeCoordinateRow(title: "P3", subtitle: "Upper left (MLW line starts here)", xValue: $p3x, yValue: $p3y)
                EnvelopeCoordinateRow(title: "P4", subtitle: "Top edge middle", xValue: $p4x, yValue: $p4y)
                EnvelopeCoordinateRow(title: "P5", subtitle: "Top right corner", xValue: $p5x, yValue: $p5y)
                EnvelopeCoordinateRow(title: "P6", subtitle: "Right side down turn", xValue: $p6x, yValue: $p6y)
                EnvelopeCoordinateRow(title: "P7", subtitle: "Lower aft corner", xValue: $p7x, yValue: $p7y)
            } header: {
                Text("Flight Envelope (P1-P7)")
            } footer: {
                Text("Main red polygon: P1 -> P2 -> P3 -> P4 -> P5 -> P6 -> P7 -> P1.")
            }

            Section {
                EnvelopeCoordinateRow(title: "Q1", subtitle: "MRW point between P3 and Q2", xValue: $q1x, yValue: $q1y)
                EnvelopeCoordinateRow(title: "Q2", subtitle: "MRW upper middle", xValue: $q2x, yValue: $q2y)
                EnvelopeCoordinateRow(title: "Q3", subtitle: "MRW upper right", xValue: $q3x, yValue: $q3y)
            } header: {
                Text("Maximum Ramp Weight Chain (Q1-Q3)")
            } footer: {
                Text("Orange dotted chain: P3 -> Q1 -> Q2 -> Q3 -> P5.")
            }

            Section {
                HStack {
                    Text("MZFW")
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    TextField("MZFW", value: $mzfw, format: .number.precision(.fractionLength(0)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .foregroundColor(AppTheme.text)
                    Text("lbs")
                        .foregroundColor(AppTheme.muted)
                }

                HStack {
                    Text("MLW")
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    TextField("MLW", value: $mlw, format: .number.precision(.fractionLength(0)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .foregroundColor(AppTheme.text)
                    Text("lbs")
                        .foregroundColor(AppTheme.muted)
                }
            } header: {
                Text("Horizontal Limits")
            }

            Section {
                envelopePreview
            } header: {
                Text("Live Envelope Preview")
            } footer: {
                Text("As you edit P/Q points and limits, this preview updates to show the resulting geometry.")
            }

            Section {
                Button(role: .destructive) {
                    resetToDefaults()
                    showResetAcknowledgmentBanner()
                } label: {
                    Text("Reset Defaults")
                }
            } footer: {
                Text("Restores the default graph geometry defined for this aircraft.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(InstrumentBackground().ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle("Envelope Settings")
        .onAppear {
            migrateWBEnvelopeIfNeeded()
        }
        .overlay(alignment: .top) {
            if showResetAcknowledgment {
                ResetAcknowledgmentBanner()
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showResetAcknowledgment)
    }

    private func resetToDefaults() {
        p1x = WBEnvelopeConfig.defaultP1x; p1y = WBEnvelopeConfig.defaultP1y
        p2x = WBEnvelopeConfig.defaultP2x; p2y = WBEnvelopeConfig.defaultP2y
        p3x = WBEnvelopeConfig.defaultP3x; p3y = WBEnvelopeConfig.defaultP3y
        p4x = WBEnvelopeConfig.defaultP4x; p4y = WBEnvelopeConfig.defaultP4y
        p5x = WBEnvelopeConfig.defaultP5x; p5y = WBEnvelopeConfig.defaultP5y
        p6x = WBEnvelopeConfig.defaultP6x; p6y = WBEnvelopeConfig.defaultP6y
        p7x = WBEnvelopeConfig.defaultP7x; p7y = WBEnvelopeConfig.defaultP7y
        q1x = WBEnvelopeConfig.defaultQ1x; q1y = WBEnvelopeConfig.defaultQ1y
        q2x = WBEnvelopeConfig.defaultQ2x; q2y = WBEnvelopeConfig.defaultQ2y
        q3x = WBEnvelopeConfig.defaultQ3x; q3y = WBEnvelopeConfig.defaultQ3y
        mzfw = WBEnvelopeConfig.defaultMZFW
        mlw = WBEnvelopeConfig.defaultMLW
    }

    private func showResetAcknowledgmentBanner() {
        showResetAcknowledgment = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showResetAcknowledgment = false
        }
    }

    private var previewGeometry: WBEnvelopeGeometry {
        WBEnvelopeGeometry(
            p1: CGPoint(x: p1x, y: p1y),
            p2: CGPoint(x: p2x, y: p2y),
            p3: CGPoint(x: p3x, y: p3y),
            p4: CGPoint(x: p4x, y: p4y),
            p5: CGPoint(x: p5x, y: p5y),
            p6: CGPoint(x: p6x, y: p6y),
            p7: CGPoint(x: p7x, y: p7y),
            q1: CGPoint(x: q1x, y: q1y),
            q2: CGPoint(x: q2x, y: q2y),
            q3: CGPoint(x: q3x, y: q3y),
            mzfw: mzfw,
            mlw: mlw
        )
    }

    private var envelopePreview: some View {
        let envelopeColor = Color(red: 0.48, green: 0.80, blue: 1.00)
        return Chart {
            ForEach(Array(consecutiveSegments(previewGeometry.closedFlightEnvelope).enumerated()), id: \.offset) { index, segment in
                let points = [segment.0, segment.1]
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("CG", Double(point.x)),
                        y: .value("Weight", Double(point.y)),
                        series: .value("Edge", "edge-\(index)")
                    )
                    .foregroundStyle(envelopeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }

            ForEach(Array(consecutiveSegments(previewGeometry.mrwChain).enumerated()), id: \.offset) { index, segment in
                let points = [segment.0, segment.1]
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("CG", Double(point.x)),
                        y: .value("Weight", Double(point.y)),
                        series: .value("MRW", "mrw-\(index)")
                    )
                    .foregroundStyle(envelopeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 5]))
                }
            }

            if let segment = previewGeometry.mzfwSegment {
                ForEach([segment.0, segment.1], id: \.self) { x in
                    LineMark(
                        x: .value("CG", x),
                        y: .value("Weight", mzfw),
                        series: .value("Limit", "limit-mzfw")
                    )
                    .foregroundStyle(Color.black)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }

            if let segment = previewGeometry.mlwSegment {
                ForEach([segment.0, segment.1], id: \.self) { x in
                    LineMark(
                        x: .value("CG", x),
                        y: .value("Weight", mlw),
                        series: .value("Limit", "limit-mlw")
                    )
                    .foregroundStyle(Color.black)
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }
            }
        }
        .chartXScale(domain: previewGeometry.xDomain)
        .chartYScale(domain: previewGeometry.yDomain)
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.18))
                AxisTick()
                    .foregroundStyle(Color.white.opacity(0.45))
                AxisValueLabel()
                    .font(.custom("Avenir Next Regular", size: 10))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.18))
                AxisTick()
                    .foregroundStyle(Color.white.opacity(0.45))
                AxisValueLabel()
                    .font(.custom("Avenir Next Regular", size: 10))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(height: 220)
        .padding(.vertical, 6)
    }
}

private struct EnvelopeCoordinateRow: View {
    let title: String
    let subtitle: String
    @Binding var xValue: Double
    @Binding var yValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Avenir Next Demi Bold", size: 14))
                    .foregroundColor(AppTheme.text)
                Text(subtitle)
                    .font(.custom("Avenir Next Regular", size: 12))
                    .foregroundColor(AppTheme.muted)
            }

            HStack(spacing: 10) {
                Text("CG")
                    .foregroundColor(AppTheme.muted)
                    .frame(width: 28, alignment: .leading)
                TextField("CG", value: $xValue, format: .number.precision(.fractionLength(2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(AppTheme.text)
                Text("in")
                    .foregroundColor(AppTheme.muted)
            }

            HStack(spacing: 10) {
                Text("W")
                    .foregroundColor(AppTheme.muted)
                    .frame(width: 28, alignment: .leading)
                TextField("Weight", value: $yValue, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(AppTheme.text)
                Text("lbs")
                    .foregroundColor(AppTheme.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WeightBalanceInputView: View {
    @AppStorage("pilotWeight") private var pilotWeight: String = "180"
    @AppStorage("copilotWeight") private var copilotWeight: String = "180"
    @AppStorage("passenger1Weight") private var passenger1Weight: String = "0"
    @AppStorage("passenger2Weight") private var passenger2Weight: String = "0"
    @AppStorage("passenger3Weight") private var passenger3Weight: String = "0"
    @AppStorage("passenger4Weight") private var passenger4Weight: String = "30"
    @AppStorage("fuelWeight") private var fuelWeight: String = "1700"
    @AppStorage("cargoWeight") private var cargoWeight: String = "60"
    @AppStorage("aftOilStowageWeight") private var aftOilStowageWeight: String = "0"

    @AppStorage("basicEmptyWeight") private var basicEmptyWeight: String = "3766.930"
    @AppStorage("emptyCG") private var emptyCG: String = "138.119"
    @AppStorage("wbDefaultsApplied") private var wbDefaultsApplied: Bool = false
    @AppStorage(WBArmConfig.pilotArm) private var pilotArmArm = WBArmConfig.defaultPilotArm
    @AppStorage(WBArmConfig.copilotArm) private var copilotArmArm = WBArmConfig.defaultCopilotArm
    @AppStorage(WBArmConfig.passenger1Arm) private var passenger1ArmArm = WBArmConfig.defaultPassenger1Arm
    @AppStorage(WBArmConfig.passenger2Arm) private var passenger2ArmArm = WBArmConfig.defaultPassenger2Arm
    @AppStorage(WBArmConfig.passenger3Arm) private var passenger3ArmArm = WBArmConfig.defaultPassenger3Arm
    @AppStorage(WBArmConfig.passenger4Arm) private var passenger4ArmArm = WBArmConfig.defaultPassenger4Arm
    @AppStorage(WBArmConfig.seatConfiguration) private var seatConfigurationRaw = WBArmConfig.defaultSeatConfiguration
    @AppStorage(WBArmConfig.fuelArmMethod) private var fuelArmMethodRaw = WBArmConfig.defaultFuelArmMethod
    @AppStorage(WBArmConfig.singleFuelArm) private var singleFuelArm = WBArmConfig.defaultSingleFuelArm
    @AppStorage(WBArmConfig.cargoArm) private var cargoArmArm = WBArmConfig.defaultCargoArm
    @AppStorage(WBArmConfig.aftOilStowageArm) private var aftOilStowageArmArm = WBArmConfig.defaultAftOilStowageArm
    @AppStorage(WBArmConfig.fuelDensityLbsPerGallon) private var fuelDensityLbsPerGallon = WBArmConfig.defaultFuelDensityLbsPerGallon
    @AppStorage(WBArmConfig.fuelMinLookupGallons) private var fuelMinLookupGallons = WBArmConfig.defaultFuelMinLookupGallons
    @AppStorage(WBArmConfig.fuelMaxLookupGallons) private var fuelMaxLookupGallons = WBArmConfig.defaultFuelMaxLookupGallons
    @AppStorage(WBArmConfig.litersPerGallon) private var litersPerGallon = WBArmConfig.defaultLitersPerGallon
    @State private var goToSetup = false
    @State private var cautionBlinkStep = 0

    private var seatConfiguration: WBSeatConfiguration {
        WBSeatConfiguration(rawValue: seatConfigurationRaw) ?? .six
    }

    private var includesFrontPassengers: Bool {
        seatConfiguration == .six
    }

    private var fuelArmMethod: WBFuelArmMethod {
        WBFuelArmMethod(rawValue: fuelArmMethodRaw) ?? .lookupTable
    }

    var totalWeight: Double {
        let values = [
            pilotWeight, copilotWeight,
            passenger1Weight, passenger2Weight,
            includesFrontPassengers ? passenger3Weight : "0",
            includesFrontPassengers ? passenger4Weight : "0",
            fuelWeight, cargoWeight, aftOilStowageWeight
        ]
        let sum = values.compactMap { Double($0) }.reduce(0, +)
        return (Double(basicEmptyWeight) ?? 0) + sum
    }

    var totalMoment: Double {
        var components: [(String, Double)] = [
            (pilotWeight, pilotArmArm),
            (copilotWeight, copilotArmArm),
            (passenger1Weight, passenger1ArmArm),
            (passenger2Weight, passenger2ArmArm),
            (cargoWeight, cargoArmArm),
            (aftOilStowageWeight, aftOilStowageArmArm)
        ]
        if includesFrontPassengers {
            components.append((passenger3Weight, passenger3ArmArm))
            components.append((passenger4Weight, passenger4ArmArm))
        }

        let dynamicMoment = components.reduce(0) { result, element in
            result + (Double(element.0) ?? 0) * element.1
        }

        let fuelWeightValue = Double(fuelWeight) ?? 0
        let fuelMoment = fuelWeightValue * fuelArmForWeight(fuelWeightValue)

        let emptyMoment = (Double(basicEmptyWeight) ?? 0) * (Double(emptyCG) ?? 0)
        return dynamicMoment + fuelMoment + emptyMoment
    }

    var calculatedCG: Double {
        totalWeight > 0 ? totalMoment / totalWeight : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandLogoView()
                    .frame(maxWidth: 140)
                    .padding(.top, 6)

                instrumentSection(title: "Crew") {
                    WeightEntryRow(label: "Pilot", text: $pilotWeight)
                    WeightEntryRow(label: "Copilot", text: $copilotWeight)
                }

                instrumentSection(title: "Passengers") {
                    if includesFrontPassengers {
                        WeightEntryRow(label: "Front Passenger Left", text: $passenger3Weight)
                        WeightEntryRow(label: "Front Passenger Right", text: $passenger4Weight)
                    }
                    WeightEntryRow(label: "Rear Passenger Left", text: $passenger1Weight)
                    WeightEntryRow(label: "Rear Passenger Right", text: $passenger2Weight)
                }

                instrumentSection(title: "Fuel & Cargo") {
                    WeightEntryRow(label: "Fuel", text: $fuelWeight)
                    fuelInfoView
                    WeightEntryRow(label: "Cargo", text: $cargoWeight)
                    WeightEntryRow(label: "Aft Oil Stowage (Max 4 lbs)", text: $aftOilStowageWeight)
                }

                NavigationLink(
                    destination: WeightBalanceChartView(cgValue: calculatedCG, weightValue: totalWeight),
                    label: {
                        Text("Calculate & View Graph")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.accent)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                )

                Text("Extreme Caution: do not rely on these calculations. Follow the calculations and procedures set in your Pilot Operating Manual for safe operations")
                    .font(.custom("Avenir Next Regular", size: 11))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .opacity(cautionBlinkStep == 2 ? 0.2 : 1.0)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 22)
        }
        .background(InstrumentBackground().ignoresSafeArea())
        .navigationTitle("Weight & Balance Input")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            applyDefaultsIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    goToSetup = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Initial Setup")
            }
        }
        .navigationDestination(isPresented: $goToSetup) {
            WBInitialSetupView()
        }
        .onAppear {
            migrateWBEnvelopeIfNeeded()
            migrateWBArmDataIfNeeded()
        }
        .onReceive(Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()) { _ in
            cautionBlinkStep = (cautionBlinkStep + 1) % 3
        }
    }

    private func instrumentSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.custom("Avenir Next Demi Bold", size: 12))
                .foregroundColor(AppTheme.muted)

            VStack(spacing: 8) {
                content()
            }
            .padding(12)
            .background(
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
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
        }
    }

    private func applyDefaultsIfNeeded() {
        if !wbDefaultsApplied {
            basicEmptyWeight = "3766.930"
            emptyCG = "138.119"
            pilotWeight = "180"
            copilotWeight = "180"
            passenger1Weight = "0"
            passenger2Weight = "0"
            passenger3Weight = "0"
            passenger4Weight = "30"
            fuelWeight = "1700"
            cargoWeight = "60"
            aftOilStowageWeight = "0"
            wbDefaultsApplied = true
            return
        }

        if basicEmptyWeight.isEmpty { basicEmptyWeight = "3766.930" }
        if emptyCG.isEmpty { emptyCG = "138.119" }
        if pilotWeight.isEmpty { pilotWeight = "180" }
        if copilotWeight.isEmpty { copilotWeight = "180" }
        if passenger1Weight.isEmpty { passenger1Weight = "0" }
        if passenger2Weight.isEmpty { passenger2Weight = "0" }
        if passenger3Weight.isEmpty { passenger3Weight = "0" }
        if passenger4Weight.isEmpty { passenger4Weight = "30" }
        if fuelWeight.isEmpty { fuelWeight = "1700" }
        if cargoWeight.isEmpty { cargoWeight = "60" }
        if aftOilStowageWeight.isEmpty { aftOilStowageWeight = "0" }
    }

    private func fuelArmForWeight(_ weightLbs: Double) -> Double {
        guard weightLbs > 0 else { return 0 }
        if fuelArmMethod == .singleArm {
            return max(singleFuelArm, 0)
        }
        let lbsPerGallon = max(fuelDensityLbsPerGallon, 0.001)
        let gallons = weightLbs / lbsPerGallon
        let availableMin = WBFuelArmStore.allGallons.first ?? WBArmConfig.defaultFuelMinLookupGallons
        let availableMax = WBFuelArmStore.allGallons.last ?? WBArmConfig.defaultFuelMaxLookupGallons
        let configuredMin = min(fuelMinLookupGallons, fuelMaxLookupGallons)
        let configuredMax = max(fuelMinLookupGallons, fuelMaxLookupGallons)
        let minGallons = max(availableMin, configuredMin)
        let maxGallons = min(availableMax, configuredMax)

        if gallons <= Double(minGallons) {
            return WBFuelArmStore.value(for: minGallons)
        }
        if gallons >= Double(maxGallons) {
            return WBFuelArmStore.value(for: maxGallons)
        }

        let lowerGallons = max(minGallons, Int(floor(gallons)))
        let upperGallons = min(maxGallons, Int(ceil(gallons)))
        let lowerFS = WBFuelArmStore.value(for: lowerGallons)
        let upperFS = WBFuelArmStore.value(for: upperGallons)

        if lowerGallons == upperGallons {
            return lowerFS
        }

        let t = (gallons - Double(lowerGallons)) / Double(upperGallons - lowerGallons)
        return lowerFS + (upperFS - lowerFS) * t
    }

    private var fuelInfoView: some View {
        let fuelLbs = Double(fuelWeight) ?? 0
        let lbsPerGallon = max(fuelDensityLbsPerGallon, 0.001)
        let gallons = fuelLbs / lbsPerGallon
        let liters = gallons * litersPerGallon
        let arm = fuelArmForWeight(fuelLbs)
        return HStack {
            Text(String(format: "Fuel: %.1f gal (%.0f L)  |  Arm: %.1f in", gallons, liters, arm))
                .font(.custom("Avenir Next Regular", size: 12))
                .foregroundColor(AppTheme.muted)
            Spacer()
        }
        .padding(.top, -2)
        .padding(.bottom, 2)
    }
}

private enum WBFuelArmStore {
    private static let keyPrefix = "wb_fuel_arm_"

    static let defaultByGallon: [Int: Double] = [
        5: 144.0,
        6: 144.0,
        7: 144.0,
        8: 144.0,
        9: 144.0,
        10: 144.0,
        11: 144.0,
        12: 143.9,
        13: 143.9,
        14: 143.8,
        15: 143.8,
        16: 143.8,
        17: 143.7,
        18: 143.7,
        19: 143.6,
        20: 143.6,
        21: 143.6,
        22: 143.6,
        23: 143.6,
        24: 143.6,
        25: 143.6,
        26: 143.6,
        27: 143.6,
        28: 143.5,
        29: 143.5,
        30: 143.5,
        31: 143.5,
        32: 143.5,
        33: 143.6,
        34: 143.6,
        35: 143.6,
        36: 143.6,
        37: 143.6,
        38: 143.7,
        39: 143.7,
        40: 143.7,
        41: 143.7,
        42: 143.8,
        43: 143.8,
        44: 143.9,
        45: 143.9,
        46: 143.9,
        47: 143.9,
        48: 144.0,
        49: 144.0,
        50: 144.0,
        51: 144.0,
        52: 144.1,
        53: 144.1,
        54: 144.2,
        55: 144.2,
        56: 144.2,
        57: 144.3,
        58: 144.3,
        59: 144.4,
        60: 144.4,
        61: 144.4,
        62: 144.4,
        63: 144.5,
        64: 144.5,
        65: 144.5,
        66: 144.5,
        67: 144.6,
        68: 144.6,
        69: 144.7,
        70: 144.7,
        71: 144.7,
        72: 144.8,
        73: 144.8,
        74: 144.9,
        75: 144.9,
        76: 144.9,
        77: 144.9,
        78: 145.0,
        79: 145.0,
        80: 145.0,
        81: 145.0,
        82: 145.1,
        83: 145.1,
        84: 145.2,
        85: 145.2,
        86: 145.2,
        87: 145.2,
        88: 145.3,
        89: 145.3,
        90: 145.3,
        91: 145.3,
        92: 145.3,
        93: 145.4,
        94: 145.4,
        95: 145.4,
        96: 145.4,
        97: 145.5,
        98: 145.5,
        99: 145.6,
        100: 145.6,
        101: 145.6,
        102: 145.7,
        103: 145.7,
        104: 145.8,
        105: 145.8,
        106: 145.8,
        107: 145.8,
        108: 145.9,
        109: 145.9,
        110: 145.9,
        111: 145.9,
        112: 145.9,
        113: 146.0,
        114: 146.0,
        115: 146.0,
        116: 146.0,
        117: 146.0,
        118: 146.1,
        119: 146.1,
        120: 146.1,
        121: 146.1,
        122: 146.2,
        123: 146.2,
        124: 146.3,
        125: 146.3,
        126: 146.3,
        127: 146.3,
        128: 146.4,
        129: 146.4,
        130: 146.4,
        131: 146.4,
        132: 146.4,
        133: 146.5,
        134: 146.5,
        135: 146.5,
        136: 146.5,
        137: 146.5,
        138: 146.6,
        139: 146.6,
        140: 146.6,
        141: 146.6,
        142: 146.6,
        143: 146.7,
        144: 146.7,
        145: 146.7,
        146: 146.7,
        147: 146.7,
        148: 146.8,
        149: 146.8,
        150: 146.8,
        151: 146.8,
        152: 146.8,
        153: 146.9,
        154: 146.9,
        155: 146.9,
        156: 146.9,
        157: 146.9,
        158: 147.0,
        159: 147.0,
        160: 147.0,
        161: 147.0,
        162: 147.0,
        163: 147.1,
        164: 147.1,
        165: 147.1,
        166: 147.1,
        167: 147.1,
        168: 147.2,
        169: 147.2,
        170: 147.2,
        171: 147.2,
        172: 147.2,
        173: 147.3,
        174: 147.3,
        175: 147.3,
        176: 147.3,
        177: 147.3,
        178: 147.4,
        179: 147.4,
        180: 147.4,
        181: 147.4,
        182: 147.4,
        183: 147.5,
        184: 147.5,
        185: 147.5,
        186: 147.5,
        187: 147.5,
        188: 147.5,
        189: 147.5,
        190: 147.5,
        191: 147.5,
        192: 147.5,
        193: 147.6,
        194: 147.6,
        195: 147.6,
        196: 147.6,
        197: 147.6,
        198: 147.7,
        199: 147.7,
        200: 147.7,
        201: 147.7,
        202: 147.7,
        203: 147.8,
        204: 147.8,
        205: 147.8,
        206: 147.8,
        207: 147.8,
        208: 147.9,
        209: 147.9,
        210: 147.9,
        211: 147.9,
        212: 147.9,
        213: 148.0,
        214: 148.0,
        215: 148.0,
        216: 148.0,
        217: 148.0,
        218: 148.1,
        219: 148.1,
        220: 148.1,
        221: 148.1,
        222: 148.1,
        223: 148.2,
        224: 148.2,
        225: 148.2,
        226: 148.2,
        227: 148.2,
        228: 148.2,
        229: 148.2,
        230: 148.2,
        231: 148.2,
        232: 148.2,
        233: 148.3,
        234: 148.3,
        235: 148.3,
        236: 148.3,
        237: 148.3,
        238: 148.4,
        239: 148.4,
        240: 148.4,
        241: 148.4,
        242: 148.5,
        243: 148.5,
        244: 148.6,
        245: 148.6,
        246: 148.6,
        247: 148.6,
        248: 148.7,
        249: 148.7,
        250: 148.7,
        251: 148.7,
        252: 148.7,
        253: 148.8,
        254: 148.8,
        255: 148.8,
        256: 148.8,
        257: 148.8,
        258: 148.9,
        259: 148.9,
        260: 148.9
    ]

    static var allGallons: [Int] {
        defaultByGallon.keys.sorted()
    }

    private static func key(for gallon: Int) -> String {
        "\(keyPrefix)\(gallon)"
    }

    static func value(for gallon: Int, defaults: UserDefaults = .standard) -> Double {
        if let stored = defaults.object(forKey: key(for: gallon)) as? NSNumber {
            return stored.doubleValue
        }
        return defaultByGallon[gallon] ?? 0
    }

    static func set(_ value: Double, for gallon: Int, defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: key(for: gallon))
    }

    static func applyDefaults(_ defaults: UserDefaults = .standard) {
        for gallon in allGallons {
            defaults.set(defaultByGallon[gallon] ?? 0, forKey: key(for: gallon))
        }
    }
}

private enum PasscodeMode {
    case set
    case unlock
}

private struct PasscodeGateView: View {
    let mode: PasscodeMode
    @Binding var passcodeInput: String
    @Binding var newPasscode: String
    let errorMessage: String?
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(mode == .set ? "Set Passcode" : "Enter Passcode")
                    .font(.custom("Avenir Next Demi Bold", size: 18))
                    .foregroundColor(AppTheme.text)

                if mode == .set {
                    SecureField("New Passcode", text: $newPasscode)
                        .textContentType(.newPassword)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                } else {
                    SecureField("Passcode", text: $passcodeInput)
                        .textContentType(.password)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.accentSoft, lineWidth: 1)
                                )
                        )
                        .foregroundColor(AppTheme.text)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Avenir Next Regular", size: 13))
                        .foregroundColor(.red)
                }

                Button(mode == .set ? "Save" : "Unlock") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
            .padding(24)
            .navigationTitle("Editing Locked")
            .background(InstrumentBackground().ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

struct WeightBalanceChartView: View {
    let cgValue: Double
    let weightValue: Double
    @State private var goToSetup = false
    @State private var chartScale: CGFloat = 1.0
    @State private var chartBaseScale: CGFloat = 1.0
    @State private var chartOffset: CGSize = .zero
    @State private var chartBaseOffset: CGSize = .zero
    @State private var blinkPhase = false
    @AppStorage(WBEnvelopeConfig.p1x) private var p1x = WBEnvelopeConfig.defaultP1x
    @AppStorage(WBEnvelopeConfig.p1y) private var p1y = WBEnvelopeConfig.defaultP1y
    @AppStorage(WBEnvelopeConfig.p2x) private var p2x = WBEnvelopeConfig.defaultP2x
    @AppStorage(WBEnvelopeConfig.p2y) private var p2y = WBEnvelopeConfig.defaultP2y
    @AppStorage(WBEnvelopeConfig.p3x) private var p3x = WBEnvelopeConfig.defaultP3x
    @AppStorage(WBEnvelopeConfig.p3y) private var p3y = WBEnvelopeConfig.defaultP3y
    @AppStorage(WBEnvelopeConfig.p4x) private var p4x = WBEnvelopeConfig.defaultP4x
    @AppStorage(WBEnvelopeConfig.p4y) private var p4y = WBEnvelopeConfig.defaultP4y
    @AppStorage(WBEnvelopeConfig.p5x) private var p5x = WBEnvelopeConfig.defaultP5x
    @AppStorage(WBEnvelopeConfig.p5y) private var p5y = WBEnvelopeConfig.defaultP5y
    @AppStorage(WBEnvelopeConfig.p6x) private var p6x = WBEnvelopeConfig.defaultP6x
    @AppStorage(WBEnvelopeConfig.p6y) private var p6y = WBEnvelopeConfig.defaultP6y
    @AppStorage(WBEnvelopeConfig.p7x) private var p7x = WBEnvelopeConfig.defaultP7x
    @AppStorage(WBEnvelopeConfig.p7y) private var p7y = WBEnvelopeConfig.defaultP7y
    @AppStorage(WBEnvelopeConfig.q1x) private var q1x = WBEnvelopeConfig.defaultQ1x
    @AppStorage(WBEnvelopeConfig.q1y) private var q1y = WBEnvelopeConfig.defaultQ1y
    @AppStorage(WBEnvelopeConfig.q2x) private var q2x = WBEnvelopeConfig.defaultQ2x
    @AppStorage(WBEnvelopeConfig.q2y) private var q2y = WBEnvelopeConfig.defaultQ2y
    @AppStorage(WBEnvelopeConfig.q3x) private var q3x = WBEnvelopeConfig.defaultQ3x
    @AppStorage(WBEnvelopeConfig.q3y) private var q3y = WBEnvelopeConfig.defaultQ3y
    @AppStorage(WBEnvelopeConfig.mzfw) private var mzfw = WBEnvelopeConfig.defaultMZFW
    @AppStorage(WBEnvelopeConfig.mlw) private var mlw = WBEnvelopeConfig.defaultMLW

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandLogoView()
                    .frame(maxWidth: 140)
                    .padding(.top, 6)

                headerView
                weightInfoView
                statusView
                chartView
                    .scaleEffect(chartScale)
                    .offset(chartOffset)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let scaled = chartBaseScale * value
                                chartScale = min(max(scaled, 1.0), 2.5)
                            }
                            .onEnded { _ in
                                chartBaseScale = chartScale
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let scaled = chartBaseScale * value
                                chartScale = min(max(scaled, 1.0), 2.5)
                            }
                            .onEnded { _ in
                                chartBaseScale = chartScale
                            }
                    )
                    .highPriorityGesture(
                        DragGesture()
                            .onChanged { value in
                                chartOffset = CGSize(
                                    width: chartBaseOffset.width + value.translation.width,
                                    height: chartBaseOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                chartBaseOffset = chartOffset
                            }
                    )
                    .onTapGesture(count: 2) {
                        let next = chartScale < 1.5 ? 2.0 : 1.0
                        chartScale = next
                        chartBaseScale = next
                        if next == 1.0 {
                            chartOffset = .zero
                            chartBaseOffset = .zero
                        }
                    }
                Spacer(minLength: 12)
            }
            .padding()
        }
        .background(InstrumentBackground().ignoresSafeArea())
        .navigationTitle("W&B Chart")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    goToSetup = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accent)
                }
                .accessibilityLabel("Initial Setup")
            }
        }
        .navigationDestination(isPresented: $goToSetup) {
            WBInitialSetupView()
        }
        .onReceive(Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()) { _ in
            blinkPhase.toggle()
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("WEIGHT & BALANCE ENVELOPE")
                .font(.custom("Avenir Next Demi Bold", size: 16))
                .foregroundColor(AppTheme.text)
                .multilineTextAlignment(.center)

            Text("Center of Gravity Limits Graph")
                .font(.custom("Avenir Next Regular", size: 12))
                .foregroundColor(AppTheme.muted)
        }
    }

    private var weightInfoView: some View {
        Text(String(format: "CG: %.2f in  |  Weight: %.0f lbs", cgValue, weightValue))
            .font(.custom("Avenir Next Demi Bold", size: 14))
            .foregroundColor(AppTheme.text)
            .padding(.bottom, 8)
    }

    private var statusView: some View {
        let status = envelopeStatus(cg: cgValue, weight: weightValue)
        return Text(status.message)
            .font(.custom("Avenir Next Demi Bold", size: 14))
            .foregroundColor(status.color)
            .opacity(status.shouldBlink ? (blinkPhase ? 1.0 : 0.15) : 1.0)
    }

    private var chartView: some View {
        Chart {
            currentPointMark
        }
        .chartXScale(domain: geometry.xDomain)
        .chartYScale(domain: geometry.yDomain)
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartXAxisLabel {
            Text("CG (in)")
                .font(.custom("Avenir Next Regular", size: 12))
                .foregroundColor(AppTheme.muted)
        }
        .chartYAxisLabel {
            Text("Weight (lbs)")
                .font(.custom("Avenir Next Regular", size: 12))
                .foregroundColor(AppTheme.muted)
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                let plotFrame = geo[proxy.plotAreaFrame]
                ZStack(alignment: .topLeading) {
                    envelopeOverlay(proxy: proxy, plotFrame: plotFrame)

                    if let mzfwSegment = geometry.mzfwSegment {
                        chartLabelAtX(
                            "Maximum Zero Fuel Weight",
                            y: mzfw,
                            x: (mzfwSegment.0 + mzfwSegment.1) / 2,
                            proxy: proxy,
                            plotFrame: plotFrame,
                            xOffset: 0,
                            yOffset: 16
                        )
                    }

                    if let mlwSegment = geometry.mlwSegment {
                        chartLabelAtX(
                            "Maximum Landing Weight",
                            y: mlw,
                            x: (mlwSegment.0 + mlwSegment.1) / 2,
                            proxy: proxy,
                            plotFrame: plotFrame,
                            xOffset: 0,
                            yOffset: 16
                        )
                    }

                    chartLabelAtX(
                        "Maximum Ramp Weight",
                        y: Double(geometry.q2.y),
                        x: Double(geometry.q2.x),
                        proxy: proxy,
                        plotFrame: plotFrame,
                        xOffset: 0,
                        yOffset: -28
                    )

                    lineLabel(
                        "Forward Limit",
                        from: geometry.p2,
                        to: geometry.p3,
                        proxy: proxy,
                        plotFrame: plotFrame,
                        offsetX: -12,
                        offsetY: -24,
                        rotate180: false
                    )

                    lineLabel(
                        "Aft Limit",
                        from: geometry.p6,
                        to: geometry.p7,
                        proxy: proxy,
                        plotFrame: plotFrame,
                        offsetX: 12,
                        offsetY: 20,
                        rotate180: true
                    )
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .frame(height: 400)
        .padding(12)
        .background(
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
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 6)
    }

    @ChartContentBuilder
    private var currentPointMark: some ChartContent {
        let status = envelopeStatus(cg: cgValue, weight: weightValue)
        let pointColor: Color = status.color
        PointMark(
            x: .value("CG", cgValue),
            y: .value("Weight", weightValue)
        )
        .symbolSize(0)
        .foregroundStyle(pointColor)
        .annotation(position: .overlay) {
            CrosshairView(
                color: pointColor,
                opacity: status.shouldBlink ? (blinkPhase ? 1.0 : 0.15) : 1.0
            )
        }
    }

    @ViewBuilder
    private func envelopeOverlay(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        let envelopeColor = Color(red: 0.48, green: 0.80, blue: 1.00)

        if let path = chartPath(for: geometry.closedFlightEnvelope, proxy: proxy, plotFrame: plotFrame) {
            path
                .stroke(envelopeColor, style: StrokeStyle(lineWidth: 2))
        }

        if let path = chartPath(for: geometry.mrwChain, proxy: proxy, plotFrame: plotFrame) {
            path
                .stroke(envelopeColor, style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
        }

        if let segment = geometry.mzfwSegment {
            let points = [
                CGPoint(x: segment.0, y: CGFloat(mzfw)),
                CGPoint(x: segment.1, y: CGFloat(mzfw))
            ]
            if let path = chartPath(for: points, proxy: proxy, plotFrame: plotFrame) {
                path
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 1))
            }
        }

        if let segment = geometry.mlwSegment {
            let points = [
                CGPoint(x: segment.0, y: CGFloat(mlw)),
                CGPoint(x: segment.1, y: CGFloat(mlw))
            ]
            if let path = chartPath(for: points, proxy: proxy, plotFrame: plotFrame) {
                path
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 1))
            }
        }
    }

    private func chartPath(for points: [CGPoint], proxy: ChartProxy, plotFrame: CGRect) -> Path? {
        let mapped = points.compactMap { point -> CGPoint? in
            guard
                let x = proxy.position(forX: Double(point.x)),
                let y = proxy.position(forY: Double(point.y))
            else {
                return nil
            }
            return CGPoint(x: plotFrame.minX + x, y: plotFrame.minY + y)
        }
        guard mapped.count >= 2 else { return nil }

        var path = Path()
        path.move(to: mapped[0])
        for point in mapped.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }

    private func chartLabelAtX(_ text: String, y: Double, x: Double, proxy: ChartProxy, plotFrame: CGRect, xOffset: CGFloat, yOffset: CGFloat) -> some View {
        let yPos = (proxy.position(forY: y) ?? 0) + plotFrame.minY
        let xPos = (proxy.position(forX: x) ?? 0) + plotFrame.minX
        return Text(text)
            .font(.custom("Avenir Next Regular", size: 9))
            .foregroundColor(AppTheme.muted)
            .position(x: xPos + xOffset, y: yPos + yOffset)
    }

    private func lineLabel(
        _ text: String,
        from: CGPoint,
        to: CGPoint,
        proxy: ChartProxy,
        plotFrame: CGRect,
        offsetX: CGFloat,
        offsetY: CGFloat,
        rotate180: Bool
    ) -> some View {
        let x1 = (proxy.position(forX: Double(from.x)) ?? 0) + plotFrame.minX
        let y1 = (proxy.position(forY: Double(from.y)) ?? 0) + plotFrame.minY
        let x2 = (proxy.position(forX: Double(to.x)) ?? 0) + plotFrame.minX
        let y2 = (proxy.position(forY: Double(to.y)) ?? 0) + plotFrame.minY
        let midX = (x1 + x2) / 2 + offsetX
        let midY = (y1 + y2) / 2 + offsetY
        var angle = atan2(y2 - y1, x2 - x1) * 180 / .pi
        if rotate180 {
            angle += 180
        }
        return Text(text)
            .font(.custom("Avenir Next Regular", size: 9))
            .foregroundColor(AppTheme.muted)
            .rotationEffect(.degrees(Double(angle)))
            .position(x: midX, y: midY)
    }



    private struct CrosshairView: View {
        let color: Color
        let opacity: Double
        private let size: CGFloat = 14
        private let thickness: CGFloat = 2

        var body: some View {
            ZStack {
                Rectangle()
                    .fill(color)
                    .frame(width: thickness, height: size)
                Rectangle()
                    .fill(color)
                    .frame(width: size, height: thickness)
            }
            .opacity(opacity)
        }
    }

    // FS labels removed per request.

    private var xAxisMarks: some AxisContent {
        let lower = floor(geometry.xDomain.lowerBound)
        let upper = ceil(geometry.xDomain.upperBound)
        return AxisMarks(values: Array(stride(from: lower, through: upper, by: 1))) { _ in
            AxisGridLine()
                .foregroundStyle(Color.white.opacity(0.25))
            AxisTick()
                .foregroundStyle(Color.white.opacity(0.6))
            AxisValueLabel()
                .foregroundStyle(AppTheme.muted)
                .font(.custom("Avenir Next Regular", size: 11))
        }
    }

    private var yAxisMarks: some AxisContent {
        let lower = (floor(geometry.yDomain.lowerBound / 400.0) * 400.0)
        let upper = (ceil(geometry.yDomain.upperBound / 400.0) * 400.0)
        let values = Array(stride(from: lower, through: upper, by: 400))
        return AxisMarks(values: values) { _ in
            AxisGridLine()
                .foregroundStyle(Color.white.opacity(0.25))
            AxisTick()
                .foregroundStyle(Color.white.opacity(0.6))
            AxisValueLabel()
                .foregroundStyle(AppTheme.muted)
                .font(.custom("Avenir Next Regular", size: 11))
        }
    }

    private var geometry: WBEnvelopeGeometry {
        WBEnvelopeGeometry(
            p1: CGPoint(x: p1x, y: p1y),
            p2: CGPoint(x: p2x, y: p2y),
            p3: CGPoint(x: p3x, y: p3y),
            p4: CGPoint(x: p4x, y: p4y),
            p5: CGPoint(x: p5x, y: p5y),
            p6: CGPoint(x: p6x, y: p6y),
            p7: CGPoint(x: p7x, y: p7y),
            q1: CGPoint(x: q1x, y: q1y),
            q2: CGPoint(x: q2x, y: q2y),
            q3: CGPoint(x: q3x, y: q3y),
            mzfw: mzfw,
            mlw: mlw
        )
    }

    private struct EnvelopeStatus {
        let message: String
        let color: Color
        let shouldBlink: Bool
    }

    private func envelopeStatus(cg: Double, weight: Double) -> EnvelopeStatus {
        if isAboveMaximumRampWeight(cg: cg, weight: weight) {
            return EnvelopeStatus(
                message: "Excessive Weight",
                color: .red,
                shouldBlink: true
            )
        }

        if !isInsideEnvelope(cg: cg, weight: weight) {
            return EnvelopeStatus(
                message: "Outside Flight Envelope",
                color: .red,
                shouldBlink: true
            )
        }

        return EnvelopeStatus(
            message: "Inside Flight Envelope",
            color: .green,
            shouldBlink: false
        )
    }

    private func isAboveMaximumRampWeight(cg: Double, weight: Double) -> Bool {
        guard let mrwWeight = yOnChain(x: cg) else { return false }
        return weight > mrwWeight
    }

    private func yOnChain(x: Double) -> Double? {
        let chain = geometry.mrwChain
        var candidates: [Double] = []
        guard chain.count > 1 else { return nil }

        for i in 0..<(chain.count - 1) {
            let start = chain[i]
            let end = chain[i + 1]
            let x1 = start.x
            let x2 = end.x
            let minX = min(x1, x2)
            let maxX = max(x1, x2)
            guard CGFloat(x) >= minX, CGFloat(x) <= maxX else { continue }
            let y1 = start.y
            let y2 = end.y
            if abs(x2 - x1) < 0.0001 {
                candidates.append(Double(max(y1, y2)))
                continue
            }
            let t = (CGFloat(x) - x1) / (x2 - x1)
            let y = y1 + t * (y2 - y1)
            candidates.append(Double(y))
        }
        return candidates.max()
    }

    private func isInsideEnvelope(cg: Double, weight: Double) -> Bool {
        let polygon = geometry.closedFlightEnvelope
        var isInside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = Double(polygon[i].x), yi = Double(polygon[i].y)
            let xj = Double(polygon[j].x), yj = Double(polygon[j].y)

            if ((yi > weight) != (yj > weight)) &&
                (cg < (xj - xi) * (weight - yi) / ((yj - yi) + 0.0001) + xi) {
                isInside.toggle()
            }
            j = i
        }

        return isInside
    }
}

private struct InstrumentTextField: View {
    let title: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    let isEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Avenir Next Regular", size: 13))
                .foregroundColor(AppTheme.muted)

            TextField("", text: $text)
                .keyboardType(keyboard)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.accentSoft, lineWidth: 1)
                        )
                )
                .foregroundColor(AppTheme.text)
                .disabled(!isEnabled)
        }
    }
}

private struct InstrumentCompactTextField: View {
    let title: String
    @Binding var text: String
    let keyboard: UIKeyboardType
    let isEnabled: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var fieldWidth: CGFloat {
        horizontalSizeClass == .regular ? 150 : 126
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.custom("Avenir Next Regular", size: 13))
                .foregroundColor(AppTheme.muted)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("", text: $text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.trailing)
                .padding(.vertical, 9)
                .padding(.horizontal, 10)
                .frame(width: fieldWidth)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.accentSoft, lineWidth: 1)
                        )
                )
                .foregroundColor(AppTheme.text)
                .disabled(!isEnabled)
        }
    }
}

private struct WeightEntryRow: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.custom("Avenir Next Regular", size: 14))
                .foregroundColor(AppTheme.text)
            Spacer()
            TextField("lbs", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: 90)
            Text("lbs")
                .font(.custom("Avenir Next Regular", size: 13))
                .foregroundColor(AppTheme.muted)
        }
        .padding(.vertical, 4)
    }
}
