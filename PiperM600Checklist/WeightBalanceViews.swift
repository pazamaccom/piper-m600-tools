import SwiftUI
import Charts

// WeightBalanceMenuView removed in favor of opening input directly from the root menu.

struct WBInitialSetupView: View {
    @AppStorage("basicEmptyWeight") private var basicEmptyWeight: String = "3766.930"
    @AppStorage("emptyCG") private var emptyCG: String = "138.119"
    @AppStorage("wbDefaultsApplied") private var wbDefaultsApplied: Bool = false
    @State private var goToInput = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image("Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 140)
                    .padding(.top, 6)

                Text("Initial Aircraft Setup")
                    .font(.custom("Avenir Next Condensed Demi Bold", size: 24))
                    .foregroundColor(AppTheme.text)

                Text("Enter the Basic Empty Weight and Center of Gravity (CG) for this aircraft.")
                    .font(.custom("Avenir Next Regular", size: 14))
                    .foregroundColor(AppTheme.muted)

                VStack(spacing: 12) {
                    InstrumentTextField(
                        title: "Basic Empty Weight (lbs)",
                        text: $basicEmptyWeight,
                        keyboard: .decimalPad,
                        isEnabled: true
                    )

                    InstrumentTextField(
                        title: "Empty CG (inches aft of datum)",
                        text: $emptyCG,
                        keyboard: .decimalPad,
                        isEnabled: true
                    )
                }

                Button(action: {
                    goToInput = true
                }) {
                    Text("Save & Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .disabled(basicEmptyWeight.isEmpty || emptyCG.isEmpty)
            }
            .padding(20)
        }
        .background(InstrumentBackground().ignoresSafeArea())
        .navigationTitle("Initial Setup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            applyDefaultsIfNeeded()
        }
        .navigationDestination(isPresented: $goToInput) {
            WeightBalanceInputView()
        }
    }

    private func applyDefaultsIfNeeded() {
        if !wbDefaultsApplied || basicEmptyWeight.isEmpty || emptyCG.isEmpty {
            basicEmptyWeight = "3766.930"
            emptyCG = "138.119"
            wbDefaultsApplied = true
        }
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
    @AppStorage("editPasscode") private var editPasscode: String = ""
    @State private var showPasscodeSheet = false
    @State private var passcodeInput = ""
    @State private var newPasscode = ""
    @State private var passcodeError: String?
    @State private var goToSetup = false
    @State private var passcodeMode: PasscodeMode = .unlock

    var totalWeight: Double {
        let values = [
            pilotWeight, copilotWeight,
            passenger1Weight, passenger2Weight,
            passenger3Weight, passenger4Weight,
            fuelWeight, cargoWeight, aftOilStowageWeight
        ]
        let sum = values.compactMap { Double($0) }.reduce(0, +)
        return (Double(basicEmptyWeight) ?? 0) + sum
    }

    var totalMoment: Double {
        let components: [(String, Double)] = [
            (pilotWeight, 135.50),
            (copilotWeight, 136.70),
            (passenger1Weight, 218.75),
            (passenger2Weight, 218.75),
            (passenger3Weight, 177.00),
            (passenger4Weight, 177.00),
            (cargoWeight, 248.23),
            (aftOilStowageWeight, 286.50)
        ]

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
                Image("Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 140)
                    .padding(.top, 6)

                instrumentSection(title: "Crew") {
                    WeightEntryRow(label: "Pilot", text: $pilotWeight)
                    WeightEntryRow(label: "Copilot", text: $copilotWeight)
                }

                instrumentSection(title: "Passengers") {
                    WeightEntryRow(label: "Front Passenger Left", text: $passenger3Weight)
                    WeightEntryRow(label: "Front Passenger Right", text: $passenger4Weight)
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
                    if editPasscode.isEmpty {
                        goToSetup = true
                    } else {
                        passcodeInput = ""
                        newPasscode = ""
                        passcodeError = nil
                        passcodeMode = .unlock
                        showPasscodeSheet = true
                    }
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
        .sheet(isPresented: $showPasscodeSheet) {
            PasscodeGateView(
                mode: passcodeMode,
                passcodeInput: $passcodeInput,
                newPasscode: $newPasscode,
                errorMessage: passcodeError
            ) {
                switch passcodeMode {
                case .set:
                    let trimmed = newPasscode.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        passcodeError = "Enter a passcode."
                        return
                    }
                    editPasscode = trimmed
                    showPasscodeSheet = false
                    goToSetup = true
                case .unlock:
                    if passcodeInput == editPasscode {
                        showPasscodeSheet = false
                        goToSetup = true
                    } else {
                        passcodeError = "Incorrect passcode."
                    }
                }
            } onCancel: {
                showPasscodeSheet = false
            }
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
        let gallons = weightLbs / 6.7
        let minGallons = 5
        let maxGallons = 260

        if gallons <= Double(minGallons) {
            return FuelArmTable.fsByGallon[minGallons] ?? 0
        }
        if gallons >= Double(maxGallons) {
            return FuelArmTable.fsByGallon[maxGallons] ?? 0
        }

        let lowerGallons = max(minGallons, Int(floor(gallons)))
        let upperGallons = min(maxGallons, Int(ceil(gallons)))

        guard
            let lowerFS = FuelArmTable.fsByGallon[lowerGallons],
            let upperFS = FuelArmTable.fsByGallon[upperGallons]
        else {
            return FuelArmTable.fsByGallon[lowerGallons] ?? 0
        }

        if lowerGallons == upperGallons {
            return lowerFS
        }

        let t = (gallons - Double(lowerGallons)) / Double(upperGallons - lowerGallons)
        return lowerFS + (upperFS - lowerFS) * t
    }

    private var fuelInfoView: some View {
        let fuelLbs = Double(fuelWeight) ?? 0
        let gallons = fuelLbs / 6.7
        let liters = gallons * 3.78541
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

private enum FuelArmTable {
    static let fsByGallon: [Int: Double] = [
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
    @AppStorage("editPasscode") private var editPasscode: String = ""
    @State private var showPasscodeSheet = false
    @State private var passcodeInput = ""
    @State private var newPasscode = ""
    @State private var passcodeError: String?
    @State private var goToSetup = false
    @State private var passcodeMode: PasscodeMode = .unlock
    @State private var chartScale: CGFloat = 1.0
    @State private var chartBaseScale: CGFloat = 1.0
    @State private var chartOffset: CGSize = .zero
    @State private var chartBaseOffset: CGSize = .zero

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("Logo")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 140)
                    .padding(.top, 6)

                headerView
                weightInfoView
                warningViewIfNeeded
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
                    if editPasscode.isEmpty {
                        goToSetup = true
                    } else {
                        passcodeInput = ""
                        newPasscode = ""
                        passcodeError = nil
                        passcodeMode = .unlock
                        showPasscodeSheet = true
                    }
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
        .sheet(isPresented: $showPasscodeSheet) {
            PasscodeGateView(
                mode: passcodeMode,
                passcodeInput: $passcodeInput,
                newPasscode: $newPasscode,
                errorMessage: passcodeError
            ) {
                switch passcodeMode {
                case .set:
                    let trimmed = newPasscode.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        passcodeError = "Enter a passcode."
                        return
                    }
                    editPasscode = trimmed
                    showPasscodeSheet = false
                    goToSetup = true
                case .unlock:
                    if passcodeInput == editPasscode {
                        showPasscodeSheet = false
                        goToSetup = true
                    } else {
                        passcodeError = "Incorrect passcode."
                    }
                }
            } onCancel: {
                showPasscodeSheet = false
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("M600 WEIGHT & BALANCE ENVELOPE")
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

    private var warningViewIfNeeded: some View {
        Group {
            if !isInsideEnvelope(cg: cgValue, weight: weightValue) {
                Text("Outside Envelope Limits")
                    .font(.custom("Avenir Next Demi Bold", size: 14))
                    .foregroundColor(.red)
            }
        }
    }

    private var chartView: some View {
        Chart {
            envelopeMarks
            limitLineMarks
            currentPointMark
        }
        .chartXScale(domain: 137...146)
        .chartYScale(domain: 3500...6200)
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartForegroundStyleScale([
            "envelope": Color.red,
            "extra": Color.red
        ])
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
                    chartLabelAtXBoxed(
                        "Weight & Balance Envelope Limits",
                        y: 3500,
                        x: 137,
                        proxy: proxy,
                        plotFrame: plotFrame,
                        xOffset: 92,
                        yOffset: 80
                    )
                    chartLabelAtX("MZFW 4850", y: 4850, x: 137, proxy: proxy, plotFrame: plotFrame, xOffset: 32, yOffset: 16)
                    chartLabelAtX("MLW 5800", y: 5800, x: 137, proxy: proxy, plotFrame: plotFrame, xOffset: 28, yOffset: 34)
                    chartLabelRight("MTW 6000", y: 6000, proxy: proxy, plotFrame: plotFrame, xInset: 36, yOffset: 34)
                    chartLabelRight("MRW 6050", y: 6050, proxy: proxy, plotFrame: plotFrame, xInset: 36, yOffset: 12)
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
    private var envelopeMarks: some ChartContent {
        ForEach(envelopePolylinePoints, id: \.self) { point in
            LineMark(
                x: .value("CG", point.x),
                y: .value("Weight", point.y),
                series: .value("Series", "envelope")
            )
            .foregroundStyle(by: .value("Series", "envelope"))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }

        ForEach(extraEnvelopePolylinePoints, id: \.self) { point in
            LineMark(
                x: .value("CG", point.x),
                y: .value("Weight", point.y),
                series: .value("Series", "extra")
            )
            .foregroundStyle(by: .value("Series", "extra"))
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }

    @ChartContentBuilder
    private var currentPointMark: some ChartContent {
        let pointColor: Color = currentPointColor(cg: cgValue, weight: weightValue)
        PointMark(
            x: .value("CG", cgValue),
            y: .value("Weight", weightValue)
        )
        .symbolSize(0)
        .foregroundStyle(pointColor)
        .annotation(position: .overlay) {
            CrosshairView(color: pointColor)
        }
    }

    @ChartContentBuilder
    private var limitLineMarks: some ChartContent {
        RuleMark(y: .value("Max ZFW", 4850))
            .foregroundStyle(AppTheme.muted)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))

        RuleMark(y: .value("Max Landing", 5800))
            .foregroundStyle(AppTheme.muted)
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))

    }

    private func chartLabel(_ text: String, y: Double, proxy: ChartProxy, plotFrame: CGRect, xOffset: CGFloat, yOffset: CGFloat) -> some View {
        let yPos = proxy.position(forY: y) ?? plotFrame.minY
        return Text(text)
            .font(.custom("Avenir Next Regular", size: 10))
            .foregroundColor(AppTheme.muted)
            .position(x: plotFrame.minX + xOffset, y: yPos + yOffset)
    }

    private func chartLabelAtX(_ text: String, y: Double, x: Double, proxy: ChartProxy, plotFrame: CGRect, xOffset: CGFloat, yOffset: CGFloat) -> some View {
        let yPos = proxy.position(forY: y) ?? plotFrame.minY
        let xPos = proxy.position(forX: x) ?? plotFrame.minX
        return Text(text)
            .font(.custom("Avenir Next Regular", size: 10))
            .foregroundColor(AppTheme.muted)
            .position(x: xPos + xOffset, y: yPos + yOffset)
    }

    private func chartLabelAtXBoxed(_ text: String, y: Double, x: Double, proxy: ChartProxy, plotFrame: CGRect, xOffset: CGFloat, yOffset: CGFloat) -> some View {
        let yPos = proxy.position(forY: y) ?? plotFrame.minY
        let xPos = proxy.position(forX: x) ?? plotFrame.minX
        return Text(text)
            .font(.custom("Avenir Next Regular", size: 10))
            .foregroundColor(AppTheme.muted)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.card.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(AppTheme.bezelLight, lineWidth: 1)
                    )
            )
            .position(x: xPos + xOffset, y: yPos + yOffset)
    }

    private func chartLabelRight(_ text: String, y: Double, proxy: ChartProxy, plotFrame: CGRect, xInset: CGFloat, yOffset: CGFloat) -> some View {
        let yPos = proxy.position(forY: y) ?? plotFrame.minY
        return Text(text)
            .font(.custom("Avenir Next Regular", size: 10))
            .foregroundColor(AppTheme.muted)
            .position(x: plotFrame.maxX - xInset, y: yPos + yOffset)
    }



    private struct CrosshairView: View {
        let color: Color
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
        }
    }

    // FS labels removed per request.

    private var xAxisMarks: some AxisContent {
        AxisMarks(values: Array(stride(from: 137, through: 146, by: 1))) { _ in
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
        let values = [3500] + Array(stride(from: 3600, through: 6000, by: 400))
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

    struct EnvelopePoint: Hashable {
        let x: Double
        let y: Double
    }

    struct EnvelopeSegment: Hashable {
        let start: EnvelopePoint
        let end: EnvelopePoint
    }

    private var envelopePoints: [EnvelopePoint] {
        [
            EnvelopePoint(x: 137.00, y: 3500),
            EnvelopePoint(x: 137.00, y: 3925),
            EnvelopePoint(x: 139.05, y: 4850),
            EnvelopePoint(x: 141.15, y: 5800),
            EnvelopePoint(x: 141.26, y: 5850),
            EnvelopePoint(x: 144.00, y: 6050),
            EnvelopePoint(x: 146.00, y: 6050),
            EnvelopePoint(x: 146.00, y: 4500),
            EnvelopePoint(x: 140.00, y: 3500),
            EnvelopePoint(x: 137.00, y: 3500)
        ]
    }

    private var envelopeSegments: [EnvelopeSegment] {
        zip(envelopePoints, envelopePoints.dropFirst()).map(EnvelopeSegment.init)
    }

    private var extraEnvelopeSegments: [EnvelopeSegment] {
        [
            EnvelopeSegment(
                start: EnvelopePoint(x: 146.00, y: 6000),
                end: EnvelopePoint(x: 144.00, y: 6000)
            ),
            EnvelopeSegment(
                start: EnvelopePoint(x: 144.00, y: 6000),
                end: EnvelopePoint(x: 141.15, y: 5800)
            )
        ]
    }

    private var envelopePolylinePoints: [EnvelopePoint] {
        envelopePoints
    }

    private var extraEnvelopePolylinePoints: [EnvelopePoint] {
        [
            EnvelopePoint(x: 146.00, y: 6000),
            EnvelopePoint(x: 144.00, y: 6000),
            EnvelopePoint(x: 141.15, y: 5800)
        ]
    }

    private func currentPointColor(cg: Double, weight: Double) -> Color {
        guard isInsideEnvelope(cg: cg, weight: weight) else {
            return .red
        }

        if let yExtra = yOnSegments(x: cg, segments: extraEnvelopeSegments), weight > yExtra {
            return .yellow
        }

        return .green
    }

    private func yOnSegments(x: Double, segments: [EnvelopeSegment]) -> Double? {
        var candidates: [Double] = []

        for segment in segments {
            let x1 = segment.start.x
            let x2 = segment.end.x
            let minX = min(x1, x2)
            let maxX = max(x1, x2)

            guard x >= minX, x <= maxX else { continue }

            let y1 = segment.start.y
            let y2 = segment.end.y
            if abs(x2 - x1) < 0.0001 {
                candidates.append(max(y1, y2))
                continue
            }

            let t = (x - x1) / (x2 - x1)
            let y = y1 + t * (y2 - y1)
            candidates.append(y)
        }

        return candidates.max()
    }

    private func isInsideEnvelope(cg: Double, weight: Double) -> Bool {
        let polygon = envelopePoints
        var isInside = false
        var j = polygon.count - 1

        for i in 0..<polygon.count {
            let xi = polygon[i].x, yi = polygon[i].y
            let xj = polygon[j].x, yj = polygon[j].y

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
