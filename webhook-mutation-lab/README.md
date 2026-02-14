# LAB webhook validation

1- Create namespace webhook-demo where we will deploy webhook components
2 - Create a TLS secret named webhook-server-tls in the webhook-demo namespace.

    This secret will be used by the admission webhook server for secure communication over HTTPS.

    We have to  created below cert and key for webhook server which should be used to create secret.

    Certificate : /root/keys/webhook-server-tls.crt

    Key : /root/keys/webhook-server-tls.key

```bash
    k -n webhook-demo create secret tls webhook-server-tl --cert=/root/keys/webhook-server-tls.crt --key=/root/keys/webhook-server-tls.key
```
3 - Create the webhook deployment that will run the admission webhook server.

    We have already provided the deployment manifest at:

```bash
    kubectl apply -f webhook-deployment.yml
    kubectl apply -f webhook-service.yml
```
4 - Create the MutatingWebhookConfiguration that will register the webhook with the Kubernetes API server.

    We have already provided the ValidatingWebhookConfiguration manifest at:

```bash
    kubectl apply -f webhook-configuration.yml
```
4 - In the previous steps, you have set up and deployed a demo webhook with the following behaviors:

    Denies all requests for pods to run as root in a container if no securityContext is provided.
    Defaults: If runAsNonRoot is not set, the webhook automatically adds runAsNonRoot: true and sets the user ID to 1234.
    Explicit root access: The webhook allows containers to run as root only if you explicitly set runAsNonRoot: false in the pod's securityContext.

In the next steps, you will find pod definition files for each scenario. Please deploy these pods using the provided definition files and validate the behavior of our webhook.

5 - Deploy the pod definition file that does not specify any securityContext. This will test the default behavior of the webhook.

```bash
    kubectl apply -f pod-with-defaults.yaml

    kubectl exec pod-with-defaults -- id

    kubectl edit pod pod-with-defaults
```

6 - Deploy pod with a securityContext explicitly allowing it to run as root
We have added pod definition file under

```bash
    kubectl apply -f pod-with-override.yaml

    kubectl exec pod-with-override -- id

    kubectl edit pod pod-with-override
```
Validate securityContext after you deploy this pod

6 -Deploy a pod that specifies a conflicting securityContext.

    The pod requests to run with runAsUser: 0 (root).
    But it does not explicitly set runAsNonRoot: false.




```bash
    kubectl apply -f pod-with-conflict.yaml

```
According to our webhook rules, this request should be denied.