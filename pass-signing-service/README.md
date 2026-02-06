# Pass Signing Service (Cloud Run)

This service signs Apple Wallet boarding passes and returns a `.pkpass` file.

## What you need
- Google Cloud project with:
  - Cloud Run API enabled
  - Secret Manager API enabled
  - Artifact Registry API enabled
- Secrets created in Secret Manager:
  - `pass_signing_signer_cert` (signer certificate, PEM)
  - `pass_signing_signer_key` (signer private key, PEM)
  - `pass_signing_signer_key_password` (passphrase for the private key)
  - `pass_signing_wwdr_cert` (Apple WWDR certificate, PEM)
- Apple WWDR certificate file placed at:
  - `certs/AppleWWDRCAG4.cer`

You can download the WWDR certificate from Apple (use the current WWDR CA G4).

## Required environment variables (Cloud Run)
- `GCP_PROJECT` (your project ID)
- `PASS_TYPE_ID` (e.g., `pass.paolo.m600checklist.new.boarding`)
- `TEAM_ID` (your Apple Team ID)
- `ORG_NAME` (organization name shown on the pass)
- `SIGNER_CERT_SECRET` (set to `pass_signing_signer_cert`)
- `SIGNER_KEY_SECRET` (set to `pass_signing_signer_key`)
- `SIGNER_KEY_PASSPHRASE_SECRET` (set to `pass_signing_signer_key_password`)
- `WWDR_CERT_SECRET` (set to `pass_signing_wwdr_cert`)

## Local test (optional)
```bash
npm install
export GCP_PROJECT=your-project-id
export PASS_TYPE_ID=pass.paolo.m600checklist.new.boarding
export TEAM_ID=YOUR_TEAM_ID
export ORG_NAME="Elite Air"
export SIGNER_CERT_SECRET=pass_signing_signer_cert
export SIGNER_KEY_SECRET=pass_signing_signer_key
export SIGNER_KEY_PASSPHRASE_SECRET=pass_signing_signer_key_password
export WWDR_CERT_SECRET=pass_signing_wwdr_cert
node index.js
```

## Cloud Run deployment (gcloud)
```bash
gcloud config set project YOUR_PROJECT_ID

gcloud run deploy pass-signing-service \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated \
  --set-env-vars GCP_PROJECT=YOUR_PROJECT_ID,PASS_TYPE_ID=pass.paolo.m600checklist.new.boarding,TEAM_ID=YOUR_TEAM_ID,ORG_NAME="Elite Air",SIGNER_CERT_SECRET=pass_signing_signer_cert,SIGNER_KEY_SECRET=pass_signing_signer_key,SIGNER_KEY_PASSPHRASE_SECRET=pass_signing_signer_key_password,WWDR_CERT_SECRET=pass_signing_wwdr_cert
```

## Request example
POST `/sign` with JSON:
```json
{
  "flightName": "Boarding Pass",
  "flightNumber": "TCEZP 001",
  "passengerName": "Jane Doe",
  "departure": "LFPT",
  "departureCity": "Paris",
  "destination": "LBTA",
  "destinationCity": "Istanbul",
  "travelDate": "Feb 15 2026",
  "boardingTime": "09:00",
  "departureTime": "09:30",
  "arrivalTime": "13:00",
  "gate": "Pontoise FBO",
  "seat": "A2",
  "boardingGroup": "Global Services",
  "frequentFlyer": "EZ01"
}
```
