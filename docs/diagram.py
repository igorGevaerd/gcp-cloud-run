from diagrams import Diagram, Cluster, Edge
from diagrams.gcp.compute import Run
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.gcp.security import Iam
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
        with Cluster("Artifact Registry API\nArtifact Registry"):
            repo = ContainerRegistry("Docker Repository")

        sa = Iam("Service Account")
        iam = Iam("IAM\nallUsers · roles/run.invoker")

        with Cluster("Cloud Run API\nCloud Run"):
            service = Run("Cloud Run Service\n1 vCPU · 512 MiB · scale 0–10")

        repo >> Edge(label="pulls image") >> service
        sa >> Edge(label="identity") >> service
        iam >> service

    developer >> Edge(label="docker push") >> repo
    client >> Edge(label="HTTPS") >> service
