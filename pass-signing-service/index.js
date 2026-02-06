import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { Storage } from "@google-cloud/storage";
import { PKPass } from "passkit-generator";
import { v4 as uuidv4 } from "uuid";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: "1mb" }));

const secretsClient = new SecretManagerServiceClient();
const storage = new Storage();

const REQUIRED_ENV = [
  "PASS_TYPE_ID",
  "TEAM_ID",
  "ORG_NAME",
  "SIGNER_CERT_SECRET",
  "SIGNER_KEY_SECRET",
  "SIGNER_KEY_PASSPHRASE_SECRET",
  "WWDR_CERT_SECRET",
  "DEFAULT_DOCS_BUCKET",
  "DEFAULT_DOCS_CODE_SECRET"
];
for (const key of REQUIRED_ENV) {
  if (!process.env[key]) {
    console.error(`Missing required env var: ${key}`);
  }
}

const MODEL_PATH = path.join(__dirname, "templates", "boarding.pass");

async function accessSecret(secretName) {
  const [version] = await secretsClient.accessSecretVersion({
    name: `projects/${process.env.GCP_PROJECT}/secrets/${secretName}/versions/latest`
  });
  return version.payload.data;
}

async function accessSecretString(secretName) {
  const buffer = await accessSecret(secretName);
  return buffer.toString("utf8").trim();
}

function safeValue(value, fallback = "--") {
  const trimmed = String(value || "").trim();
  return trimmed.length ? trimmed : fallback;
}

app.get("/health", (_req, res) => {
  res.status(200).send("ok");
});

app.post("/default-doc", async (req, res) => {
  try {
    const payload = req.body || {};
    const code = String(payload.code || "").trim();
    const doc = String(payload.doc || "").trim().toLowerCase();

    if (!code || !doc) {
      res.status(400).json({ error: "Missing code or doc." });
      return;
    }

    const expectedCode = await accessSecretString(process.env.DEFAULT_DOCS_CODE_SECRET);
    if (code !== expectedCode) {
      res.status(403).json({ error: "Invalid access code." });
      return;
    }

    const bucketName = process.env.DEFAULT_DOCS_BUCKET;
    const objectName =
      doc === "poh"
        ? process.env.DEFAULT_POH_OBJECT || "POH.pdf"
        : doc === "g3000"
          ? process.env.DEFAULT_G3000_OBJECT || "G3000.pdf"
          : null;

    if (!objectName) {
      res.status(400).json({ error: "Unknown document." });
      return;
    }

    const file = storage.bucket(bucketName).file(objectName);
    const [exists] = await file.exists();
    if (!exists) {
      res.status(404).json({ error: "Document not found." });
      return;
    }

    const [signedUrl] = await file.getSignedUrl({
      version: "v4",
      action: "read",
      expires: Date.now() + 15 * 60 * 1000
    });

    res.status(200).json({ url: signedUrl });
  } catch (error) {
    console.error(error?.message || error);
    res.status(500).json({ error: "Failed to fetch document." });
  }
});

app.post("/sign", async (req, res) => {
  try {
    const payload = req.body || {};

    const signerCert = await accessSecret(process.env.SIGNER_CERT_SECRET);
    const signerKey = await accessSecret(process.env.SIGNER_KEY_SECRET);
    const signerKeyPassphrase = (await accessSecret(process.env.SIGNER_KEY_PASSPHRASE_SECRET)).toString("utf8");
    const wwdrCert = await accessSecret(process.env.WWDR_CERT_SECRET);

    const pass = await PKPass.from(
      {
        model: MODEL_PATH,
        certificates: {
          signerCert,
          signerKey,
          signerKeyPassphrase,
          wwdr: wwdrCert
        }
      },
      {
        serialNumber: uuidv4(),
        passTypeIdentifier: process.env.PASS_TYPE_ID,
        teamIdentifier: process.env.TEAM_ID,
        organizationName: process.env.ORG_NAME || "Elite Air",
        description: "Boarding pass",
        logoText: safeValue(payload.flightName, "Elite Air"),
        foregroundColor: "rgb(255,255,255)",
        backgroundColor: "rgb(0,0,0)",
        labelColor: "rgb(200,200,200)"
      }
    );

    const barcodeMessage = [
      payload.flightName,
      payload.flightNumber,
      payload.passengerName,
      payload.departure,
      payload.destination,
      payload.departureTime,
      payload.seat,
      payload.boardingGroup
    ]
      .map((value) => String(value || "").trim())
      .filter(Boolean)
      .join("|");

    pass.setBarcodes({
      message: barcodeMessage || "BOARDING-PASS",
      format: "PKBarcodeFormatQR",
      messageEncoding: "iso-8859-1"
    });

    pass.primaryFields.push(
      { key: "from", label: "From", value: safeValue(payload.departure) },
      { key: "to", label: "To", value: safeValue(payload.destination) }
    );

    pass.secondaryFields.push(
      { key: "flight", label: "Flight", value: safeValue(payload.flightNumber) },
      { key: "date", label: "Date", value: safeValue(payload.travelDate) },
      { key: "boarding", label: "Boarding", value: safeValue(payload.boardingTime) }
    );

    pass.auxiliaryFields.push(
      { key: "depart", label: "Depart", value: safeValue(payload.departureTime) },
      { key: "arrive", label: "Arrive", value: safeValue(payload.arrivalTime) },
      { key: "gate", label: "Gate", value: safeValue(payload.gate) },
      { key: "seat", label: "Seat", value: safeValue(payload.seat) },
      { key: "group", label: "Group", value: safeValue(payload.boardingGroup) },
      { key: "ff", label: "Frequent Flyer", value: safeValue(payload.frequentFlyer) }
    );

    pass.backFields.push(
      { key: "passenger", label: "Passenger", value: safeValue(payload.passengerName) },
      { key: "route", label: "Route", value: `${safeValue(payload.departureCity)} → ${safeValue(payload.destinationCity)}` }
    );

    const buffer = await pass.getAsBuffer();
    res.setHeader("Content-Type", "application/vnd.apple.pkpass");
    res.setHeader("Content-Disposition", "attachment; filename=boarding.pkpass");
    res.status(200).send(buffer);
  } catch (error) {
    console.error(error?.message || error);
    res.status(500).json({ error: "Failed to sign pass" });
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Pass signing service listening on ${port}`);
});
