#!/usr/bin/env python3
import json
import base64
import logging
import os
from flask import Flask, request, jsonify

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

app = Flask(__name__)

def admission_response(uid, allowed=True, patch=None, message=None):
    resp = {
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": {
            "uid": uid,
            "allowed": allowed,
        },
    }
    if patch is not None:
        patch_b64 = base64.b64encode(json.dumps(patch).encode()).decode()
        resp["response"]["patchType"] = "JSONPatch"
        resp["response"]["patch"] = patch_b64
    if message:
        resp["response"]["status"] = {"message": message}
    return resp

@app.route('/mutate', methods=['POST'])
def mutate():
    review = request.get_json()
    uid = review.get("request", {}).get("uid", "")
    obj = review.get("request", {}).get("object", {})

    logging.info("Mutate request received: uid=%s", uid)

    patches = []
    spec = obj.get("spec", {})

    # Add securityContext if missing
    if "securityContext" not in spec:
        patches.append({
            "op": "add",
            "path": "/spec/securityContext",
            "value": {"runAsNonRoot": True, "runAsUser": 1234}
        })
        logging.info("Adding securityContext patch")

    if patches:
        logging.info("Returning %d patch(es)", len(patches))
        return jsonify(admission_response(uid, allowed=True, patch=patches))

    logging.info("No patch needed")
    return jsonify(admission_response(uid, allowed=True))

@app.route('/validate', methods=['POST'])
def validate():
    review = request.get_json()
    uid = review.get("request", {}).get("uid", "")
    obj = review.get("request", {}).get("object", {})

    logging.info("Validate request received: uid=%s", uid)

    sc = obj.get("spec", {}).get("securityContext", {})
    run_as_non_root = sc.get("runAsNonRoot", False)
    run_as_user = sc.get("runAsUser", None)

    if run_as_non_root and run_as_user == 0:
        msg = "Invalid: runAsNonRoot=true but runAsUser=0"
        logging.info("Denying pod: %s", msg)
        return jsonify(admission_response(uid, allowed=False, message=msg))

    logging.info("Pod allowed")
    return jsonify(admission_response(uid, allowed=True))

@app.route('/healthz', methods=['GET'])
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    cert_file = "/run/secrets/tls/tls.crt"
    key_file = "/run/secrets/tls/tls.key"
    port = int(os.environ.get('PORT', '8443'))

    use_tls = os.environ.get('USE_TLS', 'true').lower() == 'true'

    if use_tls:
        if not os.path.exists(cert_file) or not os.path.exists(key_file):
            logging.error("Certificate files not found")
            exit(1)

        logging.info("Starting HTTPS webhook server on 0.0.0.0:%d", port)
        logging.info("Using cert=%s key=%s", cert_file, key_file)

        # Flask with SSL
        app.run(
            host='0.0.0.0',
            port=port,
            ssl_context=(cert_file, key_file),
            debug=False
        )
    else:
        logging.info("Starting HTTP webhook server on 0.0.0.0:%d", port)
        app.run(host='0.0.0.0', port=port, debug=False)