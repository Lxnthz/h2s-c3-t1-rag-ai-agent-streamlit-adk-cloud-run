set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "[ERROR] Missing arguments!"
    echo "Usage: source ./setup.sh <gcp-project-id> <gcp-location>"
    echo "e.g: source ./setup.sh <project-id> <region>"
fi

PROJECT_ID="$1"
REGION="$2"

echo "[INFO] Listing active authenticated accounts..."
gcloud auth list

echo "[INFO] Setting active project to "$PROJECT_ID"..."
gcloud config set project "$PROJECT_ID"

echo "[INFO] Verifying active project configuration..."
CURR_PROJECT=$(gcloud config get-value project)
echo "[INFO] Active project is set to: $CURR_PROJECT"

if [ "$CURR_PROJECT" = "$PROJECT_ID" ]; then
    echo "[INFO] Active project verified successfully!"
else
    echo "[ERROR] Active project verification failed. "
fi

echo "[INFO] Enabling required services (run, aiplatform, cloudbuild)..."
gcloud services enable \
  run.googleapis.com \
  aiplatform.googleapis.com \
  cloudbuild.googleapis.com

echo "[INFO] Setting default compute region to '$REGION'..."
gcloud config set compute/region "$REGION"

export PROJECT_ID="$CURR_PROJECT"
export REGION="$REGION"

echo "[SUCCESS] GCP project and region are set up!"
echo "PROJECT_ID: $PROJECT_ID"
echo "REGION: $REGION"

echo "[INFO] Validating menu.json file..."
cat src/menu.json | python3 -m json.tool > /dev/null && echo "[SUCCESS] Valid JSON!"

echo "[INFO] Installing Python dependencies..."
pip3 install -r src/requirements.txt


# Deploy agent to cloud run
echo "[INFO] Starting Service Account creation..."
gcloud iam service-accounts create barista-agent-sa \
  --description="Service account for Coffee Barista SDK agent on Cloud Run" \
  --display-name="Barista Agent Service Account"

echo "[INFO] Granting Gemini Enterprise Agent Platform user role (roles/aiplatform.user) to the newly created Service Account"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:barista-agent-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

echo "[INFO] Starting the deployment process..."
gcloud run deploy coffee-barista \
  --source ./src \
  --region "$REGION" \
  --allow-unauthenticated \
  --labels app=streamlit-adk-rag \
  --command "/cnb/lifecycle/launcher" \
  --args "sh,-c,python3 -m streamlit run app.py --server.port=\$PORT --server.address=0.0.0.0 --server.enableCORS=false --server.enableXsrfProtection=false" \
  --service-account "barista-agent-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --set-env-vars GOOGLE_GENAI_USE_ENTERPRISE=TRUE,GOOGLE_CLOUD_PROJECT=$PROJECT_ID,GOOGLE_CLOUD_LOCATION=global