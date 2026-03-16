from diagrams import Diagram, Cluster, Edge
from diagrams.gcp.compute import Run
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.gcp.security import Iam
from diagrams.gcp.network import LoadBalancing
from diagrams.onprem.client import User

with Diagram(
    "GCP Infrastructure",
    filename="docs/gcp-infrastructure",
    outformat="png",
    show=False,
    direction="TB",
):
    developer = User("Developer")
    client = User("Client")

    with Cluster("GCP Project"):
        with Cluster("Artifact Registry"):
            repo = ContainerRegistry("Docker Repository")

        with Cluster("API Gateway"):
            gateway = LoadBalancing("API Gateway\n(public)")
            api_key = Iam("API Key\nx-api-key header")

        with Cluster("Cloud Run (private)"):
            service = Run("Cloud Run Service\n1 vCPU · 512 MiB · scale 0–10")

        app_sa = Iam("App\nService Account")
        gw_sa = Iam("Gateway\nService Account")

        repo >> Edge(label="pulls image") >> service
        app_sa >> Edge(label="identity") >> service
        api_key >> Edge(label="enforced on\n/random-int\n/random-name-string") >> gateway
        gw_sa >> Edge(label="roles/run.invoker") >> service

    developer >> Edge(label="docker push") >> repo
    client >> Edge(label="HTTPS") >> gateway
    gateway >> Edge(label="proxies to") >> service
