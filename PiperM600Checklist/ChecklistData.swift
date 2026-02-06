import Foundation

struct ChecklistItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var text: String
    var isChecked: Bool = false
}

struct ChecklistSection: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var items: [ChecklistItem]

    init(id: UUID = UUID(), title: String, items: [ChecklistItem]) {
        self.id = id
        self.title = title
        self.items = items
    }

    init(title: String, items: [ChecklistItem]) {
        self.title = title
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        if let decodedItems = try? container.decode([ChecklistItem].self, forKey: .items) {
            items = decodedItems
        } else {
            let legacyItems = (try? container.decode([String].self, forKey: .items)) ?? []
            items = legacyItems.map { ChecklistItem(text: $0) }
        }
    }
}

enum ChecklistData {
    private static func makeItems(_ texts: [String]) -> [ChecklistItem] {
        texts.map { ChecklistItem(text: $0) }
    }

    static let defaultSections: [ChecklistSection] = [
        ChecklistSection(title: "PRE-START", items: makeItems([
            "Inspection, chocks, plugs, covers, Doors LOCKED, Briefing",
            "O2 quantity > 800 psi: Set ON + FUEL Adequate",
            "SWITCHES OFF + BREAKERS IN + PRESSURE OFF",
            "FLAPS UP + ELT Armed + EMER GEAR locked + MOR locked",
            "GEAR DOWN + BREAK ON + POWER idle",
            "CONDITIONER Stop + FUEL SHUTOFF OPEN + AREA CLEAR",
            "EMERGENCY ON"
        ])),
        ChecklistSection(title: "ENGINE START", items: makeItems([
            "BATTERY MASTER ON (24-26V) + EMERGENCY OFF",
            "[Or EMERGENCY OFF + plug in GPU: 28V]",
            "CAS MESSAGES + NAV should be ON",
            "OAT + FUEL PUMPS MAN + IGNITION MAN + START (2 sec)",
            "NG above 13% (14-15%): Add Fuel + Monitor ITT, NG, Voltage",
            "Verify \"start engaged\" light OFF at 56% Ng",
            "Verify Ng stable > 63%, Prop RPM > 1180",
            "PUMPS AUTO + IGNITION OFF [Unplug GPU: verify > 24.5V]",
            "GEN ON: verify Volts and Amps",
            "ALT ON: verify ALT and GEN lights OUT",
            "ENVIRONMENTAL if needed",
            "AVIONICS ON + FLAPS T/O + Test Annunc Lights + Stall Warn",
            "PRESSURE LEVER IN + SWITCH",
            "W&B + FOB SYNC + DEST ELV",
            "ATIS and Clearance set into panel",
            "TRIMS + FMS or MANUAL"
        ])),
        ChecklistSection(title: "TAXI", items: makeItems([
            "TAXI LIGHTS ON + Breaks + Flight Control",
            "Run-up (1900 RPM): OS GOVER + BETA LOCK + GEN/ALT check",
            "Departure Briefing + XPDR Set"
        ])),
        ChecklistSection(title: "ENTERING RUNWAY ENVIRONMENT", items: makeItems([
            "STROBE LIGHT + FLAPS + TRIMS + PRESSURE",
            "PUMPS + IGNITERS + HOTS + LIGHTS + AT"
        ])),
        ChecklistSection(title: "TAKE-OFF", items: makeItems([
            "Call-Outs: Airspeed Alive + Gauges Green + Annunciator Clear",
            "60 Kts Crosscheck -> 85 Kts Rotate",
            "Verify Positive Rate + GEAR UP + FLAPS UP + TRIM",
            "> 400 FEET: HEADING + AP + FLC (set speed) + BARO if needed",
            "FUEL PUMPS AUTO + IGNITION AUTO",
            "Check aircraft performing as commanded"
        ])),
        ChecklistSection(title: "CLIMB/CRUISE/DESCENT", items: makeItems([
            "10k Check + Flow + Pulse lights OFF",
            "Verify Pressure/Altitude settings + APPROACH briefing"
        ])),
        ChecklistSection(title: "LANDING", items: makeItems([
            "Go down + Gear down + T/O Flaps + 400 Tq + Verify 120 Kts: Flow",
            "Clearance Received",
            "LANDING LIGHT ON + PUMPS + IGNITION MAN + APPR",
            "Runway in sight + 3 GREEN + AP OFF + AT OFF",
            "Runway clear: continue or TOGA"
        ])),
        ChecklistSection(title: "AFTER LANDING", items: makeItems([
            "PUMPS + IGNITERS + HOTS + LIGHTS",
            "FLAPS + TRIMS + PRESSURE + RADAR OFF"
        ])),
        ChecklistSection(title: "SHUTDOWN", items: makeItems([
            "ENVIRONMENTAL OFF + PRESSURE OUT + LIGHTS + AVIONICS",
            "ALT OFF + GEN OFF + FEATHER + OFF (Ng<10%) + OXYGEN OFF"
        ]))
    ]
}
